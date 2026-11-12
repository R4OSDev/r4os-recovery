# R4VIDEO

In 0.90.48, the public runtime admits real generation2 application records
through the shared Native caller snapshot, system and synchronization owners.
The snapshot stays in process-owned storage; graphics contexts use its actual
table generation and checked function prefixes. VIDEO_V1:1 and codec sources
remain independent of the platform Query2:2 binding. Explicit legacy startup
remains available during the staged consumer migration. Neither accepted
packets nor returned software frames acknowledge physical presentation.

Independent compressed-video library and compiled media-host facade for roadmap 0.79.40.
VIDEO_V1 covers bounded input, decoded BO-plane leases, timestamps, reorder,
Drain/Flush/Close and explicit backend selection. `zig build test` combines
C/Zig ABI, canonical graphics identities and concurrent allocation budgets.

`Tools/BuildNative.ps1` builds pinned FFmpeg 9.0.1 for freestanding x86_64 with
PowerShell 7, clang 19.1.7, NASM >= 2.16 and bundled Zig. It generates immutable
CAVLC/H.274/MPEG2/MSMPEG4/IntraX8/VC1 tables with the original upstream initializers and uses FFmpeg's
constant CRC tables. Linux execution and Windows cross-compilation of these
generators were checked; the complete PowerShell build was run on Linux.
`-Offline` requires the checksum-verified archive. See ThirdParty/Sources.json.

The shared native owner (0.82.31) treats an already removed empty queue as
closed after its own exact fence has acknowledged physical resource release.
An unknown outstanding fence remains an error; other close failures retain
the queue. Existing resource cases also cover these GPU-reset cleanup paths.
Installed0.1.11 on GA106/NVIDIA222 also passes the existing36-frame native
Baseline/Main/High probe: retained frames through Flush/Close, exact decoder
and runtime joins and unchanged public resource counters. This reuses the
original lifetime probe; pixel/output qualification retains its0.82.30 scope.

The archive has 277 objects (264 upstream, six adapters, seven shared C
helpers), plus separately built shared Math/Scan archives. SIMD dispatch uses
actual CPUID/XCR0; AVX512 remains masked under the current SDK contract.
Native process settings, bounded allocation ownership, worker admission/join,
TLS cleanup and real R4SYS clocks are implemented and link with the codec.
The public R4VIDEO.R4L now executes all nine VIDEO_V1 slots in a four-vCPU
R4OS guest. It is built with `../Build.sh R4VIDEO -Doffline=true` (or the Windows
Build.bat starter). `IMAGE_SCOPE=slim` includes the module in normal profiles.

The private worker bridge admits progressive H.264 8-bit 4:2:0 Baseline/Main/
High, one slice group, up to level 5.1 and caller dimension limits. Buildhost
probes check 36 exact YUV frames, reorder/timestamps, held frames over Flush/
Close, errors and modeled calling-process settings. The SMP4 native guest
repeats the frame/lifetime/error checks with real threads and budgets. Its
surface probe verifies all three YUV planes in common R8 BOs, partial-allocation
cleanup and final BO/reference/map/byte baselines. The public guest additionally
checks copied input/backpressure, leases across Flush/Close, common consumer
fences, stale tokens, failed admission retries and independent decoder errors.
PublicPoolGuest additionally checks stable BO identities, initialized padding
and 64x48 -> 96x64 -> 64x48 with a held old-size image (39 reference frames in
total). Evidence is under ExFiles/Reference/GFX/0.79.40/Evidence; PublicApiGuest,
NativeGuest and NativeSurfaceGuest retain earlier checks.

Memory limits charge payloads, allocation metadata/alignment, decoder surfaces
and retained worker stack reservations. Shared code, fixed process/TLS records,
backing allocator caches and kernel bookkeeping are outside that accounting;
these limits do not promise a total physical-RAM ceiling. Allocation exhaustion
returns failure and failed realloc preserves data. Join failure cannot return
into FFmpeg teardown while a worker might remain alive.

Source/surface.zig owns software YUV output storage, queried BO descriptors
and transient mappings. A failed upload retains partial resources until close
succeeds. It copies Y/U/V without RGB conversion. Source/engine.zig owns bounded
packet/output queues, stream generations and leases. Reuse starts after the
exact consumer fence retires and Release acknowledges the return. Fitting BOs
keep their identity and budget charge; Flush/Close/error close unused cached
storage. Dimension changes replace the affected slot's old layout without
revoking other held images. Padding is initialized separately from active rows,
avoiding a redundant clear of every pixel before copying it.

