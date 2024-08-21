const std = @import("std");

const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;
const Ray = @import("Ray.zig");
const Interval = @import("Interval.zig");

const colour = @import("colour.zig");
const material = @import("material.zig");

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    mat: *material.Material,
    t: f32,
    front_face: bool,

    pub fn set_face_normal(self: *HitRecord, r: Ray, outward_normal: Vec3) void {
        self.front_face = Vec3.dot(r.direction, outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.neg();
    }
};

pub const Hittable = struct {
    hitFn: *const fn (self: *Hittable, r: Ray, ray_t: Interval, rec: *HitRecord) bool,
    deinitFn: *const fn (self: *Hittable, allocator: std.mem.Allocator) void,

    pub fn hit(self: *Hittable, r: Ray, ray_t: Interval, rec: *HitRecord) bool {
        return self.hitFn(self, r, ray_t, rec);
    }

    pub fn deinit(self: *Hittable, allocator: std.mem.Allocator) void {
        self.deinitFn(self, allocator);
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(*Hittable),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) HittableList {
        return .{
            .objects = std.ArrayList(*Hittable).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HittableList) void {
        for (self.objects.items) |object| {
            object.deinit(self.allocator);
        }

        self.objects.deinit();
    }

    pub fn add(self: *HittableList, object: *Hittable) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: *HittableList, r: Ray, ray_t: Interval, rec: *HitRecord) bool {
        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            if (object.hit(r, Interval.init(ray_t.min, closest_so_far), &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f32,
    hittable: Hittable,
    material: *material.Material,

    pub fn init(allocator: std.mem.Allocator, center: Point3, radius: f32, mat: *material.Material) !*Sphere {
        const self = try allocator.create(@This());
        self.* = .{
            .center = center,
            .radius = if (radius > 0) radius else 0,
            .hittable = .{
                .hitFn = hit,
                .deinitFn = deinit,
            },
            .material = mat,
        };

        return self;
    }

    pub fn deinit(hittable: *Hittable, allocator: std.mem.Allocator) void {
        const self: *Sphere = @fieldParentPtr("hittable", hittable);
        self.material.deinit(allocator);
        allocator.destroy(self);
    }

    pub fn hit(hittable: *Hittable, r: Ray, ray_t: Interval, rec: *HitRecord) bool {
        const self: *Sphere = @fieldParentPtr("hittable", hittable);

        const oc = Vec3.sub(self.center, r.origin);
        const a = r.direction.length_squared();
        const h = Vec3.dot(r.direction, oc);
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
        const outward_normal = Vec3.scale(Vec3.sub(rec.p, self.center), 1 / self.radius);
        rec.set_face_normal(r, outward_normal);
        rec.mat = self.material;

        return true;
    }
};
