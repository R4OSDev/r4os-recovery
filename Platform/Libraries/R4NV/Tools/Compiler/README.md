# R4NAK host compiler

This tool builds the pinned Mesa 26.2.2 NIR/NAK compiler and translates nine
documented R4NV shader profiles for SM75, SM86, SM89 and SM120. It produces actual machine code,
the NVIDIA shader header, input NIR and readable NAK assembly. It does not
open a GPU or implement an R4OS runtime compiler.

From the workspace root on Debian 13:

```sh
Repositories/Libraries/R4NV/Tools/Compiler/Build.sh -InstallDependencies -VerifyReproducible
```

Once the host tools and seven source archives are present, use `-Offline`.
`-PrepareSources` only acquires/verifies the shared Mesa source tree and its
locked archive inputs. It needs Git, tar and (for downloads) curl, but does
not require Rust, Meson or the compiler executables. The R4GL software build
uses this path; runtime library builds maintain their own native artifacts.
The shader-generation host build stays outside interactive rendering.

On Windows, run the same `Build.ps1` through `Build.bat` from an x64 developer
environment with these tools on PATH:

- PowerShell 7, Git, curl and tar with xz support.
- LLVM 19.1.7 `clang-cl`, matching libclang, and the Windows SDK/MSVC link
  environment required by the native `x86_64-pc-windows-msvc` Rust target.
- Rust 1.85.1, bindgen 0.71.1 and cbindgen 0.27.0.
- Meson 1.7.0, Ninja 1.12.1, Python 3.10 or newer, Mako, PyYAML and packaging.
- Flex/Bison as recognized by Mesa, if its configuration requests them.

The script checks the fixed compiler-tool versions before preparing sources.
`Sources.lock.json` is the authoritative version/hash list. Windows automatic
dependency installation is not implemented. A native Windows execution of
this new path is still pending; Linux success is not a Windows build result.

The Rust installation must contain its full copyright notices. If they are
outside its standard documentation directory, pass `-RustCopyrightFile PATH`.
On Debian the script uses the installed Rust standard-library copyright file.

## Build boundaries

`MesaStandalone.patch` only adjusts Mesa's build selection and removes
Linux winsys/DRM hardware-test bindings from the standalone compiler. It
enables the real NIR implementation, never its header-only stub. NAK/NIR
instruction lowering, optimization, register allocation and encoding remain
the original pinned code. NVK, DRM, CLC/LLVM, display stacks and shader disk
caches are not selected. libclang is a host binding generator dependency;
there is no LLVM JIT in R4OS.

The six Rust crates and Mesa archive are verified before extraction. Meson
uses only locally cached sources and is forced to use the pinned Rust crates.
The prepared source tree is checked against a file manifest before reuse.
Original sources, local overlay sources, build products and generated shader
outputs remain separate. All workspace paths come from the script and the
Libraries `Settings.R4S` mappings.

Cache/source trees reside in `DevKit/Toolchains/MesaNAK` and `DevKit/.Cache`.
Outputs default to `Artifacts/Tools/R4NAK/Linux-x64` or `Windows-x64`; use
`-OutputDirectory` to select another location relative to the workspace.
`build.json` records the input recipe, tool versions, output hashes, size and
elapsed time. It is written only after the complete output set succeeds.
The host package includes all original source/license archives and Rust
runtime notices under `Legal`; distribute that directory with the host tool.
Nothing from this directory is automatically installed in an R4OS image.

`-VerifyReproducible` translates each profile twice and requires byte-identical
machine code, metadata, NIR and assembly. It performs no hardware or guest test.
The shader output is a compiler artifact, not a GPU execution result.

## Fixed shader contract

`-ShaderModel 75|86|89|120` selects one target; the default remains SM86.
SM75 uses 32 maximum resident warps per multiprocessor; the other profiles use
48, matching the pinned Mesa device table. The selected target participates in
recipe and compiler identity. Its binaries, headers, metadata, NIR and assembly
must independently reproduce before `EmitRuntime.ps1` imports them. SM86 keeps
the existing generated directory; other profiles have separate `SM*` folders.
The renderer must negotiate the measured GPU's class and matching shader model.
Generated code alone establishes neither native bootstrap nor physical support.

| ID | Source profile | Inputs and result |
| --- | --- | --- |
| 1 | Rectangle vertex | Attribute 0: clip-space vec4; 1: normalized UV vec2; 2: premultiplied tint vec4. Writes position and screen-linear UV/tint. |
| 2 | Texture fragment | Samples a 2D texture and multiplies its premultiplied RGBA by the premultiplied tint. |
| 3 | sRGB decode fragment | Unpremultiplies, converts sRGB to linear light, premultiplies and applies the tint. |
| 4 | sRGB encode fragment | Applies a linear-light tint, unpremultiplies, converts to sRGB and premultiplies. |
| 5 | Solid fragment | Writes the interpolated premultiplied tint. |
| 6 | Solid vertex | Uses attributes 0 and 2; writes position/tint without unused UV outputs. Pair with profile 5 or 9. |
| 7 | Color fragment | Named RGB transfer/primaries/range/alpha conversion, white scaling and optional output tone/gamut mapping and dither; CBuf2 coefficients. Pair with profile 1. |
| 8 | YUV fragment | NV12/P010/YUV420P integer plane loads, explicit chroma phase and range/matrix, then shared color conversion; CBuf3 sampling coefficients. Pair with profile 1. |
| 9 | Encode preparation fragment | NV12/I420 integer loads and replicated edges in native NV12 plane views; block-linear R8 targets, CBuf3 geometry. Pair with profile6. |