FFmpeg's max_pixels guard uses its own STRIDE_ALIGN-rounded width; actual
SPS/get_buffer2 dimensions still obey the exact caller limits. This permits
valid widths such as96 pixels without confusing SIMD stride with coded size.

Runtime admission permits 1..16 decoder owners. Its thread_limit caps aggregate
decoder workers, including their coordinators; one fixed retirement worker is
additional and its stack/allocation remains memory-budgeted. Config.threads caps
each decoder at 1..16 workers (zero chooses min(runtime limit,16)); caps <=2 use
one coordinator and synchronous FFmpeg, higher caps allow up to cap-1 codec
threads. Close completion includes exact joins, then Destroy frees the owner.
Finish permanently closes the process-local runtime. Fixed tombstone metadata,
including its owner mutex, follows process lifetime for safe stale/idempotent calls.

H.264 profile zero resolves to Baseline; Main/High require explicit selection.
The H.264 path admits progressive 8-bit 4:2:0. Unsupported codecs/profiles/devices
return UNSUPPORTED without implicit substitution;
a media owner can explicitly open the software backend. Errors from asynchronous
FFmpeg admission wake the coordinator even if no further packet arrives.

R4GFX now provides CPU and native YUV composition through COLOR_V1:4.
The compiled media host and corresponding-source staging are described below. CUDA/NVDECODE are not dependencies. Source pins stay in
ThirdParty/Sources.json; implementation status belongs in this README.

`Port/FFmpegNvdec.patch` registers a private hardware pixel format and H.264
callback implementation. `Port/nvdec.c` maps parsed SPS/PPS, raster scaling
matrices, short/long references and original escaped slice NALs to the private
`nvdec.h` worker interface. FFmpeg retains parsing and display-order output;
the worker callbacks own GPU work. The hardware path uses a single coordinator
and never selects software implicitly after a callback failure.

Each opaque hardware image has an AVBuffer reference. The callback table is
copied at open and into each image; its external owner must outlive every
received frame, including held frames after codec_close. Partial allocation,
begin/slice/end errors abort once and release once. Only successful end marks
an image available; the GPU implementation must check its native fence AND
NVDEC picture status before returning success. CPU data planes are absent.

The SMP4 NvdecBridge fixture runs the real native FFmpeg callbacks through
R4NV's picture/slice encoder, with a model replacing GPU image ownership. It
checks 36 metadata/reorder frames, held references over Flush/Close, copied
callback tables, four failure stages and exact budget teardown. The same
changed R4VIDEO module also passes the existing 39-frame public software
probe. This is not GPU decode evidence. Evidence: GFX/0.79.40/Evidence/NvdecBridge.

../Shared/Native/gpu_resources.zig owns native NV12 allocations, coherent system
uploads/status, VRAM scratch, acknowledged GPU VA bindings and engine-8 queue
submissions. Architecture/epoch admission covers GA10x (C7B0) and Ada (C9B0);
the driver separately validates an offered NVDEC instance/class. No GR template
is required. All method addresses must fit 40 bits; an out-of-range RM allocation
is retired and rejected. Image layouts come from actual BO descriptors, including
the uncompressed blocklinear modifier and aligned chroma offset. GPU memory and
system upload allocations remain charged through their exact retirement ACK.

Source/gpu_decoder.zig connects these resources to the real FFmpeg callbacks and
R4NV's H.264 encoder. Seventeen coloc slots track DPB membership independently
of up to 48 image owners. Reordered references preserve their physical slot;
an output held by a consumer keeps its BO while its old coloc slot is reused.
Each job retains all indirect BO/VA resources, resets the picture status and
checks the coherent result after queue completion. Missing/error status produces
no frame. A partial allocation or timed-out job remains reachable for cleanup.

Caller-local `R4VIDEO_NVDEC_TRACE=1` enables bounded diagnostics before submit,
after engine/resource completion and on submit/status errors. The trace includes
the fresh status bytes, class/profile/slot/reference identities and original
command/picture payloads. It is disabled by default; it changes neither the
submitted commands nor the error/completion predicate. Missing diagnostic
access remains silent and never supplies a completion receipt. The first
physical 0.82.30 decode produced RC20 and no frame; its automatically recovered
failure remains recorded in OssiGPU.txt pending native decode/pixel validation.

