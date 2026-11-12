# R4NV

R4NV owns bounded NVIDIA command encoding and fixed shader artifacts. It never
opens registers or submits GPU work. NVIDIA.R4D owns address spaces, allocation,
channels, completion and resource retirement. Encoding support does not qualify
a physical GPU or imply that its native driver bootstrap is implemented.

Generation2 consumers use the generated clients' `init2` entry and this
library's `Query2` descriptor. Independent interface revisions and command,
shader and cache bytes retain their own identities. This pure provider has
no platform-table, worker, heap or process-inventory dependency to replace.

`BACKEND_V1` revision 3 is a 64-byte table for copy negotiation, linear/pitched
and tiled command encoding, and image layouts. Generated C/Zig bindings check
the interface. Optional consumers can use `IMPORT=R4NV:BACKEND_V1:3:1` and keep
software rendering when the library is unavailable or incompatible.

Module0.1.16 adds the negotiated `feature_copy_graphics_channel`. Set
`R4NvCopy.flags=copy_flag_graphics_channel` only for a GR channel with an
instantiated paired CE: every copy method then uses subchannel4, alongside
GR0 and compute1. Zero flags retain the independent CE subchannel0 stream.
Unknown bits fail without changing outputs. Existing table revisions, slots,
struct layouts and constants stay unchanged; only two constants and explicit
flag semantics are added. The internal independent encoder is unchanged.
The existing provider group checks linear and tiled commands, original-C
operands, header-shaped payloads and rejected flags; C/Zig conformance passes.
This corrects the physical183/DISPLAYD56 XID13 class/subchannel mismatch;
physical R4NV16/DISPLAYD57 now passes five native CE pushes, same-VA A-to-B
remapping and exact separate semaphore/readback checks on GA106. Complete
memory qualification totals265 canonical CE jobs and72241748 exact bytes
with identical settled BO/runtime balance. The prior fault's reset retirement
remains a separate NVIDIA driver defect; other GPU profiles remain unqualified.

Native queue packets use `R4NvNativeSubmitHeader` (32 bytes), followed by exactly
`push_count` `R4NvNativePush` records (16 bytes each). Version 1 admits at most
510 pushes and flags `incomplete`/`no_prefetch`. Engine mask bit1 selects graphics;
bits2/4 additionally request instantiated compute/copy objects. Bit8 alone selects
a separate NVDEC queue; bit16 alone selects NVENC. Neither requires a ready GR template. The first job fixes
the queue's engine family/set; graphics jobs may request subsets. Mixing video
with graphics/compute/copy, changing families, unknown bits, missing classes or
an unpaired copy engine fails before GPU publication. Video queue completion
proves engine drain and memory ordering; the codec must also check its picture
status before exposing output. R4VIDEO owns decoder integration and frame leases;
the media facade connects those leases to R4GFX composition and App-Audio.
The final push must be complete. Every referenced BO/VA, including command
storage, must be retained through the common native resource list. Completion
is a GPU drain and ordered semaphore, not command fetch; Vulkan resource/cache
barriers remain in the stream. These wire types add no R4L slots or revisions;
NVIDIA.R4D decides actual support from its live resources.

`Source/video.zig` (named build path `r4nv_video`) supplies bounded, compiled
H.264 picture/DPB and NVDEC command encoding for C7B0/C9B0. It supports progressive
8-bit 4:2:0 Baseline/Main/High with KBL NV12 surfaces, up to 16 references and
255 slices. It checks buffer extents, 40-bit method addresses and overlapping
allocations; reference and output lifetimes remain with R4VIDEO and the common
BO/VA/fence owners. Its slice collector writes Annex B prefixes, EOS, a final
slice boundary and zero padding. Status decoding requires a successful queue
fence and the exact macroblock count without decoder/slice errors. Every job
must first replace its previous status record with `pendingStatus()`.

The helper adds no R4L slot or external runtime. Original NVIDIA-header vectors
exercise signed picture fields, DPB marking, scaling matrices and status layout
inside the existing R4NV test group. VIDEO_V1's NVIDIA codec integration also
passes modeled replies; GA106 physical decoding and lifetime/pixel checks
are documented in workspace Docs/Drivers/Videodekodierung07940.txt. Provenance:
`Source/nvdec_h264_vectors.json` and `Tests/nvdec_h264_reference.c`.

NVDEC `SET_OBJECT` selects the FIFO software engine (`ENGINE_SW=31`),
and every decoder method uses subchannel4, matching the original NVK state
initializer and Push class mapping. Binding only the class with engine0 is
insufficient for these software methods. The independent header vectors also
check both C7B0/C9B0 bindings; picture/method/status reference bytes are unchanged.
This serializer is embedded by R4VIDEO and does not add an exported R4NV slot.

`Source/encode.zig` (`r4nv_encode`) supplies C7B7/C9B7 H.264 Constrained Baseline
parameter blocks, one-slice CQP IDR/P controls, matching Annex-B SPS/PPS and a
61-word native command stream. The profile is progressive8-bit NV12, one
short-term reference, no reorder and BT.709 limited; headers retain nominal
timing without asserting a fixed cadence for dropped capture frames. Level5.1
picture/rate limits and QP0..51 are checked. Native picture state uses the same
frame-number, POC and QP definitions as the generated parameter sets.

The input layout's `block_height_field` is an explicit NVIDIA wire value.
R4ENC admits the native NV12 descriptor, complete block-linear plane extents
and replicated macroblock padding; manual16x16 byte tiles are not accepted.
Both plane methods name one base, with the UV offset in the picture layout.
Opaque reconstruction has an independent layout. Command checks cover40-bit
addresses, retained plane extents, disjoint ranges and the H.264 app/method
selection. Disabled MEPRED methods are omitted and the CEA address is zero.

