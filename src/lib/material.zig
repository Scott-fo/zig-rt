const ray = @import("ray.zig");
const hittable = @import("hittable.zig");
const colour = @import("colour.zig");
const vec3 = @import("vec3.zig");
const std = @import("std");

pub const Material = struct {
    scatterFn: *const fn (self: *Material, r_in: ray.Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *ray.Ray) bool,
    deinitFn: *const fn (self: *Material, allocator: std.mem.Allocator) void,

    pub fn scatter(self: *Material, r_in: ray.Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *ray.Ray) bool {
        return self.scatterFn(self, r_in, rec, attenuation, scattered);
    }

    pub fn deinit(self: *Material, allocator: std.mem.Allocator) void {
        self.deinitFn(self, allocator);
    }
};

pub const Lambertian = struct {
    albedo: colour.Colour,
    material: Material,

    pub fn init(allocator: std.mem.Allocator, albedo: colour.Colour) !*Lambertian {
        const self = try allocator.create(Lambertian);
        self.* = Lambertian{
            .albedo = albedo,
            .material = .{
                .deinitFn = deinit,
                .scatterFn = scatter,
            },
        };

        return self;
    }

    pub fn deinit(material: *Material, allocator: std.mem.Allocator) void {
        const self: *Lambertian = @fieldParentPtr("material", material);
        allocator.destroy(self);
    }

    pub fn scatter(material: *Material, _: ray.Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *ray.Ray) bool {
        const self: *Lambertian = @fieldParentPtr("material", material);

        var scatter_direction = vec3.add(rec.normal, vec3.random_unit_vector());

        if (scatter_direction.near_zero()) {
            scatter_direction = rec.normal;
        }

        scattered.* = ray.Ray.init(rec.p, scatter_direction);
        attenuation.* = self.albedo;

        return true;
    }
};

pub const Metal = struct {
    albedo: colour.Colour,
    fuzz: f32,
    material: Material,

    pub fn init(allocator: std.mem.Allocator, albedo: colour.Colour, fuzz: f32) !*Metal {
        const self = try allocator.create(Metal);
        self.* = Metal{
            .albedo = albedo,
            .fuzz = if (fuzz < 1) fuzz else 1,
            .material = .{
                .scatterFn = scatter,
                .deinitFn = deinit,
            },
        };

        return self;
    }

    pub fn deinit(material: *Material, allocator: std.mem.Allocator) void {
        const self: *Metal = @fieldParentPtr("material", material);
        allocator.destroy(self);
    }

    pub fn scatter(material: *Material, r_in: ray.Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *ray.Ray) bool {
        const self: *Metal = @fieldParentPtr("material", material);

        var reflected = vec3.reflect(r_in.direction, rec.normal);
        reflected = vec3.add(reflected.unit_vector(), vec3.scale(vec3.random_unit_vector(), self.fuzz));

        scattered.* = ray.Ray.init(rec.p, reflected);
        attenuation.* = self.albedo;

        return (vec3.dot(scattered.direction, rec.normal) > 0);
    }
};
