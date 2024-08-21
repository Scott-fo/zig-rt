const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
const hittable = @import("hittable.zig");
const colour = @import("colour.zig");
const utils = @import("utils.zig");
const std = @import("std");

pub const Material = struct {
    scatterFn: *const fn (self: *Material, r_in: Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *Ray) bool,
    deinitFn: *const fn (self: *Material, allocator: std.mem.Allocator) void,

    pub fn scatter(self: *Material, r_in: Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *Ray) bool {
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

    pub fn scatter(material: *Material, _: Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *Ray) bool {
        const self: *Lambertian = @fieldParentPtr("material", material);

        var scatter_direction = Vec3.add(rec.normal, Vec3.random_unit_vector());

        if (scatter_direction.near_zero()) {
            scatter_direction = rec.normal;
        }

        scattered.* = Ray.init(rec.p, scatter_direction);
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

    pub fn scatter(material: *Material, r_in: Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *Ray) bool {
        const self: *Metal = @fieldParentPtr("material", material);

        var reflected = Vec3.reflect(r_in.direction, rec.normal);
        reflected = Vec3.add(reflected.unit_vector(), Vec3.scale(Vec3.random_unit_vector(), self.fuzz));

        scattered.* = Ray.init(rec.p, reflected);
        attenuation.* = self.albedo;

        return (Vec3.dot(scattered.direction, rec.normal) > 0);
    }
};

pub const Dielectric = struct {
    refraction_index: f32,
    material: Material,

    pub fn init(allocator: std.mem.Allocator, refraction_index: f32) !*Dielectric {
        const self = try allocator.create(Dielectric);
        self.* = Dielectric{
            .refraction_index = refraction_index,
            .material = .{
                .scatterFn = scatter,
                .deinitFn = deinit,
            },
        };

        return self;
    }

    pub fn deinit(material: *Material, allocator: std.mem.Allocator) void {
        const self: *Dielectric = @fieldParentPtr("material", material);
        allocator.destroy(self);
    }

    pub fn scatter(material: *Material, r_in: Ray, rec: hittable.HitRecord, attenuation: *colour.Colour, scattered: *Ray) bool {
        const self: *Dielectric = @fieldParentPtr("material", material);
        attenuation.* = colour.Colour.init(1, 1, 1);

        const ri: f32 = if (rec.front_face) (1.0 / self.refraction_index) else self.refraction_index;
        const unit_direction = r_in.direction.unit_vector();
        const cos_theta: f32 = @min(Vec3.dot(unit_direction.neg(), rec.normal), 1.0);
        const sin_theta: f32 = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = ri * sin_theta > 1.0;

        var direction: Vec3 = undefined;
        if (cannot_refract or reflectance(cos_theta, ri) > utils.random_float()) {
            direction = Vec3.reflect(unit_direction, rec.normal);
        } else {
            direction = Vec3.refract(unit_direction, rec.normal, ri);
        }

        scattered.* = Ray.init(rec.p, direction);

        return true;
    }

    fn reflectance(cosine: f32, refraction_index: f32) f32 {
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;

        return r0 + (1 - r0) * std.math.pow(f32, 1 - cosine, 5);
    }
};
