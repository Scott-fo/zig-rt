const std = @import("std");
const vec3 = @import("vec3.zig");
const colour = @import("colour.zig");
const ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const utils = @import("utils.zig");

pub const Camera = struct {
    aspect_ratio: f32,
    image_width: usize,
    image_height: usize,
    center: vec3.Point3,
    pixel00_loc: vec3.Point3,
    pixel_delta_u: vec3.Vec3,
    pixel_delta_v: vec3.Vec3,
    samples_per_pixel: usize,
    pixel_samples_scale: f32,
    max_depth: usize,

    pub fn init() Camera {
        const image_width = 400;
        const aspect_ratio: f32 = 16.0 / 9.0;
        const samples_per_pixel = 100;
        const pixel_samples_scale = 1.0 / @as(f32, @floatFromInt(samples_per_pixel));
        const center = vec3.Point3.default();
        const max_depth = 10;

        const image_height_float: f32 = image_width / aspect_ratio;
        var image_height: usize = @intFromFloat(image_height_float);
        image_height = if (image_height > 1) image_height else 1;

        const focal_length: f32 = 1.0;
        const viewport_height: f32 = 2.0;
        const viewport_width: f32 = viewport_height * (image_width / image_height_float);
        const viewport_u = vec3.Vec3.init(viewport_width, 0, 0);
        const viewport_v = vec3.Vec3.init(0, -viewport_height, 0);

        const pixel_delta_u = vec3.scale(viewport_u, 1 / @as(f32, @floatFromInt(image_width)));
        const pixel_delta_v = vec3.scale(viewport_v, 1 / image_height_float);

        var viewport_upper_left = vec3.sub(center, vec3.Vec3.init(0, 0, focal_length));
        viewport_upper_left = vec3.sub(viewport_upper_left, vec3.scale(viewport_u, 0.5));
        viewport_upper_left = vec3.sub(viewport_upper_left, vec3.scale(viewport_v, 0.5));

        const pixel00_loc = vec3.add(viewport_upper_left, vec3.scale(vec3.add(pixel_delta_u, pixel_delta_v), 0.5));

        return Camera{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .center = center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .samples_per_pixel = samples_per_pixel,
            .pixel_samples_scale = pixel_samples_scale,
            .max_depth = max_depth,
        };
    }

    pub fn render(self: Camera, writer: anytype, world: *hittable.HittableList) !void {
        try writer.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            std.debug.print("\rScanline remaining: {d} ", .{self.image_height - j});
            for (0..self.image_width) |i| {
                var pixel_colour = colour.Colour.default();
                for (0..self.samples_per_pixel) |_| {
                    const r = self.get_ray(@floatFromInt(i), @floatFromInt(j));
                    pixel_colour = vec3.add(pixel_colour, r.colour(self.max_depth, world));
                }

                try colour.write_colour(&writer, vec3.scale(pixel_colour, self.pixel_samples_scale));
            }
        }

        std.debug.print("\rDone.                   \n", .{});
    }

    fn get_ray(self: Camera, i: f32, j: f32) ray.Ray {
        const offset = sample_square();
        const pixel_sample = vec3.add(self.pixel00_loc, vec3.add(vec3.scale(self.pixel_delta_u, i + offset.x), vec3.scale(self.pixel_delta_v, j + offset.y)));
        const ray_origin = self.center;
        const ray_direction = vec3.sub(pixel_sample, ray_origin);

        return ray.Ray.init(ray_origin, ray_direction);
    }

    fn sample_square() vec3.Vec3 {
        return vec3.Vec3.init(utils.random_float() - 0.5, utils.random_float() - 0.5, 0);
    }
};
