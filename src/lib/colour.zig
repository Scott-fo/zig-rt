const fs = @import("std").fs;
const std = @import("std");

const Vec3 = @import("Vec3.zig");
const Interval = @import("Interval.zig");

pub const Colour = Vec3;

inline fn linear_to_gamma(linear_component: f32) f32 {
    if (linear_component > 0) {
        return @sqrt(linear_component);
    }

    return 0;
}

pub fn write_colour(out: anytype, pixel_colour: Colour) !void {
    var r = pixel_colour.x;
    var g = pixel_colour.y;
    var b = pixel_colour.z;

    r = linear_to_gamma(r);
    g = linear_to_gamma(g);
    b = linear_to_gamma(b);

    const intensity = Interval.init(0.000, 0.999);

    const ir: i32 = @intFromFloat(256 * intensity.clamp(r));
    const ig: i32 = @intFromFloat(256 * intensity.clamp(g));
    const ib: i32 = @intFromFloat(256 * intensity.clamp(b));

    try out.print("{d} {d} {d}\n", .{ ir, ig, ib });
}
