const vec3 = @import("vec3.zig");
const ray = @import("ray.zig");
const Colour = @import("colour.zig").Colour;
const hittable = @import("hittable.zig");
const interval = @import("interval.zig");
const std = @import("std");

pub const Ray = struct {
    origin: vec3.Point3,
    direction: vec3.Vec3,

    pub fn init(origin: vec3.Point3, direction: vec3.Vec3) Ray {
        return Ray{
            .origin = origin,
            .direction = direction,
        };
    }

    pub fn colour(self: Ray, depth: usize, world: *hittable.HittableList) Colour {
        if (depth <= 0) {
            return Colour.default();
        }

        var rec: hittable.HitRecord = undefined;

        if (world.hit(self, interval.Interval.init(0.001, std.math.inf(f32)), &rec)) {
            var scattered: ray.Ray = undefined;
            var attenuation: Colour = undefined;

            if (rec.mat.scatter(self, rec, &attenuation, &scattered)) {
                return vec3.mult(attenuation, scattered.colour(depth - 1, world));
            }

            return Colour.default();
        }

        const unit_direction = self.direction.unit_vector();
        const a: f32 = 0.5 * (unit_direction.y + 1.0);

        return vec3.add(vec3.scale(Colour.init(1, 1, 1), 1.0 - a), vec3.scale(Colour.init(0.5, 0.7, 1.0), a));
    }

    fn hit_sphere(self: Ray, center: vec3.Point3, radius: f32) f32 {
        const oc = vec3.sub(center, self.origin);
        const a = self.direction.length_squared();
        const h = vec3.dot(self.direction, oc);
        const c = oc.length_squared() - radius * radius;
        const discriminant = h * h - a * c;

        if (discriminant < 0) {
            return -1.0;
        } else {
            return (h - @sqrt(discriminant)) / a;
        }
    }

    pub inline fn at(self: Ray, t: f32) vec3.Point3 {
        return vec3.add(self.origin, vec3.scale(self.direction, t));
    }
};
