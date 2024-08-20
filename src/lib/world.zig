const std = @import("std");
const vec3 = @import("vec3.zig");
const hittable = @import("hittable.zig");
const camera = @import("camera.zig");
const material = @import("material.zig");
const colour = @import("colour.zig");

pub const World = struct {
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
        const material_ground = try material.Lambertian.init(self.allocator, colour.Colour.init(0.8, 0.8, 0.0));
        const material_center = try material.Lambertian.init(self.allocator, colour.Colour.init(0.1, 0.2, 0.5));
        const material_left = try material.Metal.init(self.allocator, colour.Colour.init(0.8, 0.8, 0.8), 0.3);
        const material_right = try material.Metal.init(self.allocator, colour.Colour.init(0.8, 0.6, 0.2), 1.0);

        var sphere1 = try self.allocator.create(hittable.Sphere);
        sphere1.* = hittable.Sphere.init(vec3.Point3.init(0, -100.5, -1), 100, &material_ground.material);
        try self.list.add(&sphere1.hittable);

        var sphere2 = try self.allocator.create(hittable.Sphere);
        sphere2.* = hittable.Sphere.init(vec3.Point3.init(0, 0.0, -1.2), 0.5, &material_center.material);
        try self.list.add(&sphere2.hittable);

        var sphere3 = try self.allocator.create(hittable.Sphere);
        sphere3.* = hittable.Sphere.init(vec3.Point3.init(-1, 0, -1), 0.5, &material_left.material);
        try self.list.add(&sphere3.hittable);

        var sphere4 = try self.allocator.create(hittable.Sphere);
        sphere4.* = hittable.Sphere.init(vec3.Point3.init(1, 0, -1), 0.5, &material_right.material);
        try self.list.add(&sphere4.hittable);
    }
};
