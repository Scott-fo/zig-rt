const std = @import("std");
const utils = @import("utils.zig");

const Vec3 = @This();
pub const Point3 = Vec3;

x: f32,
y: f32,
z: f32,

pub fn default() Vec3 {
    return .{
        .x = 0,
        .y = 0,
        .z = 0,
    };
}

pub fn init(x: f32, y: f32, z: f32) Vec3 {
    return .{
        .x = x,
        .y = y,
        .z = z,
    };
}

pub fn neg(self: Vec3) Vec3 {
    return .{
        .x = -self.x,
        .y = -self.y,
        .z = -self.z,
    };
}

pub fn unit_vector(self: Vec3) Vec3 {
    return scale(self, 1 / self.length());
}

pub fn length_squared(self: Vec3) f32 {
    return self.x * self.x + self.y * self.y + self.z * self.z;
}

pub fn length(self: Vec3) f32 {
    return @sqrt(self.length_squared());
}

pub fn near_zero(self: Vec3) bool {
    const s = 1e-8;
    return (@abs(self.x) < s and @abs(self.y) < s and @abs(self.z) < s);
}

pub fn random() Vec3 {
    return Vec3.init(utils.random_float(), utils.random_float(), utils.random_float());
}

pub fn random_in_range(min: f32, max: f32) Vec3 {
    return Vec3.init(utils.random_float_in_range(min, max), utils.random_float_in_range(min, max), utils.random_float_in_range(min, max));
}

pub fn random_in_unit_disk() Vec3 {
    while (true) {
        const p = Vec3.init(utils.random_float_in_range(-1, 1), utils.random_float_in_range(-1, 1), 0);
        if (p.length_squared() < 1) {
            return p;
        }
    }
}

pub inline fn reflect(v: Vec3, n: Vec3) Vec3 {
    return sub(v, scale(n, 2 * dot(v, n)));
}

pub inline fn refract(u: Vec3, n: Vec3, etai_over_etat: f32) Vec3 {
    const cos_theta: f32 = @min(dot(u.neg(), n), 1.0);
    const r_out_perp = scale(add(u, scale(n, cos_theta)), etai_over_etat);

    const scalar: f32 = @sqrt(@abs(1.0 - r_out_perp.length_squared()));
    const r_out_parallel = scale(n, -scalar);

    return add(r_out_perp, r_out_parallel);
}

pub inline fn random_in_unit_sphere() Vec3 {
    while (true) {
        const p = random_in_range(-1, 1);
        if (p.length_squared() < 1) {
            return p;
        }
    }
}

pub inline fn random_unit_vector() Vec3 {
    return random_in_unit_sphere().unit_vector();
}

pub inline fn random_on_hemisphere(normal: Vec3) Vec3 {
    const on_unit_sphere = random_unit_vector();
    if (dot(on_unit_sphere, normal) > 0.0) {
        return on_unit_sphere;
    } else {
        return on_unit_sphere.neg();
    }
}

pub inline fn add(u: Vec3, v: Vec3) Vec3 {
    return .{
        .x = u.x + v.x,
        .y = u.y + v.y,
        .z = u.z + v.z,
    };
}

pub inline fn sub(u: Vec3, v: Vec3) Vec3 {
    return .{
        .x = u.x - v.x,
        .y = u.y - v.y,
        .z = u.z - v.z,
    };
}

pub inline fn mult(u: Vec3, v: Vec3) Vec3 {
    return .{
        .x = u.x * v.x,
        .y = u.y * v.y,
        .z = u.z * v.z,
    };
}

pub inline fn scale(u: Vec3, t: f32) Vec3 {
    return .{
        .x = u.x * t,
        .y = u.y * t,
        .z = u.z * t,
    };
}

pub fn dot(u: Vec3, v: Vec3) f32 {
    return u.x * v.x + u.y * v.y + u.z * v.z;
}

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{
        .x = u.y * v.z - u.z * v.y,
        .y = u.z * v.x - u.x * v.z,
        .z = u.x * v.y - u.y * v.x,
    };
}

test "scale" {
    const v = Vec3.init(1, 2, 3);

    const actual = scale(v, 10);

    try std.testing.expectEqual(10, actual.x);
    try std.testing.expectEqual(20, actual.y);
    try std.testing.expectEqual(30, actual.z);
}

test "mult" {
    const u = Vec3.init(3, 2, 1);
    const v = Vec3.init(1, 2, 3);
    const actual = mult(u, v);

    try std.testing.expectEqual(3, actual.x);
    try std.testing.expectEqual(4, actual.y);
    try std.testing.expectEqual(3, actual.z);
}

test "sub" {
    const u = Vec3.init(1, 2, 3);
    const v = Vec3.init(1, 2, 3);
    const actual = sub(u, v);

    const expected = Vec3.default();

    try std.testing.expectEqual(expected.x, actual.x);
    try std.testing.expectEqual(expected.y, actual.y);
    try std.testing.expectEqual(expected.z, actual.z);
}

test "add" {
    const u = Vec3.init(1, 2, 3);
    const v = Vec3.init(1, 2, 3);
    const actual = add(u, v);

    try std.testing.expectEqual(2, actual.x);
    try std.testing.expectEqual(4, actual.y);
    try std.testing.expectEqual(6, actual.z);
}

test "default" {
    const actual = Vec3.default();
    try std.testing.expectEqual(0, actual.x);
    try std.testing.expectEqual(0, actual.y);
    try std.testing.expectEqual(0, actual.z);
}

test "init" {
    const actual = Vec3.init(1, 2, 3);

    try std.testing.expectEqual(1, actual.x);
    try std.testing.expectEqual(2, actual.y);
    try std.testing.expectEqual(3, actual.z);
}

test "neg" {
    const v = Vec3.init(1, 2, 3);
    const actual = v.neg();

    try std.testing.expectEqual(-1, actual.x);
    try std.testing.expectEqual(-2, actual.y);
    try std.testing.expectEqual(-3, actual.z);
}

test "dot" {
    const u = Vec3.init(1, 2, 3);
    const v = Vec3.init(1, 2, 3);

    const actual = dot(u, v);

    try std.testing.expectEqual(14, actual);
}

test "cross" {
    const u = Vec3.init(1, 2, 3);
    const v = Vec3.init(4, 5, 6);
    const actual = cross(u, v);

    try std.testing.expectEqual(-3.0, actual.x);
    try std.testing.expectEqual(6.0, actual.y);
    try std.testing.expectEqual(-3.0, actual.z);
}

test "length_squared" {
    const u = Vec3.init(1, 2, 3);
    const actual = u.length_squared();

    try std.testing.expectEqual(14, actual);
}

test "length" {
    const u = Vec3.init(1, 2, 3);
    const actual = u.length();

    try std.testing.expectEqual(@sqrt(14.0), actual);
}
