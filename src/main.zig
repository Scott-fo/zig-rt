const std = @import("std");
const hittable = @import("lib/hittable.zig");
const Camera = @import("lib/Camera.zig");
const World = @import("lib/World.zig");
const utils = @import("lib/utils.zig");

test {
    _ = @import("lib/Vec3.zig");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    utils.init_random(@intCast(std.time.timestamp()));

    const file = try std.fs.cwd().createFile(
        "image.ppm",
        .{ .read = true, .truncate = true },
    );
    defer file.close();

    var buffered_writer = std.io.bufferedWriter(file.writer());
    const writer = buffered_writer.writer();

    const world = try World.init(allocator);
    defer world.deinit();

    var c = Camera.init();
    try c.render(allocator, writer, world.list);

    try buffered_writer.flush();
}
