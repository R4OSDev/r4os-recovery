# R4GFX

R4GFX is the userland graphics library. Its runtime module owns render resources,
backend selection, CPU rendering and native render/present submission;
R4DRAW owns shared buffers, queues and presentation. The compiled `Display/`
helpers parse receiver metadata and the Zig bindings expose queue/output helpers.
The Report keeps SCDC and low-rate scrambling separate; malformed extensions
contribute neither flag. Consumers decide link policy from a complete report.
These source helpers compile in their consumers, separately from R4GFX.R4L.

Build this unit with `../Build.sh R4GFX` on Linux or `..\Build.bat R4GFX` on
Windows. Both use the same PS7 build with the existing owner, display and
C/Zig conformance checks. `test` selects those checks explicitly. No guest
or benchmark runs automatically.

## Runtime interfaces

`module.R4MF` is authoritative. Module 0.1.18 exports four independent tables:

| Import | Behavior |
| --- | --- |
| `R4GFX:API_V1:1` | Checked linear layouts and rectangle fill; original table and payloads unchanged. |
| `R4GFX:RENDER_V1:1` | Capability query and ordered, bounded CPU 2D batches. |
| `R4GFX:DEVICE_V1:10` | Caller-owned resources, native allocation, queued copy/render, output swapchains and canonical completion receipts. |
| `R4GFX:COLOR_V1:4` | Explicit RGB/YUV colors, FP16/HDR transforms and native multi-plane YUV/color/grid render jobs. |

Bindings and API documentation are generated from `Contract/LibraryContract.json`.
Use `ApiV1Client.init` or `RenderV1Client.init` with the app start context. The
generated clients check interface identity, revision, size and required slots.
RENDER_V1 reports software rendering. DEVICE_V1 selects a compatible native
backend through the matching optional `R4NV:BACKEND_V1:3:1` or
`R4AMD:BACKEND_V1:1:1` import. Their interface IDs and vendor payloads are
validated separately; missing/incompatible tables preserve software rendering
and copying. Backend IDs are 1=software, 2=NVIDIA, 3=AMD. Native capabilities
come from the selected driver's confirmed operations; loading R4AMD alone
does not enable an accelerated backend.

## Device resources

Allocate `storage_size()` bytes at `device_storage_alignment`, zero the storage
before its first open, and pass the app start context to `device_open`. Serialize
calls for a device. Keep its storage, imported libraries and start context alive
until `device_close` succeeds; never move an open device. Device, resource and job
handles include owner/generation identity. Handles cannot survive freed storage.

There are at most 256 resources and 16 jobs per device. Create system-memory images,
import a canonical BO reference or immutable shared-raster lease, or borrow CPU
storage with an explicit source generation. Images also act as render targets when
`image_target` is set and writable access is allowed. Samplers and operation
pipelines are immutable resources. Retain/release is explicit; a job independently
holds its source and target until its exact receipt is physically retired.

For explicit native offscreen allocation, set `source_create_native` and point
`source_address` to `R4GfxNativeImage` (version1, size32, finite absolute
`deadline_ns`, width/height/format and layout0 linear or1 native tiled).
Leave `image` and `source_generation` zero. A selected native backend is required.
Creation waits on the common request outside frame execution; the returned BO
supplies actual pitch/extent. Closing the app or timing out does not free active
driver work. The driver uses a separate finite RM budget; native backing is not
CPU mapped. Scanout creation and GPU rendering use their explicit capability-gated paths.

Overlapping leases for the same immutable shared-raster generation reuse one BO
import. No upload or raster conversion occurs. Imported BO descriptors supply their
real geometry; borrowed CPU storage remains the caller's responsibility. `resource_info`
reports source kind/generation and canonical BO identity. Device counters distinguish
imports/imported bytes, successful CPU reads/writes and completed native copy bytes.
Upload bytes remain zero in this profile; these are logical costs, not bus measurements.