Additional `R4VIDEO_NVDEC_STEP=1` isolates the original method words into eight
groups with full native queue/resource retirement between them. This diagnostic
is disabled by default and is not the regular decode qualification. Every group
retains all indirect BO/VA owners; only EXECUTE can decode, and the same mandatory
fresh codec status still gates output. Unavailable trace snapshots are marked
with question marks rather than concealing the original submit error.

VIDEO_V1 now admits that NVIDIA path and publishes two NV12 planes borrowing
the same canonical BO, with normal timestamps, crop and color metadata. The
coordinator retains the received AVFrame through the consumer fence AND public
Release acknowledgement. Flush/Close do not revoke held images. Hardware uses
one coordinator; no FFmpeg frame threads or mandatory CPU color conversion.
Storage geometry changes require an empty DPB; held consumer images survive.
At most 36,864 macroblocks are admitted, so not every 4096x4096 combination is
valid. Further codecs, interlace, noncoherent mappings and unknown layouts are
not enabled. Physical decode/pixel validation remains in OssiGPU.txt.

Evidence/GpuOwner records the focused owner cases (delayed MAP/retirement,
timeouts, budgets, DPB-slot reorder/reuse, held old-size images and missing/bad
picture status). The public SMP4 fixture runs the actual R4VIDEO.R4L, FFmpeg
and GPU owner with modeled GPU replies: 36 Baseline/Main/High metadata/reorder
frames, held images through Flush/Close and delayed Release acknowledgement,
plus a rejected picture status and complete teardown. The same module passes
the existing 39 exact software frames. No GPU pixel or performance claim is
made; no additional permanent test group was added.

## Media host

`Bindings/Zig/playback.zig` is an optional compiled consumer facade, exported
as the package path `r4video_playback`; import `r4os` and `r4gfx_binding` into
that module. It uses actual VIDEO_V1, R4GFX COLOR_V1:4 / DEVICE_V1:10 and the
ordinary App-Audio/AUDSVC path. It is independent of any particular player UI.
The caller retains demux, audio decoding, file I/O/seek and desktop presentation.

Open the VIDEO runtime and graphics device outside paint callbacks, then
`Session.init` with explicit codec/color/budget settings and optional PCM owner.
Call `send` with complete access units and the current stream generation;
AGAIN/BUSY accepts no input. Feed bounded S16LE PCM with its sample-derived PTS
and audio epoch. Pump `step` from the event loop, using `pendingFrame` metadata
to choose the current crop/viewport and an available CPU or GPU output target.
Only `target_accepted` borrows that target. Each returned `Output` ends its
composition use; present it through the existing desktop/swapchain host only
when `display` is true. The caller owns the output storage and its subsequent
presentation lifetime. Three independent slots permit old/new-size overlap.

Sources use canonical BOs. Native composition retains frame loans throughout
BUSY preparation, GPU completion and physical job retirement. The R4GFX job
owns its fence; VIDEO receives an empty receipt only after that job is released.
CPU composition permits explicit system-linear maps only and retains partial
maps until unmap succeeds. Unknown modifiers never become implicit CPU reads.
ColorPolicy supplies explicit defaults for unspecified metadata and luminance;
unsupported signaled values remain errors. COLOR opacity is0..65535 on both
CPU and GPU, with full precision retained by native float vertex attributes.

One monotonic, pause-corrected clock schedules video and PCM; decode speed and
audio acceptance do not change it. App-Audio currently has no audible sample
cursor. The audio owner uses a10ms staging/lead bound and one service call per
step (SDK `AudioStream.writeOnce`); partial replies preserve their exact prefix.
Late audio/video is trimmed or dropped, never accelerated to catch up. Audio
absence/failure is reported as degraded while video time continues unchanged.
An uncertain timed-out write closes its stream instead of replaying samples.
Actual device latency and long-term A/V drift still require physical measurement.

`seek` and `pause` flush the decoder and close/discard queued audio. While the
seek handshake is pending, old outputs are retired without display and no new
packets enter. On `Step.reposition_ns`, seek the source to a preceding random-
access point and call `repositioned`; decoded preroll is skipped on the media
timeline. `resumePlaying` restarts the paused clock. PCM after seek uses the new
audio epoch. New stream dimensions/color are obtained from `pendingFrame`;
old composition targets remain held independently until returned.

