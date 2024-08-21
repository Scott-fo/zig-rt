const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;
const Ray = @import("Ray.zig");
const colour = @import("colour.zig");
const hittable = @import("hittable.zig");
const utils = @import("utils.zig");

const ResultsContext = struct {
    results: *std.ArrayList([]u8),
    mutex: std.Thread.Mutex,
    progress: std.atomic.Value(usize),
    total_lines: usize,
};

const Camera = @This();

image_width: usize,
aspect_ratio: f32,
samples_per_pixel: usize,
max_depth: usize,
vfov: f32,
look_from: Point3,
look_at: Point3,
vup: Vec3,
defocus_angle: f32,
focus_dist: f32,

image_height: usize,
pixel_samples_scale: f32,
pixel00_loc: Point3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,

defocus_disk_u: Vec3,
defocus_disk_v: Vec3,

pub fn init() Camera {
    const image_width: usize = 1200;
    const aspect_ratio: f32 = 16.0 / 9.0;
    const samples_per_pixel: usize = 500;
    const max_depth: usize = 50;
    const vfov: f32 = 20;
    const look_from: Point3 = Point3.init(13, 2, 3);
    const look_at: Point3 = Point3.init(0, 0, 0);
    const vup: Vec3 = Vec3.init(0, 1, 0);

    const defocus_angle = 0.6;
    const focus_dist = 10.0;

    const image_height_float: f32 = @as(f32, @floatFromInt(image_width)) / aspect_ratio;
    var image_height: usize = @intFromFloat(image_height_float);
    image_height = if (image_height > 1) image_height else 1;

    const theta = utils.degrees_to_radians(vfov);
    const h = @tan(theta / 2);

    const viewport_height: f32 = 2.0 * h * focus_dist;
    const viewport_width: f32 = viewport_height * (@as(f32, @floatFromInt(image_width)) / image_height_float);

    const w = Vec3.sub(look_from, look_at).unit_vector();
    const u = Vec3.cross(vup, w).unit_vector();
    const v = Vec3.cross(w, u);

    const viewport_u = Vec3.scale(u, viewport_width);
    const viewport_v = Vec3.scale(v.neg(), viewport_height);

    const pixel_delta_u = Vec3.scale(viewport_u, 1 / @as(f32, @floatFromInt(image_width)));
    const pixel_delta_v = Vec3.scale(viewport_v, 1 / image_height_float);

    var viewport_upper_left = Vec3.sub(look_from, Vec3.scale(w, focus_dist));
    viewport_upper_left = Vec3.sub(viewport_upper_left, Vec3.scale(viewport_u, 0.5));
    viewport_upper_left = Vec3.sub(viewport_upper_left, Vec3.scale(viewport_v, 0.5));

    const pixel00_loc = Vec3.add(viewport_upper_left, Vec3.scale(Vec3.add(pixel_delta_u, pixel_delta_v), 0.5));
    const pixel_samples_scale = 1.0 / @as(f32, @floatFromInt(samples_per_pixel));

    const defocus_radius = focus_dist * @tan(utils.degrees_to_radians(defocus_angle / 2.0));
    const defocus_disk_u = Vec3.scale(u, defocus_radius);
    const defocus_disk_v = Vec3.scale(v, defocus_radius);

    return .{
        .image_width = image_width,
        .aspect_ratio = aspect_ratio,
        .samples_per_pixel = samples_per_pixel,
        .max_depth = max_depth,
        .vfov = vfov,
        .look_from = look_from,
        .look_at = look_at,
        .vup = vup,
        .image_height = image_height,
        .pixel_samples_scale = pixel_samples_scale,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .defocus_angle = defocus_angle,
        .focus_dist = focus_dist,
        .defocus_disk_u = defocus_disk_u,
        .defocus_disk_v = defocus_disk_v,
    };
}

