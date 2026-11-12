# R4ENC

In 0.90.48, the public runtime admits real generation2 application records
through the shared Native caller snapshot, system and synchronization owners.
The snapshot stays in process-owned storage; graphics contexts use its actual
table generation and checked function prefixes. ENCODE_V1:1 and codec sources
remain independent of the platform Query2:2 binding. Explicit legacy startup
remains available during the staged consumer migration. Packet acceptance
does not acknowledge physical encoding hardware or file persistence.

Native NVIDIA work in 0.82.31 corrects the picture controls, completion
semantics and GR-to-NVENC surface handoff. SET_OBJECT selects the original
NVC56F software engine. The GR preparer awaits each exact asynchronous
input-VA retirement within the job deadline; pending unmaps neither fail a
completed preparation nor resubmit it. The pure R4NV encode helper and GR
preparer are compiled into R4ENC. The installed public ENCODE_V1 worker also
passes the bounded native-input sequence and lifecycle cases below. The
productive Desktop recorder also passes real NVENC, files and explicit
software fallback after a controlled physical GPU reset.

Independent encoder library introduced in 0.79.41. The generated
`ENCODE_V1:1` contract separates canonical input BOs/fences, stream timestamps,
explicit codec/rate capabilities, bounded queues and immutable bitstream
leases. It does not reuse the R4VIDEO decoder API.

Implemented software path:

- C/Zig contract and canonical graphics identity checks.
- BO admission with deduplicated imports, finite retained-memory accounting,
  borrowed producer fences, CPU I420/NV12 views and retryable cleanup.
- Queue/control bookkeeping with backpressure, exact lease identities, ordered
  completion, IDR after Abort and Close escalation over pending Drain/Abort.
- Pinned OpenH264 2.6.0 freestanding C++/x86 assembly build; CQP H.264
  Constrained Baseline 8-bit 4:2:0, IDR/P, checked Annex-B access units.
- Loadable R4ENC.R4L with all nine public calls, R4SYS memory/clock/TLS adapters
  and one bounded worker per encoder, charged through its exact join.

The public software runtime passed a short SMP4 guest run with real BOs,
I420/NV12 inputs, bounded backlog, held output leases, Abort/IDR, Close and
exact worker joins. Independent FFmpeg decoding verified two twelve-frame
320x192 sequences at QP18/QP36. This is not a throughput or NVENC proof.
The private NVENC session now owns bounded work/bitstream BOs, two opaque
reconstructed references, IDR/P sequencing and fresh status validation.
It uses Shared/Native/gpu_resources.zig, including exact physical retirement
after timeout. Its Ampere/Ada SDK-dispatch model passes within the existing
second component case; no input pixels or actual codec execution are modeled.
The internal encodePrepared boundary requires a fully padded, authenticated
native NV12 BO owned by the exact session. Its descriptor supplies the shared
plane base, relative UV offset, stride and block height. Opaque reconstructed
references use a separate fixed layout and remain private to NVENC.
The public NVIDIA path now selects matching Ampere/Ada NVENC and GR classes
and uses this session through its existing bounded worker. It starts GPU work
only for accepted input, applies one deadline to preparation/encoding and
retires both engines before input/close acknowledgements. Abort resets the
reference chain. Explicit NVIDIA requests never silently select software.

The GR preparer samples retained NV12/I420 directly, including authenticated
block-linear textures, and writes edge-padded native NV12. Only
shader/packet/command/status/bitstream BOs are CPU-mapped; no full-frame
readback or extra intermediate copy is required. Manual16x16 byte tiling is
not the admitted input layout. On GA106/C7B7, all92160 padded Y/UV bytes from
the canonical GR preparer were checked through CE; a subsequent native IDR
decoded independently to the correct318x190 image at QP18 (Y/U/V PSNR
41.67/42.59/42.44dB). The canonical encoder reproduced that bitstream without
private control hooks, with full resource retirement and a normal reboot.
Two eight-frame static/changing sequences also decode correctly, including
actual P-reference consumption, alternating reconstruction buffers, GOP,
forced IDR and reset. Lowest measured PSNR is41.42dB; maximum sample error14.
First encoder calls take346–351ms, following calls11–38ms including broker
work; these bounded runs do not establish sustained throughput.