Drain preserves reordered output. Close keeps pumping until all compositions,
VIDEO release acknowledgements, decoder destruction and audio close complete.
A definitively invalidated service connection ends the local audio close;
BUSY and uncertain replies keep it pending. Service death cannot hold the
session in an endless close loop.
Only then may the caller finish the VIDEO runtime, close the graphics device
and unload providers. A deadline reports failure but never frees live GPU data.
Unsupported NVIDIA admission may select the explicitly allowed software backend;
an asynchronous decoder/device failure requires closing this session and opening
a new software session at a source random-access point. No packet is silently
retried in another backend. A failed old device and its owners remain loaded
until their physical cleanup completes.

Existing owner cases cover clocks, partial audio responses, seek/close replies,
CPU map retention, native BUSY, separate GPU retirement and decoder errors. SMP4
executes the actual public modules:12 complete baseline frames and8 post-seek
frames (half opacity), plus one96x64 frame, all compared pixelwise to a scalar
BT.709/BT.1886 FP16 reference. First probe failures were its incorrect generic
success code and its three-frame expectation for a one-frame resize fixture.
This proves software integration, not native GPU pixels or audible A/V sync.

## Distribution and rebuilding

Every normal image and graphics video update contains
`R4OS/SOURCES/R4VIDEO/SOURCE.TGZ` (gzip-compressed tar) and its JSON SHA256
`MANIFEST` alongside the replaceable library. Older long filenames can remain
as historical sources; the current pair uses short leaves for atomic first
installation through SYSUPD. `Tools/PackageSources.ps1`
packages the matching module identity, original FFmpeg archive, all port patches
and R4VIDEO/SDK/contract/native-helper sources needed for a complete rebuild.
Full distribution terms and replacement steps are in `R4VIDEO-NOTICES.txt`;
FFmpeg retains LGPL-2.1-or-later. Consumers dynamically import this R4L.

On a Windows or Linux host, extract the package and provide PowerShell7,
clang19.1.7, NASM>=2.16, git, tar and a complete Zig0.16.0 installation under
`<DevKit>/Toolchains/Zig`. Run the packaged
`Repositories/Libraries/R4VIDEO/Tools/RebuildSources.ps1 -DevKitDirectory <DevKit>`
with PowerShell. The supplied FFmpeg archive allows an offline source rebuild
and relink. Replace `C:\R4OS\LIBS\R4VIDEO.R4L` after consumers stop or on reboot;
no signature or modification lock prevents using a compatible rebuilt module.

## AMD VCN1 H.264 (0.80.29)

R4VIDEO 0.1.4 admits explicit AMD backend 2 for progressive H.264 Baseline,
Main and High, 8-bit 4:2:0, one slice group, up to level 5.1, coded dimensions
64..4096, at most 36,864 macroblocks per picture. Admission intersects the actual Picasso/VCN1 driver epoch and
firmware-ready facts with R4AMD's source limits. The additional AMD codecs
implemented in 0.80.30 are described below. Software fallback
requires the caller's explicit playback policy before backend selection.

`Source/amd_decoder.zig` consumes the same real FFmpeg parser callbacks as
NVIDIA. The private callback names retain their historical `nvdec` spelling;
AMD emits only VCN1 firmware commands. R4AMD's compiled `vcn_decode.zig`
encodes the tier-0 external session, contiguous internal DPB, scaling table,
Annex-B slices and native linear NV12 target. Its 17 DPB slots are separate
from public image leases. Each decode requires a fresh matching feedback
number, zero firmware status/error bits and acknowledged native resources.
A missing, old or erroneous record never becomes a successful image.

Seek/Flush removes reference membership; held output BOs survive session
resize and Close until their public release/consumer fence is acknowledged.
The common player keeps pause, monotonic/media clocks, bounded audio writes,
service-loss policy and R4GFX YUV presentation. No CPU pixel mapping is used
by the AMD decoder. Resource pressure is bounded by the existing budgets and
32 native bindings; no unconditional allocation/performance claim is made.

Original Mesa C profile vectors and focused owner/parser/VIDEO_V1 SMP4
checks are recorded in Docs/Drivers/AMDH26408029.txt/.json. The guest models
VCN feedback; it does not decode or qualify AMD pixels. Physical firmware,
feedback values, image quality, audio and laptop qualification are /39.
The corresponding source package includes R4AMD and this entire port.

