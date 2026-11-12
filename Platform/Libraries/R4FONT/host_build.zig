const std = @import("std");

const freetype_sources = [_][]const u8{
    "freetype/src/base/ftbase.c",
    "freetype/src/base/ftbitmap.c",
    "freetype/src/base/ftdebug.c",
    "freetype/src/base/ftinit.c",
    "freetype/src/base/ftmm.c",
    "freetype/src/autofit/autofit.c",
    "freetype/src/cff/cff.c",
    "freetype/src/gzip/ftgzip.c",
    "freetype/src/psaux/psaux.c",
    "freetype/src/pshinter/pshinter.c",
    "freetype/src/psnames/psnames.c",
    "freetype/src/sfnt/sfnt.c",
    "freetype/src/smooth/smooth.c",
    "freetype/src/truetype/truetype.c",
};

const brotli_sources = [_][]const u8{
    "brotli/common/constants.c",
    "brotli/common/context.c",
    "brotli/common/dictionary.c",
    "brotli/common/platform.c",
    "brotli/common/shared_dictionary.c",
    "brotli/common/transform.c",
    "brotli/dec/bit_reader.c",
    "brotli/dec/decode.c",
    "brotli/dec/huffman.c",
    "brotli/dec/prefix.c",
    "brotli/dec/state.c",
    "brotli/dec/static_init.c",
};

const bridge_sources = [_][]const u8{
    "src/r4font_bridge.c",
    "src/r4font_system.c",
};

const host_c_flags: []const []const u8 = &.{
    "-std=c11",
    "-fno-builtin",
    "-DFT2_BUILD_LIBRARY",
    "-DFT_CONFIG_OPTIONS_H=<r4font_ftoption.h>",
    "-DFT_CONFIG_MODULES_H=<r4font_ftmodule.h>",
    "-DBROTLI_STATIC_INIT=NONE",
};

pub fn addHostDecoder(b: *std.Build, module: *std.Build.Module, root: std.Build.LazyPath) void {
    module.addIncludePath(root.path(b, "freetype/include"));
    module.addIncludePath(root.path(b, "brotli/include"));
    module.addIncludePath(root.path(b, "config"));
    module.addIncludePath(root.path(b, "include"));
    module.addCSourceFiles(.{ .root = root, .files = &freetype_sources, .flags = host_c_flags });
    module.addCSourceFiles(.{ .root = root, .files = &brotli_sources, .flags = host_c_flags });
    module.addCSourceFiles(.{ .root = root, .files = &bridge_sources, .flags = host_c_flags });
}

