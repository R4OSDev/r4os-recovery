const std = @import("std");
const r4font_build = @import("R4FONT/host_build.zig");

pub const addR4fontHostDecoder = r4font_build.addHostDecoder;
pub const addR4gfxHostColor = @import("R4GFX/color_build.zig").addAt;

/// Das Rootpaket baut keine Runtime-Library. Es stellt ausschliesslich die
/// versionierten Consumer-Bindings als benannte Paketpfade bereit; jede R4L
/// bleibt in ihrer eigenen Einheit baubar und getestet.
pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("r4amd_copy", b.path("R4AMD/Source/copy.zig"));
    b.addNamedLazyPath("r4amd_pm4", b.path("R4AMD/Source/pm4.zig"));
    b.addNamedLazyPath("r4amd_driver", b.path("R4AMD/Source/driver.zig"));
    b.addNamedLazyPath("r4amd_native_build", b.path("R4AMD/Tools/Build.ps1"));
    b.addNamedLazyPath("r4amd_zig_binding", b.path("R4AMD/Bindings/Zig/r4amd.zig"));
    b.addNamedLazyPath("r4amd_c_include", b.path("R4AMD/Bindings/C"));
    b.addNamedLazyPath("r4aco_zig_binding", b.path("R4ACO/Bindings/Zig/r4aco.zig"));
    b.addNamedLazyPath("r4aco_worker", b.path("R4ACO/Bindings/Zig/worker.zig"));
    b.addNamedLazyPath("r4aco_shaders", b.path("R4ACO/Bindings/Zig/shaders.zig"));
    b.addNamedLazyPath("r4aco_c_include", b.path("R4ACO/Bindings/C"));
    b.addNamedLazyPath("r4enc_zig_binding", b.path("R4ENC/Bindings/Zig/r4enc.zig"));
    b.addNamedLazyPath("r4enc_c_include", b.path("R4ENC/Bindings/C"));
    b.addNamedLazyPath("r4enc_recording_mux", b.path("R4ENC/Bindings/Zig/recording_mux.zig"));
    b.addNamedLazyPath("r4enc_recording_pixels", b.path("R4ENC/Bindings/Zig/recording_pixels.zig"));
    b.addNamedLazyPath("r4video_zig_binding", b.path("R4VIDEO/Bindings/Zig/r4video.zig"));
    b.addNamedLazyPath("r4video_playback", b.path("R4VIDEO/Bindings/Zig/playback.zig"));
    b.addNamedLazyPath("r4video_c_include", b.path("R4VIDEO/Bindings/C"));
    b.addNamedLazyPath("r4gl_zig_binding", b.path("R4GL/Bindings/Zig/r4gl.zig"));
    b.addNamedLazyPath("r4gl_c_include", b.path("R4GL/Bindings/C"));
    b.addNamedLazyPath("r4vk_zig_binding", b.path("R4VK/Bindings/Zig/r4vk.zig"));
    b.addNamedLazyPath("r4vk_c_include", b.path("R4VK/Bindings/C"));
    b.addNamedLazyPath("r4nak_zig_binding", b.path("R4NAK/Bindings/Zig/r4nak.zig"));
    b.addNamedLazyPath("r4nak_c_include", b.path("R4NAK/Bindings/C"));
    b.addNamedLazyPath("r4nak_worker", b.path("R4NAK/Bindings/Zig/worker.zig"));
    b.addNamedLazyPath("r4nv_copy", b.path("R4NV/Source/copy.zig"));
    b.addNamedLazyPath("r4nv_video", b.path("R4NV/Source/video.zig"));
    b.addNamedLazyPath("r4nv_encode", b.path("R4NV/Source/encode.zig"));
    b.addNamedLazyPath("r4nv_render", b.path("R4NV/Source/render.zig"));
    b.addNamedLazyPath("r4nv_render_reference", b.path("R4NV/Source/render_reference_cases.zig"));
    b.addNamedLazyPath("r4nv_telemetry", b.path("R4NV/Source/telemetry.zig"));
    b.addNamedLazyPath("r4nv_zig_binding", b.path("R4NV/Bindings/Zig/r4nv.zig"));
    b.addNamedLazyPath("r4nv_c_include", b.path("R4NV/Bindings/C"));
    b.addNamedLazyPath("r4gfx_zig_binding", b.path("R4GFX/Bindings/Zig/r4gfx_abi.zig"));
    b.addNamedLazyPath("r4gfx_queue", b.path("R4GFX/Bindings/Zig/queue.zig"));
    b.addNamedLazyPath("r4gfx_edid", b.path("R4GFX/Display/edid.zig"));
    b.addNamedLazyPath("r4gfx_outputs", b.path("R4GFX/Bindings/Zig/outputs.zig"));
    b.addNamedLazyPath("r4gfx_topology", b.path("R4GFX/Display/topology.zig"));
    b.addNamedLazyPath("r4gfx_desktop_outputs", b.path("R4GFX/Display/desktop_outputs.zig"));
    b.addNamedLazyPath("r4gfx_readback", b.path("R4GFX/Display/readback.zig"));
    b.addNamedLazyPath("r4gfx_transfer", b.path("R4GFX/Display/transfer.zig"));
    b.addNamedLazyPath("r4gfx_c_include", b.path("R4GFX/Bindings/C"));
    b.addNamedLazyPath("r4std_zig_binding", b.path("R4STD/Bindings/Zig/r4std.zig"));
    b.addNamedLazyPath("r4std_console_text", b.path("R4STD/Bindings/Zig/console_text.zig"));
    b.addNamedLazyPath("r4std_grapheme", b.path("R4STD/Bindings/Zig/grapheme.zig"));
    b.addNamedLazyPath("r4std_path_text", b.path("R4STD/Bindings/Zig/path_text.zig"));
    b.addNamedLazyPath("r4std_legacy_tables", b.path("R4STD/Source/codec_tables.zig"));
    b.addNamedLazyPath("r4std_c_include", b.path("R4STD/Bindings/C"));
    b.addNamedLazyPath("r4img_zig_binding", b.path("R4IMG/Bindings/Zig/r4img.zig"));
    b.addNamedLazyPath("r4img_c_include", b.path("R4IMG/Bindings/C"));
    b.addNamedLazyPath("r4font_zig_binding", b.path("R4FONT/Bindings/Zig/r4font.zig"));
    b.addNamedLazyPath("r4font_c_include", b.path("R4FONT/Bindings/C"));
    b.addNamedLazyPath("r4font_app_fonts", b.path("R4FONT/Bindings/Zig/app_fonts.zig"));
    b.addNamedLazyPath("r4font_font_tools", b.path("R4FONT/Bindings/Zig/font_tools.zig"));
    b.addNamedLazyPath("r4font_import", b.path("R4FONT/Bindings/Zig/font_import.zig"));
    b.addNamedLazyPath("r4font_format", b.path("R4FONT/Bindings/Zig/font_format.zig"));
    const grapheme_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("R4STD/Bindings/Zig/grapheme.zig"),
        .target = b.graph.host,
        .optimize = .ReleaseSafe,
    }) });
    b.step("test-grapheme", "Pinned Unicode17 extended grapheme vectors, streaming and bounded prefixes").dependOn(&b.addRunArtifact(grapheme_tests).step);
    const path_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("R4STD/Bindings/Zig/path_text.zig"),
        .target = b.graph.host,
        .optimize = .ReleaseSafe,
    }) });
    b.step("test-path-text", "Test shared strict transport pathname boundaries").dependOn(&b.addRunArtifact(path_tests).step);
}