## Additional AMD codecs (0.80.30)

R4VIDEO 0.1.5 adds progressive 4:2:0 HEVC Main/Main10, VP9 profiles 0/2,
MPEG2 Main/Simple, VC1 Advanced and baseline JPEG. Eight-bit output is native
NV12, ten-bit output is P010. Coded dimensions are even, 64..4096 per axis
(VP9: 16..4096), subject to caller memory and binding capacity. HEVC admits
levels through 186, VP9 through 62 and VC1 through 4. MPEG2 level codes are
not ordered numerically; max_level is zero instead of a misleading maximum.
AV1, MPEG4 Part 2, VC1 Simple/Main, interlace, other chroma formats, HEVC
range/SCC extensions and progressive/lossless/multiscan JPEG are unsupported.
The software and NVIDIA paths keep their existing H.264 limits.

`Port/vcn.c` translates real FFmpeg metadata and retained reference images
to pinned Mesa codec structures. `R4AMD/Port/vcn_codecs.c` compiles the
unchanged upstream payload builders and VP9 probability defaults. HEVC uses
tier-0 internal DPB/context, VP9 a tier-1 linear NV12/P010 DPB, MPEG2/VC1
the firmware-managed tier-0 picture slots. Decode results require fresh
firmware feedback plus native retirement. VC1 Advanced sequence/entry headers
must precede the first frame in the first access unit; opening is deferred
until those bounded headers are present.

JPEG consumes one complete baseline SOI..EOI image per packet, at most 8 MB.
FFmpeg's post-SOI callback buffer is reconstructed without duplicating scans.
The worker explicitly unmaps its command CPU write lease before the driver
reads/copies that IB into VMID0; re-mapping waits for acknowledged retirement.
AMDGPU serializes JPEG against decode/encode through resource retirement,
following the VCN1 workaround. JPEG has no VCN decode-message feedback;
its native fence/error IRQ is the completion source. Capability admission
requires the driver's separate JPEG submit bit, not just VCN ring readiness.

The optional `R4IMG.NativeJpeg.Consumer(video)` facade owns this bounded
VIDEO_V1 image/lease lifecycle while callers retain ICC/Exif characterization
and explicit R4GFX color policy. It does not map GPU pixels or change R4IMG's
loaded API. Existing media-host timing/audio/consumer rules remain applicable.

Docs/Drivers/AMDCodecs08030.txt/.json record original-Mesa JPEG command
comparisons, codec storage/reference checks and a public SMP4 integration
probe with 99 parser/output frames over eight profiles plus the R4IMG image
consumer. The probe models GPU replies and proves no physical decoded pixels.
Actual firmware results, pixels, throughput and laptop operation are /39.
All port changes and original sources accompany the replaceable LGPL module.

## Raven2 device selection (0.80.39)

R4VIDEO0.1.6 uses the shared GPU resource owner with paired Picasso or
Raven2 GC/SDMA identity and exact external-revision ranges. VCN capability
queries retain the selected1.0.0/1.0.1 class; readiness, generation and queue
ownership still come from the actual driver receipt. Host owner checks cover
Raven2 and reject mixed profiles; codec/pixel hardware qualification is open.

## Software multislice correction (0.80.39, candidate 0.1.7)

The software H.264 path keeps FFmpeg error-resilience bookkeeping enabled.
Forcing `error_concealment=0` left its per-macroblock table unmaintained and
caused the sequential multislice check to reject valid pictures with
`FF_DECODE_ERROR_DECODE_SLICES`. Hardware callbacks retain zero CPU concealment.
Strict error detection including EXPLODE and rejection of corrupt/error-marked
frames remain enabled. Bounded codec diagnostics preserve the original errors.

The standard build passed all 16 steps and the existing three test groups.
A targeted SMP4 run through public VIDEO_V1 compared 39 actual software frames
across Baseline/Main/High at 64x64 and 96x64: all 248832 YUV samples matched.
A truncated packet was rejected and Close/Destroy/Finish completed; requesting
native AMD without an available backend was also rejected. The temporary probe
imports R4DESK for native stdio diagnostics. These are software results, with
separate sessions for each resolution, not native VCN/resize/seek qualification.
The 13-clip native readback probe remains prepared but unexecuted on Lenovo.
Evidence: Temp/AMD08039/VideoPhysical; this candidate is not installed there.
