//! Concrete spelling of the public structural selection parameter. The
//! rendering implementation and all clipping/Unicode work remain in gui.zig.
const g = @import("gui.zig");
pub const telemetry_field_count = @import("gfx_telemetry.zig").fields.len;
pub fn formatKernelVersion(value: @import("r4os_contract").abi.KernelVersion, buffer: []u8) ?[]const u8 {
    return @import("r4dev.zig").formatKernelVersion(value, buffer);
}
pub fn telemetryField(index: usize) ?@import("gfx_telemetry.zig").Field {
    return if (index < telemetry_field_count) @import("gfx_telemetry.zig").fields[index] else null;
}
pub fn telemetryForAdapter(draw: *const @import("r4draw.zig").Context, adapter: u32, mask: u64, output: *@import("r4os_contract").abi.GfxTelemetryState) i32 {
    return @import("gfx_telemetry.zig").forAdapter(draw, adapter, mask, output);
}
pub fn drawTextFieldEx(canvas: g.Canvas, rect: g.Rect, scratch: []u8, value: []const u8, cursor: usize, selection: g.TextRange, focused: bool, disabled: bool, palette: g.Palette) i32 {
    return g.drawTextFieldEx(canvas, rect, scratch, value, cursor, selection, focused, disabled, palette);
}
