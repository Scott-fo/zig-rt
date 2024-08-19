const std = @import("std");
const vec3 = @import("vec3.zig");
const colour = @import("colour.zig");
const ray = @import("ray.zig");
const hittable = @import("hittable.zig");

pub const Camera = struct {
    aspect_ratio: f32,
    image_width: usize,
    image_height: usize,
    center: vec3.Point3,
    pixel00_loc: vec3.Point3,
    pixel_delta_u: vec3.Vec3,
    pixel_delta_v: vec3.Vec3,

    pub fn init() Camera {
        const image_width = 400;
        const aspect_ratio: f32 = 16.0 / 9.0;
        const center = vec3.Point3.default();

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
        };
    }

    pub fn render(self: Camera, writer: anytype, world: *hittable.HittableList) !void {
        try writer.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            std.debug.print("\rScanline remaining: {d} ", .{self.image_height - j});
            for (0..self.image_width) |i| {
                const pixel_delta_u_scaled = vec3.scale(self.pixel_delta_u, @floatFromInt(i));
                const pixel_delta_v_scaled = vec3.scale(self.pixel_delta_v, @floatFromInt(j));
                const pixel_center = vec3.add(self.pixel00_loc, vec3.add(pixel_delta_u_scaled, pixel_delta_v_scaled));

                const ray_direction = vec3.sub(pixel_center, self.center);
                const r = ray.Ray.init(self.center, ray_direction);

                const pixel_colour = r.colour(world);
                try colour.write_colour(&writer, pixel_colour);
            }
        }

        std.debug.print("\rDone.                   \n", .{});
    }
};
