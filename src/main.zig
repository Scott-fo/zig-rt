const std = @import("std");
const vec3 = @import("lib/vec3.zig");
const hittable = @import("lib/hittable.zig");
const camera = @import("lib/camera.zig");
const wr = @import("lib/world.zig");
const utils = @import("lib/utils.zig");

test {
    _ = @import("lib/vec3.zig");
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

    const world = try wr.World.init(allocator);
    defer world.deinit();

    const c = camera.Camera.init();
    try c.render(writer, world.list);

    try buffered_writer.flush();
}
