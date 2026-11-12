# R4OS Runtime Libraries

This repository contains the independent Runtime-R4L units R4STD, R4IMG, R4GFX, R4NV,
R4NAK, R4VK, R4GL, R4VIDEO, R4ENC, R4FONT, R4AMD, and R4ACO. Each library owns its implementation, contract, baseline, Zig and C
bindings, manifest, and tests. Generated Rust table consumers live beside the
Zig/C contracts. Higher text/image/font/graphics/media/compiler Rust and C helpers are described in
[Shared/Rust/README.md](Shared/Rust/README.md); they execute the original owner
functions and are linked explicitly, without changing provider binaries.

## Build and validation

Build and test all libraries on Windows:

    Build.bat test

Build and test one unit:

    Build.bat R4STD test
    Build.bat R4IMG test
    Build.bat R4FONT test
    ./Build.sh R4GFX test
    ./Build.sh R4NV test
    ./Build.sh R4NAK
    ./Build.sh R4VK
    ./Build.sh R4GL
    ./Build.sh R4VIDEO -Doffline=true

R4NAK is the freestanding C/Rust SPIR-V/NIR/NAK runtime compiler. Its first
build needs the pinned host tools and sources described in `R4NAK/README.md`.
R4VK is the native Mesa Vulkan provider under development. Its regular build
prepares the matching NVK/NIL/NAK dependencies; see `R4VK/README.md`. It remains
available as an optional runtime in slim/full images. R4GL provides Mesa EGL/OpenGL with explicit graphics providers; see
`R4GL/README.md` for the current profile and lifecycle contract.
R4VIDEO provides bounded H.264 software, NVIDIA NVDEC and AMD VCN1 decoding
through explicit VIDEO_V1 backend selection. Its pinned
FFmpeg build uses clang/NASM; offline builds require the cached archive. It is
included in normal profiles with corresponding sources; see `R4VIDEO/README.md`.

R4AMD provides real AddrLib image layouts and bounded SDMA/PM4 encoders.
R4ACO links Mesa SPIR-V/NIR/ACO for CPU compilation of the fixed Picasso
GFX9 profile, isolated jobs and compiler-bound caches. Both remain outside
normal image profiles until package integration; see their READMEs.

Both `Build.bat` and `./Build.sh` use the shared PowerShell 7 `Build.ps1`. Dependency paths are mapped by
`Settings.R4S`.

The SDK emits pagewise inline stack probes for Zig modules. Native C/C++
profiles pass `-Xclang -fstack-clash-protection` directly to the frontend,
including the shared NAK/Vulkan and portability profiles; the freestanding
driver-level option alone is ignored. The native Rust target already uses
inline probes. Probes preserve the existing ABI and do not allocate or wait;
fixed worker stacks still require bounded resident workspaces.

Detailed German migration notes are preserved in
`DOCUMENTATION.de.txt`.

## License

Original R4OS material is licensed under Apache License 2.0. Vendored code and
test fixtures retain their upstream licenses; see `THIRD_PARTY_NOTICES.md`
and the license files beside that material.