Installed R4ENC0.1.6/R4NV0.1.17 also passed an eight-frame changing native-input
sequence through the public ENCODE_V1 worker. Independent FFmpeg decoding and
demux confirm pixels, keyframes, variable PTS/DTS and per-frame durations,
BT.709 limited and sRGB transfer13. The append-only Matroska clip spans832ms
by packet PTS plus BlockDuration; it has no backpatched Info.Duration.
A held output lease for500ms kept queue/memory bounded and packet bytes stable;
Drain/EOS, Abort/IDR, held Close, exact worker join, all20 resource counters and
a normal reboot passed. Send-to-receive latency was1.60s on first startup and
111–115ms thereafter, including worker scheduling and caller polling. This
caller fills a bounded memory sink then writes the completed file.

The unchanged Desktop0.1.102 recording owner is separately qualified with a
controlled CPU capture publisher and actual NVENC/file streams:24 decoded
pictures across four parts, source/size changes, stop/restart and static tail.
Injected800ms file delay/error cases retain no capture leases while waiting;
all BO/capture counters, encoder joins and no-consumer idle recover exactly.
With encoder and final packet held across a controlled physical FLR, the
recorder preserves its native part and opens software only after exact native
retirement. Both parts decode independently (four native/six software frames).
This does not qualify spontaneous faults, active display or sustained capture.
Current shared evidence and scope: Docs/Drivers/Videoencoding07941.txt.

Native configuration is
CQP,8-bit BT.709 limited, transfer1 or sRGB13, default/left chroma, GOP<=65535; unsupported metadata,
layouts, generations or missing channels return explicit errors. Capability
queries describe this software profile, not a completed physical qualification.
The compiled recording_mux helper writes bounded append-only Matroska/H.264
with explicit packet durations. Twelve real encoder packets preserve variable
PTS/durations and decoded pixels through independent demux. The companion
recording_pixels helper converts immutable CPU sRGB snapshots to limited NV12
with left chroma and explicit transfer13; it has no resource or thread owner.
Desktop's Ctrl+Print Screen recorder owns activation, latest-frame selection,
explicit fallback, file rotation and the worker. Its SMP4 consumer run decoded
62 pictures independently and checked delayed/failed writes, modeled NVIDIA
loss, repeated recording, exact joins and restored BO/capture baselines.
The bounded sequence evidence does not qualify sustained capture or other hardware.
CBR/VBR constants define requests; they do not imply backend support.

Build the module from Libraries with `./Build.sh R4ENC -Doffline=true` (or
`Build.bat R4ENC -Doffline=true`). Source archives must already be cached for
offline builds. From Libraries, use `./Build.sh R4ENC test` or `Build.bat R4ENC test` for the two
short component cases. The ownership case also exercises BO cleanup and flow
control with modeled kernel replies. No new workspace gate is added.

`Tools/BuildNative.ps1` uses PowerShell 7, clang 19.1.7, NASM >=2.16 and the bundled
Zig math sources. `-Offline` requires the checksum-pinned archive. Both host
paths share the script; execution has so far been checked on Linux only.
OpenH264's global thread pool is unavailable; the caller-owned R4OS worker runs
a single-thread codec with actual CPU SIMD dispatch. C++ is closed to exceptions
and RTTI; `-fcheck-new` preserves the codec's null-allocation checks.

Source pins/license: `ThirdParty/Sources.json`, `ThirdParty/OpenH264-LICENSE.txt`.
Workspace findings and proof limits: `Docs/Drivers/Videoencoding07941.txt`.
Physical follow-up: `ExFiles/Reports/OssiGPU.txt`, section 0.79.41.

## AMD provider foundation (0.80.28)

ENCODE_V1 preserves existing slots and appends AMD backend ID 2 and common
codec/profile constants. Canonical AMD native resources support an encode
IB, coherent status/command BOs and exact fence/retirement ownership. Profile
eligibility includes only VCN1 H.264/HEVC 8-bit; HEVC Main10, AV1 and unproven
B-frame operation are excluded. The 0.80.31 implementation below resolves this foundation through the
actual driver and its implemented session/rate-control profile.
The NVIDIA path requires its own provider identity. Physical codec output
and rate/quality tests belong to /39; AMDVCN08028 documents current evidence.

