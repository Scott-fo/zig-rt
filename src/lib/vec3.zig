const std = @import("std");

pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn default() Vec3 {
        return Vec3{
            .x = 0,
            .y = 0,
            .z = 0,
        };
    }

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn neg(self: Vec3) Vec3 {
        return Vec3{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
        };
    }

    pub fn addAssign(self: *Vec3, other: Vec3) void {
        self.x += other.x;
        self.y += other.y;
        self.z += other.z;
    }

    pub fn scaleAssign(self: *Vec3, t: f32) void {
        self.x *= t;
        self.y *= t;
        self.z *= t;
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
};

pub const Point3 = Vec3;

pub inline fn add(u: Vec3, v: Vec3) Vec3 {
    return Vec3{
        .x = u.x + v.x,
        .y = u.y + v.y,
        .z = u.z + v.z,
    };
}

pub inline fn sub(u: Vec3, v: Vec3) Vec3 {
    return Vec3{
        .x = u.x - v.x,
        .y = u.y - v.y,
        .z = u.z - v.z,
    };
}

pub inline fn mult(u: Vec3, v: Vec3) Vec3 {
    return Vec3{
        .x = u.x * v.x,
        .y = u.y * v.y,
        .z = u.z * v.z,
    };
}

pub inline fn scale(u: Vec3, t: f32) Vec3 {
    return Vec3{
        .x = u.x * t,
        .y = u.y * t,
        .z = u.z * t,
    };
}

pub fn dot(u: Vec3, v: Vec3) f32 {
    return u.x * v.x + u.y * v.y + u.z * v.z;
}

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return Vec3{
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

test "addAssign" {
    var u = Vec3.init(1, 2, 3);
    const v = Vec3.init(1, 2, 3);

    u.addAssign(v);

    try std.testing.expectEqual(2, u.x);
    try std.testing.expectEqual(4, u.y);
    try std.testing.expectEqual(6, u.z);
}

test "scaleAssign" {
    var v = Vec3.init(1, 2, 3);
    v.scaleAssign(10);

    try std.testing.expectEqual(10, v.x);
    try std.testing.expectEqual(20, v.y);
    try std.testing.expectEqual(30, v.z);
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
