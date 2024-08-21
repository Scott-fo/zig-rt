const std = @import("std");

const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;
const Colour = @import("colour.zig").Colour;
const Interval = @import("Interval.zig");

const hittable = @import("hittable.zig");

const Ray = @This();

origin: Point3,
direction: Vec3,

pub fn init(origin: Point3, direction: Vec3) Ray {
    return .{
        .origin = origin,
        .direction = direction,
    };
}

pub fn colour(self: Ray, depth: usize, world: *hittable.HittableList) Colour {
    if (depth <= 0) {
        return Colour.default();
    }

    var rec: hittable.HitRecord = undefined;

    if (world.hit(self, Interval.init(0.001, std.math.inf(f32)), &rec)) {
        var scattered: Ray = undefined;
        var attenuation: Colour = undefined;

        if (rec.mat.scatter(self, rec, &attenuation, &scattered)) {
            return Vec3.mult(attenuation, scattered.colour(depth - 1, world));
        }

        return Colour.default();
    }

    const unit_direction = self.direction.unit_vector();
    const a: f32 = 0.5 * (unit_direction.y + 1.0);

    return Vec3.add(Vec3.scale(Colour.init(1, 1, 1), 1.0 - a), Vec3.scale(Colour.init(0.5, 0.7, 1.0), a));
}

fn hit_sphere(self: Ray, center: Vec3.Point3, radius: f32) f32 {
    const oc = Vec3.sub(center, self.origin);
    const a = self.direction.length_squared();
    const h = Vec3.dot(self.direction, oc);
    const c = oc.length_squared() - radius * radius;
    const discriminant = h * h - a * c;

    if (discriminant < 0) {
        return -1.0;
    } else {
        return (h - @sqrt(discriminant)) / a;
    }
}

pub inline fn at(self: Ray, t: f32) Point3 {
    return Vec3.add(self.origin, Vec3.scale(self.direction, t));
}
