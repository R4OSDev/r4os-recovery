//! Existing data-parity step: execute the real C ABI, not only layout asserts.
const std = @import("std");
comptime {
    _ = @import("text_composition_runtime.zig");
}
extern fn R4TestTextCompositionABI() callconv(.c) c_int;
pub fn main() void {
    const code = R4TestTextCompositionABI();
    if (code != 0) {
        std.debug.print("TextComposition C ABI failed at C line {d}\n", .{code});
        std.process.exit(1);
    }
}