The kernel publishes a coherent opaque backend profile and exact device/reset binding.
R4NV validates its interface, command ABI, pinned RM release and Copy Engine class.
The generation must still open successfully through the common queue. `device_refresh`
changes the selected backend while preserving system images and immutable source
imports. Device-local imports affected by reset/change become `resource_invalidated`;
render/copy rejects them as stale, while information and release stay available.
The caller recreates those resources from retained sources; old GPU addresses are
never transferred to a new binding.

`render` resolves a whole resource batch through the same software 2D implementation
as RENDER_V1 and maps each distinct BO once. All primitive validation precedes pixel
writes. A failed physical unmap can still return busy after rendering; resources
remain tracked until release succeeds. Result metadata and input/storage ranges must
not alias. Native queue capabilities separately gate copy, render, grid/color lists and
presentation. The synchronous CPU renderer reports the software backend;
queued native work uses the corresponding DEVICE_V1/COLOR_V1 submission calls.

`copy_submit` uses the canonical queue and returns a job, not synthetic completion.
Query/cancel/release preserve its original device/reset generation. An old queue stays
open until its last receipt is released. Cancellation/deadline alone never frees active
GPU resources. Close is retryable (`status_busy`); continue querying/releasing or retry
close while retaining storage. Opaque device-local images are not CPU shadows.

Output-swapchain close and resize accept an already absent queue after reset,
matching ordinary device-queue retirement. This applies only after all exact
frame jobs have retired; busy queues and active GPU resources remain retained.

The Desktop composes its retained layers and WINSVC window images through
DEVICE_V1/COLOR_V1 and uses the common output swapchain and capture owner.
R4DRAW retains the underlying BOs, queues and driver-owned presentation routes.
DISPLAYD `/BUFFERS` includes two dependent row copies and exact 16-pixel readback through
this interface, in addition to the original RENDER_V1 scene.

## Asynchronous copies

DEVICE_V1 revision 2 appends `copy_submit_ex` and `job_fence` to the original
table. Pass bytes per row, nonzero row count and the two pitches for geometric
copies; zero rows and zero pitches retain linear-byte semantics. Image-plane
pitches must match the canonical descriptor. Offsets are logical plane offsets,
including for opaque native images. Up to eight exact common fences can be
passed as dependencies. Submit the dependent work before releasing its upstream
job. The kernel retains admitted dependencies independently; exporting a fence
does not transfer ownership or complete the job. Query/release only after the
reported physical boundary; cancellation alone does not release resources.

R4NV revision 2 and the common backend operation mask negotiate linear, pitched
and blocklinear CE copies independently of software rendering. Unsupported row
copies between system BOs can use a cached software queue. Opaque/device-local
copies require a compatible native backend and never guess CPU addresses.
Queue device/reset generations and the driver's memory generation are distinct;
native imports must match the current memory epoch and are invalidated on reset.
System resources survive this change. Copy costs count transferred row bytes,
excluding pitch gaps. DISPLAYD /BUFFERS demonstrates two dependent 24-byte copies
with pitches 16/24/32 and a checked readback. Software evidence and physical
follow-up: `Docs/Drivers/GrafikCopy07918.txt` and `ExFiles/Reports/OssiGPU.txt` /18.

## CPU batch ownership

Create/import shared BOs through R4DRAW and hold a write map for each target
and read access for each source until `execute_cpu` returns. Pass these CPU
addresses, pitches and extents as `R4GfxCpuImage`; physical/GPU addresses and
unmapped memory are invalid caller inputs. Input arrays and the batch must
remain immutable, and target access must be exclusive throughout the call.
No pointers, BOs or maps are retained by R4GFX.

The renderer validates every image and command, arithmetic, aliases and total
pixel budget before writing. Rejection leaves image bytes and output stats
unchanged. This is preflight atomicity, not rollback of memory faults or caller
lifetime violations. Pixel storage may not alias metadata or the output.
The caller must also exclude different virtual mappings of the same backing.

Use at most 64 images, 1024 commands and 16,777,216 destination pixels per
call, with an explicit `pixel_budget`. Whole rectangles must be clipped by
the caller; coordinates are unsigned and out-of-image areas are rejected.
Commands execute in array order. Empty rectangles do no pixel work.

