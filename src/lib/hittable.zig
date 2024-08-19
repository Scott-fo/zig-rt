const std = @import("std");
const vec3 = @import("vec3.zig");
const colour = @import("colour.zig");
const ray = @import("ray.zig");
const interval = @import("interval.zig");

pub const HitRecord = struct {
    p: vec3.Point3,
    normal: vec3.Vec3,
    t: f32,
    front_face: bool,

    pub fn set_face_normal(self: *HitRecord, r: ray.Ray, outward_normal: vec3.Vec3) void {
        self.front_face = vec3.dot(r.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.neg();
    }
};

pub const Hittable = struct {
    hitFn: *const fn (self: *Hittable, r: ray.Ray, ray_t: interval.Interval, rec: *HitRecord) bool,

    pub fn hit(self: *Hittable, r: ray.Ray, ray_t: interval.Interval, rec: *HitRecord) bool {
        return self.hitFn(self, r, ray_t, rec);
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(*Hittable),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HittableList {
        return HittableList{
            .objects = std.ArrayList(*Hittable).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HittableList) void {
        self.objects.deinit();
    }

    pub fn clear(self: *HittableList) void {
        self.objects.clearRetainingCapacity();
    }

    pub fn add(self: *HittableList, object: *Hittable) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: *HittableList, r: ray.Ray, ray_t: interval.Interval, rec: *HitRecord) bool {
        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(r, interval.Interval.init(ray_t.min, closest_so_far), &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};

pub const Sphere = struct {
    center: vec3.Point3,
    radius: f32,
    hittable: Hittable,

    pub fn init(center: vec3.Point3, radius: f32) Sphere {
        const r = if (radius > 0) radius else 0;
        return Sphere{
            .center = center,
            .radius = r,
            .hittable = .{ .hitFn = hit },
        };
    }

    pub fn hit(hittable: *Hittable, r: ray.Ray, ray_t: interval.Interval, rec: *HitRecord) bool {
        const self: *Sphere = @fieldParentPtr("hittable", hittable);

        const oc = vec3.sub(self.center, r.origin);
        const a = r.direction.length_squared();
        const h = vec3.dot(r.direction, oc);
        const c = oc.length_squared() - (self.radius * self.radius);

        const discriminant = h * h - a * c;

        if (discriminant < 0) {
            return false;
        }

        const sqrtd: f32 = @sqrt(discriminant);

        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root)) {
                return false;
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        const outward_normal = vec3.scale(vec3.sub(rec.p, self.center), 1 / self.radius);
        rec.set_face_normal(r, outward_normal);

        return true;
    }
};
