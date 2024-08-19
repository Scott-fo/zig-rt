const vec = @import("vec3.zig");
const fs = @import("std").fs;

pub const Colour = vec.Vec3;

pub fn write_colour(out: anytype, pixel_colour: Colour) !void {
    const r = pixel_colour.x;
    const g = pixel_colour.y;
    const b = pixel_colour.z;

    const ir: i32 = @intFromFloat(255.999 * r);
    const ig: i32 = @intFromFloat(255.999 * g);
    const ib: i32 = @intFromFloat(255.999 * b);

    try out.print("{d} {d} {d}\n", .{ ir, ig, ib });
}