## AMD VCN1 encoder (0.80.31)

R4ENC 0.1.3 implements native H.264 Baseline/Main/High and HEVC Main8 via
ENCODE_V1 backend2. It reuses the existing worker, queues, timestamps,
immutable output leases, Abort/Drain/Close and budget ownership. Both native
providers remain explicit; the software and NVIDIA profiles retain their
previous behavior.

Pinned Mesa 26.2.2 VCN1 session, header, slice-template and rate-control
functions are extracted without changes by R4AMD/Tools/VcnEncode.ps1 and
compiled into R4ENC. The bounded adapter owns two reconstructed surfaces,
one previous reference and IDR/P sequencing. Firmware0x0310f005 selects
session ABI1.9 and the extended per-picture controls. A fresh feedback
record and retired native fence are both required before returning bytes.
Timeouts retain input/session storage through retirement; Close requires
its firmware command acknowledgement or a changed device epoch after the
old queue has retired. Only commands, feedback and compressed bytes are
mapped on the CPU. Source pixels remain native borrowed NV12 BOs.

Configuration: even dimensions128x128..4096x2304 for AVC, width>=130 for
HEVC; level5.2/6.2 and their sample-rate bounds, <=240fps, GOP1..65535,
CQP/CBR/peak-constrained VBR, QP0..51, rate-controlled peak<=200Mbps.
Color is BT.709 limited, transfer1 or13, default/left chroma. One contiguous
linear NV12 BO uses 256-byte-aligned pitch, explicit plane offset, padded
16-row AVC or64-row HEVC coded extent and sufficient initialized storage.
Separate planes, tiled input, B pictures, Main10 encoding and AV1 are not
implemented. Packet capacity is8192..8MB including up to1024 header bytes.

Existing host cases cover GOP/reset, rate controls, fresh/invalid feedback,
no input CPU mapping and late init/frame/close acknowledgements. A short
SMP4 guest ran the actual R4L/ENCODE_V1 worker through13 sessions and73
inputs, held-packet Drain, Abort/IDR, Close and exact worker joins. GPU
completion and VCL data are modeled. Independent FFmpeg checks parse36
production SPS/PPS/VPS vectors,24 reconstructed IDR/P slice headers and
decode small software reference clips;
the latter exercise Annex-B admission, not AMD output quality. Real VCN
bitstreams, rates and laptop performance remain reserved for0.80.39.
Provenance and limits: Docs/Drivers/AMDEncoding08031.txt/.json.

The shared native owner (0.82.31) accepts an already retired empty queue
after a GPU reset. Its exact outstanding fence must first acknowledge physical
resource release; a stale fence or any other queue error still keeps cleanup
pending. Encoder BOs and accounting close independently afterward. Existing
owner cases cover this distinction. Physical GA106 output and the productive
Desktop recorder, including retained-encoder reset/fallback, are qualified
in0.82.31. Scope and shared evidence: Docs/Drivers/Videoencoding07941.txt.

The compiled `recording_pixels.Layout.initAmd` helper (0.80.32) retains visible
dimensions and supplies 256-byte pitch, 16-row AVC coded extent, and neutral
luma/chroma padding. The final row chunk initializes bottom padding. The
generic helper retains its existing layout. Host ownership checks also cover
130x130 canonical system input after producer CPU unmap for both AMD codecs.
Desktop0.1.74 selects AMD through QueryCaps/Create and uses this AVC layout;
R4ENC.R4L remains byte-identical0.1.3. Hardware pixel qualification remains39.

## Raven2 device selection (0.80.39)

R4ENC0.1.4 uses the shared GPU resource owner with paired Picasso or
Raven2 GC/SDMA identity and exact external-revision ranges. VCN capability
queries retain the selected1.0.0/1.0.1 class; readiness, generation and queue
ownership still come from the actual driver receipt. Host owner checks cover
Raven2 and reject mixed profiles; codec/pixel hardware qualification is open.