pub fn render(self: *Camera, allocator: std.mem.Allocator, writer: anytype, world: *hittable.HittableList) !void {
    const num_threads = try std.Thread.getCpuCount();
    const chunk_size: usize = self.image_height / num_threads;

    var results = try std.ArrayList([]u8).initCapacity(allocator, self.image_height);
    defer {
        for (results.items) |item| {
            allocator.free(item);
        }

        results.deinit();
    }

    for (0..self.image_height) |_| {
        const empty = try allocator.alloc(u8, 0);
        try results.append(empty);
    }

    var threads = try std.ArrayList(std.Thread).initCapacity(allocator, num_threads);
    defer threads.deinit();

    var results_context = ResultsContext{
        .results = &results,
        .mutex = .{},
        .progress = std.atomic.Value(usize).init(0),
        .total_lines = self.image_height,
    };

    const progress_thread = try std.Thread.spawn(.{}, report_progress, .{&results_context});

    for (0..num_threads) |t| {
        const start = t * chunk_size;
        const end = if (t == num_threads - 1) self.image_height else (t + 1) * chunk_size;

        const thread = try std.Thread.spawn(.{}, render_chunk, .{
            self,
            allocator,
            start,
            end,
            world,
            &results_context,
        });

        try threads.append(thread);
    }

    for (threads.items) |thread| {
        thread.join();
    }

    _ = results_context.progress.fetchAdd(1, .release);
    progress_thread.join();

    try writer.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });
    for (results.items) |line| {
        try writer.writeAll(line);
    }
}

fn render_chunk(
    self: *Camera,
    allocator: std.mem.Allocator,
    start: usize,
    end: usize,
    world: *hittable.HittableList,
    results_context: *ResultsContext,
) !void {
    for (start..end) |j| {
        var line_result = std.ArrayList(u8).init(allocator);
        defer line_result.deinit();

        for (0..self.image_width) |i| {
            var pixel_colour = colour.Colour.default();
            for (0..self.samples_per_pixel) |_| {
                const r = self.get_ray(@floatFromInt(i), @floatFromInt(j));
                pixel_colour = Vec3.add(pixel_colour, r.colour(self.max_depth, world));
            }

            try colour.write_colour(line_result.writer(), Vec3.scale(pixel_colour, self.pixel_samples_scale));
        }

        results_context.mutex.lock();
        defer results_context.mutex.unlock();

        results_context.results.items[j] = try line_result.toOwnedSlice();
        _ = results_context.progress.fetchAdd(1, .release);
    }
}

fn report_progress(results_context: *ResultsContext) void {
    const total_lines = results_context.total_lines;
    while (true) {
        const current_progress = results_context.progress.load(.acquire);
        if (current_progress > total_lines) break;

        const percentage = @as(f32, @floatFromInt(current_progress)) / @as(f32, @floatFromInt(total_lines)) * 100.0;
        std.debug.print("\rProgress: {d:.2}% ({d}/{d} lines)", .{ percentage, current_progress, total_lines });
        std.time.sleep(1 * std.time.ns_per_s);
    }

    std.debug.print("\rRendering completed.            \n", .{});
}

fn get_ray(self: Camera, i: f32, j: f32) Ray {
    const offset = sample_square();
    const pixel_sample = Vec3.add(self.pixel00_loc, Vec3.add(Vec3.scale(self.pixel_delta_u, i + offset.x), Vec3.scale(self.pixel_delta_v, j + offset.y)));
    const ray_origin = if (self.defocus_angle <= 0) self.look_from else defocus_disk_sample(self);
    const ray_direction = Vec3.sub(pixel_sample, ray_origin);

    return Ray.init(ray_origin, ray_direction);
}

fn sample_square() Vec3 {
    return Vec3.init(utils.random_float() - 0.5, utils.random_float() - 0.5, 0);
}

fn defocus_disk_sample(self: Camera) Point3 {
    const p = Vec3.random_in_unit_disk();
    return Vec3.add(self.look_from, Vec3.add(Vec3.scale(self.defocus_disk_u, p.x), Vec3.scale(self.defocus_disk_v, p.y)));
}
