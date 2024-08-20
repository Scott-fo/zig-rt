const std = @import("std");

pub inline fn degrees_to_radians(degrees: f32) f32 {
    return degrees * std.math.pi / 180.0;
}

var prng: std.Random.DefaultPrng = undefined;
var rand: std.Random = undefined;

pub fn init_random(seed: u64) void {
    prng = std.Random.DefaultPrng.init(seed);
    rand = prng.random();
}

pub fn random_float() f32 {
    return rand.float(f32);
}

pub fn random_float_in_range(min: f32, max: f32) f32 {
    return min + ((max - min) * random_float());
}