| Operation | Inputs and behavior |
| --- | --- |
| Fill | Target rectangle and packed color. Source index, source rectangle, sampler and opacity must be zero. |
| Blit | Source/target rectangles, nearest or bilinear sampler; `opacity=255`, `color=0`. Supports scaling and XRGB/ARGB conversion. |
| Source-over | Same image geometry/samplers as blit; `opacity=0..255`, `color=0`. Premultiplied ARGB or opaque XRGB. |

All reserved fields and batch flags must be zero. R8 supports fill/blit only;
R8/color conversions are unsupported. XRGB reads as opaque and stores its
unused byte as zero. Filtering uses pixel centers and clamps to the source
rectangle. Color-space conversion is a separate stage. Equal-size, same-format
copies of identical views have memmove semantics, including overlapping rows.
Other overlapping source/target spans are rejected.

Capabilities report formats, operations, samplers, features and limits. Errors
distinguish invalid inputs, unsupported operations, overflow, work limits and
unsupported aliases. Unsupported work does not silently discard draws.
`R4GfxCpuStats` reports successful commands, destination pixels and logical
read/write bytes, including filter samples and destination reads for blending.
These counters do not measure memory-bus traffic, GPU time or presentation.

No allocation, upload, frame copy, thread, wait or service call is hidden inside
the renderer. Map release and presentation are separate caller actions.
`Repositories/Diagnostics/DisplayDiag/src/buffers.zig` is the executable client
example, including read leases surviving producer release and balanced teardown.

Native shader rendering and GPU Desktop composition were added in 0.79.19/20.
A passing CPU scene does not qualify NVIDIA hardware. Software evidence lives in
`Docs/Drivers/GrafikRender07917.txt`; physical follow-up remains in
`ExFiles/Reports/OssiGPU.txt`, section 0.79.17.

## Explicit color pipeline

COLOR_V1 adds named color resources, source/output descriptions, ICC profile
arenas and generation, linear FP16 composition and SDR/PQ/HLG conversion.
Native color lists use the existing DEVICE_V1 queue/fence lifetime and
R4NV resource ABI4. Present and swapchains require descriptions matching the
acknowledged output. General ICC/VCGT display profiles currently use the
canonical SDR CPU path; hardware LUT/CTM capabilities remain zero. Display
color changes use the shared timed mode controller and COLORS.R4S schema2.
JPEG/BMP/PNG characterization is supplied by R4IMG. Detailed interface
layouts: [Docs/API.md](Docs/API.md); workspace architecture and evidence:
Docs/Desktop/GrafikFarbe07925.txt and GrafikFarbe07925.json.

Revision3 appends `color_yuv_image_transform` for borrowed linear NV12, P010
and YUV420P planes. Explicit CICP, separate Y/C ranges, all six chroma positions,
odd coded dimensions/crops and independent pitches feed the same tiled RGB
composition/output pipeline. P010 keeps ten meaningful bits through FP16 or
10-bit RGB output. Conventional SDR video uses the BT.1886 display EOTF;
BT.601525/625 primaries and explicit black/white levels are supported. Missing
metadata is rejected for the media owner to resolve explicitly. The function
does not map VRAM or allocate a full-frame RGB intermediate.

Revision4 appends `color_yuv_render_submit` for canonical BO planes. The public
R4NV RENDER_V1 encoder supplies integer NV12/P010/YUV420P sampling and shared
color conversion. Device-owned, bounded BO/VA mappings and coherent command
uploads are reused across frames. Preparation returns BUSY without waiting;
successful submission publishes an ordinary DEVICE_V1 job and its real fence.
Decoder consumers must remain held through preparation and physical job release.
Reset, cache trimming and close retain mappings until retirement acknowledgements.
No native pixels are CPU-mapped. Unsupported layouts/colors remain explicit so
the media owner can choose the CPU path. Hardware pixel/performance acceptance
and the decoder/media presentation integration remain separate follow-ups.


## Variable refresh

