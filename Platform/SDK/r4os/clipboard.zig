const std = @import("std");
const abi = @import("r4os_contract").abi;
const program = @import("program.zig");

pub const Info = abi.ClipboardInfo;
pub const max_text_bytes = abi.clipboard_max_text_bytes;

pub const ReadResult = struct {
    code: i32 = 0,
    text: []const u8 = "",
    required_len: u32 = 0,
    revision: u32 = 0,

    pub fn ok(self: ReadResult) bool {
        return self.code >= 0;
    }
};

pub fn writeText(ctx: *const program.Context, text: []const u8) i32 {
    return ctx.clipboardWrite(text);
}

pub fn clear(ctx: *const program.Context) i32 {
    return ctx.clipboardClear();
}

pub fn query(ctx: *const program.Context) Info {
    var out = Info{};
    _ = ctx.clipboardInfo(&out);
    return out;
}

pub fn hasText(ctx: *const program.Context) bool {
    const out = query(ctx);
    return (out.flags & abi.clipboard_flag_has_text) != 0 and out.length > 0;
}

pub fn readText(ctx: *const program.Context, out: []u8) ReadResult {
    var meta = Info{};
    const meta_code = ctx.clipboardInfo(&meta);
    const code = ctx.clipboardRead(out);
    if (code < 0) {
        return .{
            .code = code,
            .required_len = if (meta_code >= 0) meta.length else 0,
            .revision = if (meta_code >= 0) meta.revision else ctx.clipboardRevision(),
        };
    }
    const len: usize = @intCast(code);
    return .{
        .code = code,
        .text = out[0..@min(len, out.len)],
        .required_len = if (meta_code >= 0) meta.length else @intCast(len),
        .revision = if (meta_code >= 0) meta.revision else ctx.clipboardRevision(),
    };
}

pub fn resultName(code: i32) []const u8 {
    if (code >= 0) return "ok";
    return switch (code) {
        abi.clipboard_error_invalid => "invalid",
        abi.clipboard_error_too_large => "too-large",
        abi.clipboard_error_buffer_too_small => "buffer-too-small",
        abi.clipboard_error_unsupported => "unsupported",
        else => "error",
    };
}

test "clipboard result names are stable" {
    try std.testing.expectEqualStrings("ok", resultName(0));
    try std.testing.expectEqualStrings("ok", resultName(42));
    try std.testing.expectEqualStrings("invalid", resultName(abi.clipboard_error_invalid));
    try std.testing.expectEqualStrings("too-large", resultName(abi.clipboard_error_too_large));
    try std.testing.expectEqualStrings("buffer-too-small", resultName(abi.clipboard_error_buffer_too_small));
    try std.testing.expectEqualStrings("unsupported", resultName(abi.clipboard_error_unsupported));
}
