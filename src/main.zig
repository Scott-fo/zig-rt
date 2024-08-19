const std = @import("std");
const vec3 = @import("lib/vec3.zig");
const colour = @import("lib/colour.zig");
const ray = @import("lib/ray.zig");
const hittable = @import("lib/hittable.zig");

test {
    _ = @import("lib/vec3.zig");
    _ = @import("lib/colour.zig");
    _ = @import("lib/ray.zig");
}

pub fn main() !void {
    const file = try std.fs.cwd().createFile(
        "image.ppm",
        .{ .read = true, .truncate = true },
    );
    defer file.close();

    var buffered_writer = std.io.bufferedWriter(file.writer());
    const writer = buffered_writer.writer();

    const image_width = 400;
    const aspect_ratio: f32 = 16.0 / 9.0;

    const image_height_float: f32 = image_width / aspect_ratio;
    var image_height: usize = @intFromFloat(image_height_float);
    image_height = if (image_height > 1) image_height else 1;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var world = hittable.HittableList.init(allocator);
    defer world.deinit();

    const sphere1 = try allocator.create(hittable.Sphere);
    defer allocator.destroy(sphere1);
    sphere1.* = hittable.Sphere.init(vec3.Point3.init(0, 0, -1), 0.5);

    const sphere2 = try allocator.create(hittable.Sphere);
    defer allocator.destroy(sphere2);
    sphere2.* = hittable.Sphere.init(vec3.Point3.init(0, -100.5, -1), 100);

    try world.add(&sphere1.hittable);
    try world.add(&sphere2.hittable);

    const focal_length: f32 = 1.0;
    const viewport_height: f32 = 2.0;
    const viewport_width: f32 = viewport_height * (image_width / image_height_float);
    const camera_center = vec3.Point3.default();

    const viewport_u = vec3.Vec3.init(viewport_width, 0, 0);
    const viewport_v = vec3.Vec3.init(0, -viewport_height, 0);

    const pixel_delta_u = vec3.scale(viewport_u, 1 / @as(f32, @floatFromInt(image_width)));
    const pixel_delta_v = vec3.scale(viewport_v, 1 / image_height_float);

    var viewport_upper_left = vec3.sub(camera_center, vec3.Vec3.init(0, 0, focal_length));
    viewport_upper_left = vec3.sub(viewport_upper_left, vec3.scale(viewport_u, 0.5));
    viewport_upper_left = vec3.sub(viewport_upper_left, vec3.scale(viewport_v, 0.5));

    const pixel00_loc = vec3.add(viewport_upper_left, vec3.scale(vec3.add(pixel_delta_u, pixel_delta_v), 0.5));

    try writer.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        std.debug.print("\rScanline remaining: {d} ", .{image_height - j});
        for (0..image_width) |i| {
            const pixel_delta_u_scaled = vec3.scale(pixel_delta_u, @floatFromInt(i));
            const pixel_delta_v_scaled = vec3.scale(pixel_delta_v, @floatFromInt(j));
            const pixel_center = vec3.add(pixel00_loc, vec3.add(pixel_delta_u_scaled, pixel_delta_v_scaled));

            const ray_direction = vec3.sub(pixel_center, camera_center);
            const r = ray.Ray.init(camera_center, ray_direction);

            const pixel_colour = r.colour(&world);
            try colour.write_colour(&writer, pixel_colour);
        }
    }

    try buffered_writer.flush();
    std.debug.print("\rDone.                   \n", .{});
}
