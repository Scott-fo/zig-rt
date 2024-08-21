const std = @import("std");

const Vec3 = @import("Vec3.zig");
const Point3 = Vec3.Point3;
const Colour = @import("colour.zig").Colour;

const hittable = @import("hittable.zig");
const material = @import("material.zig");
const utils = @import("utils.zig");

const World = @This();

list: *hittable.HittableList,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !World {
    const list = try allocator.create(hittable.HittableList);
    list.* = hittable.HittableList.init(allocator);

    var self = World{
        .list = list,
        .allocator = allocator,
    };

    try self.build_world();
    return self;
}

pub fn deinit(self: World) void {
    self.list.deinit();
    self.allocator.destroy(self.list);
}

fn build_world(self: World) !void {
    const material_ground = try material.Lambertian.init(self.allocator, Colour.init(0.5, 0.5, 0.5));
    const sphere1 = try hittable.Sphere.init(self.allocator, Point3.init(0, -1000, -1), 1000, &material_ground.material);
    try self.list.add(&sphere1.hittable);

    for (0..22) |a| {
        for (0..22) |b| {
            const a_scaled: f32 = @as(f32, @floatFromInt(a)) - 11;
            const b_scaled: f32 = @as(f32, @floatFromInt(b)) - 11;

            const choose_mat = utils.random_float();
            const center: Point3 = Point3.init(a_scaled + 0.9 * utils.random_float(), 0.2, b_scaled + 0.9 * utils.random_float());

            if ((Vec3.sub(center, Point3.init(4, 0.2, 0)).length() > 0.9)) {
                if (choose_mat < 0.8) {
                    const albedo = Vec3.mult(Colour.random(), Colour.random());
                    const m = try material.Lambertian.init(self.allocator, albedo);
                    const s = try hittable.Sphere.init(self.allocator, center, 0.2, &m.material);
                    try self.list.add(&s.hittable);
                } else if (choose_mat < 0.95) {
                    const albedo = Colour.random_in_range(0.5, 1.0);
                    const fuzz = utils.random_float_in_range(0, 0.5);
                    const m = try material.Metal.init(self.allocator, albedo, fuzz);
                    const s = try hittable.Sphere.init(self.allocator, center, 0.2, &m.material);
                    try self.list.add(&s.hittable);
                } else {
                    const m = try material.Dielectric.init(self.allocator, 1.5);
                    const s = try hittable.Sphere.init(self.allocator, center, 0.2, &m.material);
                    try self.list.add(&s.hittable);
                }
            }
        }
    }

    const m1 = try material.Dielectric.init(self.allocator, 1.5);
    const s1 = try hittable.Sphere.init(self.allocator, Point3.init(0, 1, 0), 1.0, &m1.material);
    try self.list.add(&s1.hittable);

    const m2 = try material.Lambertian.init(self.allocator, Colour.init(0.4, 0.2, 0.1));
    const s2 = try hittable.Sphere.init(self.allocator, Point3.init(-4, 1, 0), 1.0, &m2.material);
    try self.list.add(&s2.hittable);

    const m3 = try material.Metal.init(self.allocator, Colour.init(0.7, 0.6, 0.5), 0.0);
    const s3 = try hittable.Sphere.init(self.allocator, Point3.init(4, 1, 0), 1.0, &m3.material);
    try self.list.add(&s3.hittable);
}