The compiled Display helpers provide validated EDID/DisplayID/HDMI-Forum
VRR ranges, mode/source admission, policy, bounded real-frame observations,
per-monitor REFRESH.R4S preferences and the presenter intent lease client.
DEVICE_V1 swapchains remove fixed-phase scheduling only after the common
output API confirms active VRR. Native scheduling still owns actual deadlines
and buffer completion; LFC is not advertised. Workspace architecture and
software evidence: Docs/Desktop/GrafikVRR07926.txt and GrafikVRR07926.json.

Small public resource/import and compositor-output examples are available in
Examples/. Integration, measured software costs and lifecycle guidance:
Docs/Desktop/GrafikIntegration07944.txt in the workspace Docs repository.

## Provider identity (0.80.3)

`Source/providers.zig` negotiates each vendor independently. Effective
capabilities, then the active display adapter, then canonical adapter ID
determine selection. An explicit preferred adapter never borrows another GPU.
Both vendors require the complete current `GfxBackendInfo`, explicit operation
bits and a nonzero memory generation. Short snapshots cannot borrow a device
or queue epoch or assume copy support. Profile changes invalidate
native BOs even when an erroneous producer reuses adapter/generation values.
Pending jobs retain their original backend ID and exact fence until physical
retirement; AMD copies count as GPU traffic without acquiring NVIDIA labels.

AMD image admission (0.80.12) and native render/YUV transport (0.80.14) use
the measured R4AMD architecture and explicit common driver operation bits.
Native YUV submits a bounded description with deduplicated canonical BO/VA
loans; AMDGPU owns ACO upload and PM4 encoding. Plane mappings are cached
until retirement, without CPU pixel maps or per-frame shader compilation.
Since 0.80.19, confirmed AMD Present operations also enable the common
image-present and FIFO swapchain paths. Native XR24 composition images use
AMD-owned UMA storage and SDMA-to-DCN presentation without CPU pixel maps.
The same Desktop, WINSVC and app/subsystem transports remain in use.
Direct scanout and unknown operations receive no AMD capability.
Generic BO descriptors,
queues, fences and budgets remain with their common owners. Opaque modifiers
are passed only to the selected driver, never interpreted as NVIDIA layouts
for an AMD resource. Existing software/Virtio presentation stays independent.

AMD backend properties (0.80.23): the image/render consumers accept the exact
revision/length pairs 1/64 and 2/240 with the unchanged architecture prefix
and zero padding. Truncated or mismatched payloads remain unsupported.


R4GFX0.1.28 (0.80.39) pairs image/native upload admission with the actual
Picasso or Raven2 GC/SDMA and external revision. Existing presentation and
NV12/P010 YUV owner checks cover both families, plus profile replacement
with retained old resources. Public ABI remains unchanged; physical
Raven2 presentation is still awaiting qualification.


Bounded FP16 staging (0.81.23, R4GFX 0.1.30)
------------------------------------------
Complete operations of at most 64 pixels reuse the existing sample scratch
for finite preflight and execution. Every sampled floating source and every
floating OVER target is validated before the first store. Large operations
retain whole-request preflight; no unchecked format or ABI flag was added.
The existing numerical/color check can be selected with
`test "-Dprovider-test-filter=bounded color conversion"`. It now also compares
36 staged/unstaged format/sampler/alpha cases and 12 late NaN/Inf failures,
including target bytes/padding and the reported physical image reads.

Native YUV diagnostics (R4GFX 0.1.31)
-----------------------------------
`R4GFX_YUV_TRACE=1` reports the native owner's failing preparation or
submission stage. It defaults to off, suppresses ordinary `BUSY` retries,
and preserves the original error and resource retirement. A mapping or
encoder diagnostic is not a decoded-frame or rendering completion proof.

Since 0.1.32, this option also reports the exact failed native VA query and
step metadata. R4GFX 0.1.33 waits while the common owner reports a driver
claim without a published result (flags 8/result 0); only the matching
successful create completion admits the mapping. The existing native
NVIDIA/AMD resource check now exercises that real asynchronous state.