Profiles 1 and 2–4/7–8 share their UV/tint interface. Profile 6 pairs with 5 or 9,
so the fixed pipeline does not require disabling out-of-range attribute
exceptions for unused vertex outputs.

For RGB profiles, nearest/bilinear filtering is sampler state. Resource ABI4 keeps the combined
TIC/TSC word in constant buffer 1 at byte 0 and normalized source-texel-center
bounds at bytes 16..31. All texture profiles clamp ordinary interpolated UVs
to those bounds, including bilinear crops and one-texel views.

Profile 2 additionally accepts an optional 64-byte logical sampling grid at
bytes 32..95, an atlas rectangle at bytes 96..111 and image extents at bytes
112..119. A zero grid selects the ordinary path. An enabled grid uses native
pixel centers, inverse output rotation, scale in 120ths and two integer
divisions to select exact logical cells and guest texels. Only the final texel
center becomes a normalized float. The driver validates clipped corners and
requires nearest filtering with identity transfer; pixels remain on the GPU.
The reproducible SM86 grid fragment has 2208 code bytes; the largest complete
cache entry across the four ISAs is 12544 bytes (SM120 YUV). Earlier resource ABI keys cannot select these
programs, while the public shader table and payload layouts remain unchanged.

NAK's internal graphics constants use buffer 0: sample locations at byte 0,
masks at byte 16 and an optional printf pointer at byte 48. These single-sample
profiles read none of those internal constants and contain no printf. Both
sRGB conversions preserve zero-alpha pixels without division by zero; their
texture/render views must avoid a second automatic sRGB transfer.

Profile7 uses a separate256-byte constant buffer2. The layout is documented
in `Source/color_shader.h`. R4GFX computes the coefficients; the fixed NIR
program evaluates sRGB, BT.1886, PQ and HLG, two primary matrices, alpha conventions,
white scaling, a rational luminance shoulder and neutral-axis gamut mapping.
It supports nearest sampling; bilinear encoded samples are not advertised as
linear-light interpolation. The SM86 program is10976 bytes/686 instructions,
uses24 GPRs and has no scratch or stack allocation. Compilation and numerical
host checks do not establish physical GPU execution.

Profile8 uses integer texel fetches instead of hardware normalized filtering.
It discards the six P010 padding bits before reconstructing chroma and applies
the EOTF before optional bilinear RGB interpolation. CBuf1 holds up to three
TIC indices; CBuf3 holds the explicit matrix, phase, coded dimensions and crop.
The unused sampler area in the1280-byte upload packet carries CBuf3. The SM86
program has11056 bytes/691 instructions,32 GPRs and no scratch or stack.
`RENDER_V1` exposes matched shader upload and bounded YUV-list encoding;
canonical BO/VA loans and physical retirement remain with the caller/queue.

Profile9 uses CBuf1 integer texture handles and CBuf3 format/plane/pitch/visible
extent. Texture storage extents remain independent of the visible crop. It
writes block-linear R8 views of an authenticated native NV12 allocation.
The render target handles storage addressing; fragment coordinates name
ordinary samples, and chroma edge replication preserves U/V parity.
SM86/89:624 bytes,24 GPRs,39 instructions; SM75:656 bytes/41 instructions;
SM120:672 bytes/42 instructions. All have no scratch or stack. The previous
private16x16 byte packing produced incorrect pixels on the physical C7B7
encoder despite a completed fence and syntactically valid H.264. Physical
qualification must compare both prepared bytes and independently decoded
pixels; host compilation alone does not establish either result.

`Source/shaders.c`, `Source/color_shader.h`, `Source/yuv_shader.h` and
`Source/encode_shader.h` are the source of truth. Metadata uses explicit JSON fields;
no host C-structure layout is serialized. Compilation fails on spills, local
scratch or call-stack allocation in these bounded profiles. Generated NAK
assembly is diagnostic text, not external `nvdisasm` output.

## Runtime materialization

After a successful reproducible build, run on either host:

```powershell
pwsh -NoProfile -File Repositories/Libraries/R4NV/Tools/Compiler/EmitRuntime.ps1
```

`-CompilerOutputDirectory` optionally selects a different verified output set.
The emitter checks the current recipe inputs and all recorded code, metadata,
NIR and assembly hashes before replacing generated runtime files. It also
validates the nine profiles, target and bounded metadata. Modified headers
are rejected even when the machine-code file itself is unchanged.

The checked-in `Source/Generated/Shaders` files contain only the nine programs,
metadata and provenance. R4NV's separate `SHADER_V1` table exposes a bounded,
driver/GPU/compiler/ABI/format/pipeline-state-bound byte cache. The regular
R4NV build consumes these files without running Mesa or a host compiler.
Native allocations and the asynchronous render queue consume the fixed
profiles. The 0.79.19 texture checkpoint includes CPU/f64 reference images
and a separate f32 method/descriptor model. Real SM86 pixel execution and
full Vulkan pipeline integration remain separate work. The dynamic R4OS
compiler port is now owned by `../../../R4NAK`; see that unit's README and
`Docs/Drivers/GrafikCompiler07934.txt` in the workspace.
