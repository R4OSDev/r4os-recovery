R4IMG.R4L
=========

R4IMG is the independent Runtime-R4L for raster and vector image formats. It
owns its implementation, stb_image integration, local V1 contract, and
generated Zig/C/Rust contract bindings. Higher Rust/C consumers use the
original helpers through Libraries/Shared/Rust and Bindings/C/r4img_helpers.h;
see Libraries/Shared/Rust/README.md. Consumers import R4IMG:API_V1:1 and call only
the loaded function table. Pixel and scratch buffers always remain owned by
the calling process.

The current implementation supports PNG, JPEG, BMP, and a bounded static SVG
2 subset with ARGB output, alpha composition, aspect-ratio handling, software
rasterization, and bounded scaling. Optional consumer callbacks handle SVG
text and link regions.

Build and test:

    Build.bat R4IMG test
    ./Build.sh R4IMG test

The optional host profile compares the same opaque Full-HD bilinear scaling
workload under both manifest optimization modes. It is not part of the normal
test gate:

    Build.bat R4IMG profile -Dhost-test-optimize=ReleaseSmall
    Build.bat R4IMG profile -Dhost-test-optimize=ReleaseFast
    ./Build.sh R4IMG profile -Dhost-test-optimize=ReleaseSmall
    ./Build.sh R4IMG profile -Dhost-test-optimize=ReleaseFast

Tests cover the contract, provider, real decoder paths, runtime table, and an
independent C consumer.

Color-aware consumers additionally import PNG_V1 for PNG metadata, ICC
extraction and full-precision RGBA16 samples, or RASTER_V1 for JPEG ICC/Exif
and BMP V4/V5 characterization. The ColorDecoder(R4GFX) facade connects these
metadata interfaces to the shared COLOR_V1 CMM without decoder-owned color
math. Untagged sRGB is an explicit application policy; unknown/linked/CMYK
source descriptions are never silently relabeled. API_V1 remains unchanged.
See Docs/API.md for layouts and workspace Docs/Desktop/GrafikFarbe07925.txt
for pipeline ownership, display profiles and output limitations.

Optional native JPEG consumer (0.80.30)
-------------------------------------
The compiled Zig binding exports NativeJpeg.Consumer(video), instantiated
with the R4VIDEO binding. capabilities checks the real VIDEO_V1 AMD/JPEG
provider and source dimensions; start/advance return one canonical NV12
image lease. The encoded baseline 8-bit 4:2:0 image remains borrowed until
send succeeds or close completes. Even dimensions 64..4096 and packets up
to 8 MB are accepted; the decoder validates a single complete SOI..EOI scan.

The caller retains RASTER_V1 ICC/Exif characterization, orientation and
R4GFX color policy. NativeJpeg performs no CPU pixel map, RGB conversion or
implicit fallback. release retries the exact caller-supplied consumer receipt
until acknowledged. close may begin with a held image and waits for that
release and decoder resource retirement before destroy. One extra receive
slot lets drain observe EOS while the image is held. Runtime/API_V1 and the
R4IMG module version remain unchanged; this is an optional compiled facade.
The 0.80.30 SMP4 probe uses the actual facade and R4VIDEO with modeled GPU
responses. Physical JPEG pixels and color qualification remain in 0.80.39.