Physical C7B7 execution established picture codec0 (method CODEC_TYPE remains3),
macroblock slice mode0 and positive SSD/RDO initialization. Status completion2
with zero microcode error and an exclusive end offset is required after the
exact successful queue fence. The actual independently decoded IDR status is
preserved in `nvenc_status_capture.bin/.json`; it supplements the original-C
layout vectors. No GPU allocation, submission or capability is published by
these pure helpers. Canonical GA106 internal sessions pass independently
decoded static/changing IDR/P sequences. The installed public R4ENC worker
also passes native-input, timestamp and bounded lifecycle cases. Productive
recording and explicit fallback after a controlled physical GPU reset are
qualified in workspace Docs/Drivers/Videoencoding07941.txt. A C9B7 header
vector is not a physical Ada result.

Existing provider tests compare complete picture/control blocks and methods
against the original NVIDIA C types. Independent FFmpeg decoding of two actual
SPS/PPS outputs with test-only I_PCM slices checks exact pixels, cropping,
colorimetry and parsed VUI timing. This is header validation, not NVENC output
or compression-quality evidence. See `Source/nvenc_*_vectors.json`, canonical
`Tests/nvenc_*_reference.c` and GFX/0.79.41/Evidence/NvencParameters.

`Source/copy.zig` is shared by the R4L and the driver's compiled binding:

| Copy class | Encoding scope |
| --- | --- |
| C5B5 | Linear, pitched and blocklinear; packed 16-bit x/y origins. |
| C6B5, C7B5 | Linear, pitched and blocklinear; separate 32-bit x/y origins. |
| C9B5, CAB5 | Linear and pitched; tiled operations require a future explicit kind/BPP contract. |

Command addresses remain 40-bit and copy operands 49-bit. Transfers and their
final system-scope semaphore release use the selected class's PLC control.
Allocation extents, aliasing and every operand are checked before publication.
At most 37 command words are written. Callers provide output storage and retain
GPU resources themselves; a rejected call leaves output and count unchanged.

`SHADER_V1` revision 1 is a separate 56-byte metadata/cache table. The keyed
cache admits exactly C597/SM75, C797/SM86, C997/SM89 or CD97/SM120. Every target
has nine fixed programs with its original NVIDIA header. Class and shader
model must agree with the measured driver profile. The legacy unkeyed metadata
entry continues to describe SM86. See `Docs/API.md` for the unchanged ABI.

A cache binds driver build, device/reset identity, graphics class, compiler,
RM/command/shader/resource ABI, formats and complete pipeline-state digest.
It contains a 384-byte prefix, header and code within the 16384-byte ABI limit.
Loading checks exact metadata, header, code and hash; stale or corrupt entries
return `status_cache_miss`. No GPU address is cached. Reset requires fresh
resident resources, regardless of a CPU cache hit.

The [host compiler](Tools/Compiler/README.md) builds pinned Mesa 26.2.2 NIR/NAK.
`-ShaderModel 75|86|89|120` selects one target (default 86). Reproducible outputs
include machine code, header, NIR and assembly. `EmitRuntime.ps1` verifies and
imports those outputs. `Tools/RenderState/Generate.ps1` derives class-specific
state from the pinned original headers. Normal module builds embed the checked
files and do not run or download a compiler. Complete upstream notices remain
with source/generated files and the host tool's Legal directory.

Build with `../Build.sh R4NV` or `..\Build.bat R4NV`. The existing `test` step
covers C/Zig conformance, commands, target separation, byte caches and rejection.
The driver tests retain independent original-header fixtures. The C7B5 release
fixture correction and all four compiler/state profiles are recorded under
`ExFiles/Reference/GFX/0.79.33`.
Physical qualification follows `ExFiles/Reports/OssiGPU.txt`; native Windows
compiler execution and runtime compiler integration remain in 0.79.34.

Version 0.1.12 encodes SET_BLEND_PER_FORMAT_ENABLE with its original bit-4
field through DRF_DEF. The previous unshifted enum set reserved bit 0.
All four generated class tables and the existing command-stream regression
cover the correction. OssiPC169 passed the small CE pixel test but failed
the subsequent GR command; physical qualification of this fix remains open.

Version 0.1.13 removes the additional SET_ANTI_ALIAS_RASTER override rejected
by GA106. Sample layout still uses SET_ANTI_ALIAS, matching the pinned NVK
path. All four generated tables and the existing emitted-stream regression
cover this change. Hardware170 repeated the CE pixel result and progressed
past the fixed blend flag; GR execution of the new recipe remains pending.

Version 0.1.14 removes SET_SAMPLE_MASK0xfa4 rejected by GA106. The four
regular sample masks remain0xffff, matching the pinned NVK path. The
existing four-class emitted-stream case covers both omission and masks.
Hardware171 repeated512 exact CE pixels; GR with this recipe is pending.

Version 0.1.15 sets the previously missing surface clip to the complete
target extent, independently of viewport and scissor, matching pinned NVK.
Shader binding emits only address A/B on C597; C797 and newer additionally
receive bounded prefetch blocks covering the header and code, capped at127.
The existing four-class command checks reproduce both prior errors and pass
with the corrected stream. Shader bytes and external ABI are unchanged.
Hardware172/R4NV14 completed CE and GR receipts but left all512 pixels
unchanged. Hardware173/R4NV15 passes both512-pixel CE and GR rounds on GA106;153 filled
and359 preserved pixels are exact each round. Resource balance and driver
shutdown remain open. This does not qualify another GPU generation.
