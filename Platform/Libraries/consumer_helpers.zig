//! Consumer helpers belong to the libraries. The native implementations are
//! shared by Zig, C and Rust; this file only selects concrete public entries.
const std = @import("std");
pub const r4os = @import("r4os");
pub const standard = @import("R4STD/Bindings/Zig/r4std.zig");
pub const text = standard.text;
pub const settings = standard.settings;
pub const date = standard.date;
pub const time = standard.time;
pub const config = standard.config;
pub const codec = standard.codec;
pub const grapheme = @import("R4STD/Bindings/Zig/grapheme.zig");
pub const path_text = @import("R4STD/Bindings/Zig/path_text.zig");
pub const console_text = @import("R4STD/Bindings/Zig/console_text.zig");
// The font importer imports the same decoder through its named dependency.
pub const decode = console_text.decode;
pub const shortcut = standard.shortcut;
pub const app_assoc = standard.app_assoc;
pub const file_handler = standard.file_handler;
pub const subsystem_runtime = standard.subsystem_runtime;
pub const image = @import("R4IMG/Bindings/Zig/r4img.zig");
pub const font = @import("R4FONT/Bindings/Zig/r4font.zig");
pub const app_fonts = @import("R4FONT/Bindings/Zig/app_fonts.zig");
pub const font_import = @import("R4FONT/Bindings/Zig/font_import.zig");
pub const font_format = @import("R4FONT/Bindings/Zig/font_format.zig");
pub const image_color = image.ColorDecoder(@import("r4gfx_binding"));
pub const native_jpeg = image.NativeJpeg(@import("R4VIDEO/Bindings/Zig/r4video.zig"));
pub const native_jpeg_format = @import("R4IMG/Bindings/Zig/native_jpeg.zig");
pub const support = @import("Shared/Language/support.zig");
pub const adapters = @import("consumer_adapters.zig");
pub const media = @import("consumer_media.zig");
// The receiver binding's named import shares these exact owner definitions.
pub const Error = media.r4gfx_edid.Error;
pub const Report = media.r4gfx_edid.Report;
pub const color = media.r4gfx_edid.color;
pub const links = media.r4gfx_edid.links;
pub const timing = media.r4gfx_edid.timing;
pub const parse = media.r4gfx_edid.parse;
pub const max_blocks = media.r4gfx_edid.max_blocks;
pub const modules = .{ standard, text, settings, date, time, config, codec, grapheme, path_text, console_text, shortcut, app_assoc, file_handler, subsystem_runtime, image, image_color, native_jpeg, native_jpeg_format, font, app_fonts, font_import, font_format, support, adapters, adapters.Config, adapters.Settings, adapters.TextFile, adapters.FileHandler, adapters.Subsystem } ++ media.modules;

pub fn moduleType(comptime T: type) bool {
    if (T == @This() or T == media or T == media.gfx_api or T == media.aco_api or T == media.nak_api) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return T == standard.abi or T == image.abi or T == font.abi or T == standard.text_file;
}

pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    if (T == std.mem.Allocator or T == support.Session or T == r4os.r4sys.Context) return true;
    const name = @typeName(T);
    if (std.mem.endsWith(u8, name, "Client")) return true;
    // Allocator/container internals and SDK dispatch owners are not library
    // helpers. They are borrowed native values, never foreign field layouts.
    for (.{ "array_list.", "hash_map.", "atomic.", "mem.Allocator", "r4os.", "program.", "r4sys.", "r4desk.", "r4draw.", "r4audio.", "runtime_context.", "gui.", "app_gui." }) |prefix| {
        if (std.mem.startsWith(u8, name, prefix)) return true;
    }
    return false;
}
