const std = @import("std");
const vec3 = @import("vec3.zig");
const hittable = @import("hittable.zig");
const camera = @import("camera.zig");

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
        for (self.list.objects.items) |obj| {
            // Later, define a destroy on the obj itself so we can use more than
            // sphere.
            const sphere: *hittable.Sphere = @fieldParentPtr("hittable", obj);
            self.allocator.destroy(sphere);
        }

        self.list.deinit();
        self.allocator.destroy(self.list);
    }

    fn build_world(self: World) !void {
        var sphere1 = try self.allocator.create(hittable.Sphere);
        sphere1.* = hittable.Sphere.init(vec3.Point3.init(0, 0, -1), 0.5);
        try self.list.add(&sphere1.hittable);

        var sphere2 = try self.allocator.create(hittable.Sphere);
        sphere2.* = hittable.Sphere.init(vec3.Point3.init(0, -100.5, -1), 100);
        try self.list.add(&sphere2.hittable);
    }
};
