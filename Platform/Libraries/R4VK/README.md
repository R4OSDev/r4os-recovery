# R4VK native Vulkan provider

Version45 admits real generation2 callers through `Query2:2` and the
independent `VULKAN_V1:1` interface. Pass runtime version2 with the actual
Start2 address in sys and draw/dev zero. The32-byte bootstrap layout and
interface revision1 stay stable. Each process owns its startup snapshot and
C-facing view; retain its imports and objects through actual destruction.
Runtime version1 remains the explicit legacy path during staged migration.

R4VK builds Mesa 26.2.2 NVK and RADV in one consistent native Vulkan
runtime. Provider-specific constructors, revalidation and destruction select
only admitted NVIDIA/AMD backends. The R4OS winsys owns ordinary BO/VA/map,
queue and fence handles; NVIDIA.R4D and AMDGPU.R4D remain hardware owners.
`IMAGE_SCOPE=slim` installs the module in normal images. Missing backends
produce no device; the firmware-framebuffer renderer remains available.

Version35 bounds the private NVK device's usable virtual-address span to
512 GiB, matching the pinned Nouveau backend. The descriptor-buffer view
cache prepopulates this span with a 12-bit chunk key; passing the hardware's
full 49-bit range reaches its assertion at chunk4096 during device creation.
The VA owner retains the actual backend bounds separately. A valid native
reservation outside the usable span is dropped and reports device-memory
exhaustion; malformed receipts or failed drops still report device loss.
Smaller native ranges are preserved. CPU regressions execute the actual
owner and unchanged cache algorithm, including RGB32 boundary lookups,
transport/retirement failures and cache OOM cleanup. Descriptor/hash/format
interfaces in that regression are CPU fixtures. The exact R4GL19/R4VK35
physical GA106 pbuffer run now completes NVK/Zink initialization and yields
64 green RGBA pixels plus 64 intact guard bytes, byte-identical to Softpipe,
with a basic EGL fence and exact warm BO retirement. R4GL24/R4VK37 now
qualify the full regular GUI cycle and controlled physical loss/rebuild.
R4GL27/R4VK39 also qualify genuinely outstanding EGL fences, asynchronous
server ordering, held-wait deletion and complete resource retirement.
R4GL22/R4VK35
also pass all four original EGLImage case groups on the physical GPU:444
complete RGBA records,7104 pixels, byte-identical to the actual software
reference, with full EGL/runtime retirement and exact warm BO balances.

Version36 adds optional first-failure recording for native queue/point/WSI
diagnosis. `R4VK_NATIVE_FAILURE_FILE` names an explicit caller-owned file.
One bounded record contains the original stage, Vulkan result, native result
or detail and exact queue/point identity. Later teardown errors cannot replace
it. GUI callers otherwise have no console transcript. The disabled path does
not allocate or write; recording failure never changes the operation's result
or establishes GPU completion. At36, physical multi-frame EGL window
qualification remained open. The original22/35 second-frame readback is zero, and a separate
control without readback fails its second swap with EGL_CONTEXT_LOST. The
22/36 first-error file records queue-flush VK_NOT_READY before context loss.

Version37 preserves every native VA/BO execution loan while distinguishing
NVK swapchain ownership. Unacquired or handed-off images retain read loans;
the broker's confirmed exact-image acquisition restores write loans. The
memory owner changes every canonical alias under the residency mutex, and
later aliases inherit the same policy. Ordinary BOs remain conservative
writers. Handoff happens after the GPU checkpoint is submitted and before
the host can publish its consumer loan. Existing submitted jobs keep their
independent original write loans; CPU/read-only conflicts and exact fence
retirement remain enforced by the common owner. Actual old/new memory and
VA source snapshots pass28 CPU integration controls against the unchanged
kernel owner, including ordinary CPU readers, immutable exports, late aliases
and rejected actual writers. The installed22/37 physical run now renders
three consecutive stable frames and1280x720 pixels/capture. The full resize,
restore and occlusion cycle subsequently passes with GL24/37 and exact
warm retirement. The original36 diagnostic failure is retained.

Version38 reserves the exact last native execution point for a signal-only
submission on the same queue and resource epoch. Reserving metadata before
the nonblocking reap preserves the actual WSI fence pins. Assigning that
existing completion avoids a second empty physical job waiting for prior
execution at the serialized publisher; it does not invent GPU completion.
Commands, waits, initial signals, foreign/stale points and released metadata
retain ordinary physical submission. Timeline allocation, assignment and
installation failures retain existing error/device-loss handling. Actual
old/new functions pass21 CPU controls under ASan/UBSan; the exact38 artifact
passes the fresh SMP4 software pixel/compute/guard/cleanup controls and
native no-device rejection. The refreshed physical GL24/VK38 GUI cycle passes with exact warm
retirement. PendingFenceE still returns an already completed first fence
after384 ms inside eglCreateSync. GL27 corrects the separate next-batch
recording order; the actual pending/server/delete and refreshed image
qualification subsequently pass with27/39.

Version39 adds opt-in native submission and completion-wait timing under
R4VK_DEVICE_TRACE. Markers retain the exact queue identity and original
result, emit outside the submit/point owners, and never supply completion.
The same21 CPU owner controls pass for38/39; the complete39 build and fresh
SMP4 qualification pass. Physical F/G timing on GA106 measures about35 us
for native submission and170 us for signal handling. GL25 markers locate
about328 ms in the next command-buffer begin, while the unchanged pending
predicate still fails. These timings establish neither a pending fence nor
server/delete ordering. Physical I with GL27/VK39 separately proves both,
with unchanged shaders/workloads/oracles and full warm retirement. All444
original image records/7104 GPU pixels also match software in physical D.

Version34 adds optional caller-local device-construction diagnostics for
Roadmap0.82.29. `R4VK_DEVICE_TRACE=1` records the exact requested extension
names and feature-chain node types/addresses, followed by common/NVK startup
stages. The CPU-only dump is bounded to256 extensions and256 nodes; it changes
neither Vulkan validation nor GPU/resource order. It is silent by default.
The exact new R4GL19/R4VK34 artifacts pass the fresh SMP4 Softpipe pixel/guard/
fence/cleanup and native no-device rejection run. That guest result does not
exercise NVK's real-device constructor; the physical initialization and pixel
result above uses the subsequent private VA correction in35.

Roadmap 0.82.27 qualifies actual GA106 WSI pixel/depth readbacks, regular
Desktop window/fullscreen/resize/occlusion, source FP16/PQ capture, retained
producer fences beyond Deviceclose, full Desktop restart with surviving GUI,
and real MMU/FLR followed by fresh same-GUI pixels and exact warm retirement.
Headless windows explicitly use an all-zero output and portable system BOs;
the native producer's DeviceExecution fence keeps its actual GPU identity.
Old contract layouts and slots remain unchanged. Active TV/output integration
and manual variants stay in0.82.37/38. Evidence: GrafikVulkan07937.txt/.json
in Docs. Existing failed results and original software/model limits remain.

Roadmap 0.82.26 qualifies physical GA106 graphics/compute, generated commands,
pipeline libraries/binaries, distinct multisample resolves and parallel cache
lifetimes. Version30 replaces generated-QMD CB0 high address bits;31 checks
device loss before compute/graphics cache hits. The unchanged public reset
caller now rejects old cache/binary pipelines and executes imported bytes on
the rebuilt GPU with NVIDIA197's corrected GR bootstrap and exact command RM admission.
All original failed results remain archived. See GrafikVulkan07936.txt/.json;
active output and manual variants remain0.82.37/38.

Roadmap 0.82.25 qualifies the regular public NVIDIA ICD on physical GA106:
headless buffer/image/meta readbacks, coherent RAM and VRAM aliases, independent
logical devices, native queue/ring lifetimes and bounded resource growth.
A single owned-unmapped BDA read interrupts actual compute at the expected
counter; public calls report device loss, old resources retire, and fresh
Vulkan work passes after physical FLR and rebuild. Exact warm BO accounting
returns after the new epoch's first-use cache allocation. Original failed
probes remain preserved. Software missing-ACK/COPY10+ fixtures are identified
separately; no physical CTS, active output or absent-board claim is made.
See `GrafikVulkan07935.txt/.json` in Docs for scope, source reuse and evidence.

AMD 0.80.25 admits the software Vulkan 1.3 profile with actual RADV/NIR/ACO
pipelines, dynamic rendering, synchronization2 and Mesa timeline semaphores
over native binary points. Shared provider-specific WSI operations connect
AMD window surfaces, FIFO/MAILBOX, fullscreen, resize and device loss to the
existing WINSVC/Desktop transport. RADV images import the same canonical BO
with checked linear GFX9 geometry; mutable UNORM/sRGB views and swapchain
aliases retain the original backing without a private full-frame copy.

Revision-3 AMD facts add the validated ATOM/SOC15 timestamp clock, 32 native
root bindings and a 1 GB plus 4 KB backing limit. Unknown board clocks and
legacy receipts retain API 1.0. Public Vulkan limits are 1 GB per allocation
and buffer and 4096 allocations; small public memory objects share disjoint,
padded extents of native root BOs. The SMP4 acceptance maps 4096 allocations
simultaneously and binds/maps/touches a real 1 GB buffer. Driver host checks
cover the corresponding page tables and retained SG metadata. The 2 GB VA
aperture, 32 root bindings and bounded 4 MB recording streams remain finite.

AMD EGL integration in 0.80.26 extends this pool to small private shader,
upload and command allocations. Each submission retains at most 32 native
roots. Closing a pooled BO removes caller ownership but keeps its byte extent
occupied while any submission still holds that root. Completion detaches
retired children under the residency mutex; actual frees run outside the
point mutex. Empty submissions retain their NOP storage by the same rule.
Concurrent final release cannot resurrect a root with a zero reference count.
A queue that cannot establish completion during teardown poisons its winsys;
resident kernel loans continue protecting uncertain physical execution.
This fixes Zink's exhaustion of native bindings without raising driver limits.
See AMDEGL08026.txt/.json for the scoped queue and EGL evidence.

Captured public Picasso queries pass selected unchanged Khronos CTS feature,
limit, format and sample-count predicates. Timestamp query/reset/copy and
unavailable-result handling pass the public runtime probe. Targeted SMP4
runs use real kernel BO/VA/queue/fence ownership and the exact production
archives. Actual Desktop composition, output and capture consume AMD WSI
images; a separate NVK run covers the shared WSI regression. GPU execution
receipts remain modeled: no rendered pixels, computed values or physical
GPU timestamps are inferred. Physical qualification is exclusively 0.80.39.
Source-location debugging, EXT_shader_object and EXT_graphics_pipeline_library
remain disabled; no official Vulkan conformance is claimed.
See AMDRADV08023.txt/.json through AMDRADV08025.txt/.json in Docs/Drivers.
Native generators additionally require glslang 15.2.0.

Roadmap 0.79.38 accepts the software Vulkan 1.3 profile. Captured public
queries for modeled GA106/AD106 backends pass selected unmodified Khronos
CTS feature, limit, format and sample-count predicates through a host replay
adapter. Public timestamp queries/reset/copy and unavailable-result handling
pass a targeted SMP4 run. These are software checks; no physical GPU results
or official conformance are inferred. See `GrafikVulkan07938.txt/.json` in Docs.

Roadmap 0.79.37 software integration is complete. The private canonical-BO import and WSI image
constructor share existing NVK memory/VA owners. The image constructor checks
channel format, geometry, modifier and actual NVK/NIL capabilities, then binds
the same BO to an ordinary VkImage/device-memory pair. Linear images retain
NVK's tiled-shadow handling for mixed rendering. A scoped SMP4 consumer links
the full production NVK/NIL/NAK archives and checks the actual NVIDIA layout
calculator for UNORM8, sRGB, 10-bit and FP16, producer-close, render submission,
callback OOM and cleanup. GPU execution and completion are modeled; pixels and
physical presentation are unverified. Desktop now consumes the common WINSVC
window transport. R4VK provides native window surfaces, standard KHR surface
queries and swapchain/acquire/present through real WINSVC. scRGB/HDR10 windows
use the shared Desktop HDR/SDR and capture policy. Targeted SMP4 integration
connects public Vulkan calls to the actual Desktop Window/compositor owners,
canonical R4GFX output swapchain, real kernel routing and capture. Resize,
modeled output replacement/reset, producer kill, service restart and actual
GUI-shell consumer death preserve generations and release all BO budgets.
R4GFX 0.1.17 fixes output-queue teardown after reset. The guest uses a
controlled shell rather than the complete R4DESK App event loop.
No FD/DRM import or unregistered Vulkan platform extension is advertised.
See `Docs/Drivers/GrafikVulkan07937.txt` and `.json` in the Docs repository.

Native surface entrypoint: include `Bindings/C/r4vk_wsi.h`, enable
`VK_KHR_surface` (optionally `VK_KHR_get_surface_capabilities2`) on the instance,
and obtain `R4VK_WINDOW_SURFACE_ENTRYPOINT` from the R4VK instance-proc loader.
Pass surface-create version1, the exact create-info size, the actual calling
startup address and its Desktop window ID. The opaque application pointer
admits Start2 for new callers and legacy Start1 during migration; the process
retains a stable copied record for the surface lifetime. `VK_NOT_READY` means that Desktop has not
published that GPU window; creation does not wait indefinitely. The resulting
`VkSurfaceKHR` uses ordinary surface support/capability/format/present-mode
queries and `vkDestroySurfaceKHR`. No private Vulkan extension string,
structure type, ICD platform number or R4L table revision is invented.

Surfaces pin the process, Desktop and service generations. Queries take fresh
WINSVC snapshots; resize/DPI changes update the exact extent, hiding preserves
the surface, and service replacement requires explicit recreation. Supported
formats are the intersection of published color contracts and selected native provider's
linear-image capabilities: B8G8R8A8 UNORM/sRGB, with supported opaque or
electrically premultiplied alpha. Image counts, FIFO/MAILBOX and output binding
come from Desktop; image usage and alpha flags must work for all enumerated
formats. With `VK_EXT_swapchain_colorspace` enabled on the instance, exact
published contracts additionally expose R16G16B16A16_SFLOAT/scRGB linear
(1.0 = 80 cd/m2) and A2R10G10B10_UNORM_PACK32/HDR10 ST2084 (BT2020/PQ).
Both admit opaque and premultiplied alpha when published. Legacy 100-nit
FP16 is not relabeled as scRGB. CreateSwapchain checks the advertised pair.
HDR metadata remains disabled; the default content envelope is 10000 cd/m2,
not a claim about panel brightness. Desktop converts absolute window values
into its FP16 working scale and applies the common output tone/gamut mapping
only after composition. SDR UI white follows the confirmed output white.
The existing compositor tests cover absolute 80/1000-nit inputs, SDR/HDR
outputs, capture, warm resource reuse and removal of the HDR source.

Enable `VK_KHR_swapchain` on the device for normal swapchain creation, image
enumeration, acquire and queue presentation. Native allocation selects the
actual pitch/backing; Vulkan and WINSVC import the same canonical BO. Image
alias creation/binding and local device-group presentation use these images.
Acquisition signals the supplied Vulkan semaphore/fence only when WINSVC
returns an available image. Present consumes binary waits through Mesa
submission and lends its actual native completion fence to the compositor.

Enable `VK_KHR_swapchain_mutable_format` for compatible views of one native
window buffer. Creation validates Mesa's format compatibility class and owns
the supplied view-format list. Native images carry MUTABLE_FORMAT and
EXTENDED_USAGE; image aliases preserve the same flags and allowed format set.
A targeted SMP4 run checks UNORM/sRGB views, caller-list lifetime, aliasing,
invalid lists, resize and complete retirement with real WINSVC and modeled
GPU completion. Format-class predicates also pass ASan/UBSan. Evidence:
`ExFiles/Reference/GFX/0.79.39/Evidence/VulkanMutableFormats`. This enables
Zink window integration; it does not qualify native GL presentation or pixels.

The private `r4vkDrainWindowSwapchain` instance entrypoint waits until already
posted images leave the WINSVC producer queue. Zink uses it before replacing a
FIFO chain with another policy. Timeout preserves frames and allows retry;
consumer-held images may remain live. This is not a GPU-completion or VBlank
wait. External synchronization and the live device/chain are caller-owned.
Evidence/EGLZinkSwap covers the actual helper through native EGL mode changes,
including timeout/order, synchronization loss and exact pre-exit buffer balance.

Retirement preserves fences and native queue ownership while Desktop holds
an image, including after destroying the Vulkan device. Vulkan images and
user allocation callbacks finish synchronously at swapchain destruction;
independent native records finish after broker acknowledgement or exact
service death. Unknown RPC outcomes retain the original immutable request.
Old-swapchain replacement, timeout, hide, resize, aliases, render/present and
service-restart cleanup are covered by one targeted SMP4 fixture using the
canonical library, real WINSVC and modeled GPU execution. The subsequent
Desktop-owner integration verifies output/capture and process failure as
described above. Physical pixels, HDMI and interactive Desktop behavior
remain in OssiGPU.txt /0.79.37.

Build from the Libraries root with `./Build.sh R4VK` or `Build.bat R4VK`.
`-Doffline=true` requires cached source archives. `Tools/Build.ps1` resolves
the mapped workspace, obtains a verified R4NAK build receipt, prepares Mesa
and shader helpers, builds native C/NIL, and publishes matching archives to
the Zig build. `Artifacts/Native/R4VK/<host>` holds checked native caches;
no temporary fixture path is a build dependency. Windows execution remains
unchecked. Required host tools are described below and in R4NAK/README.md.

Applications import `R4VK:VULKAN_V1:1` through the normal R4M loader. Generated
C/Zig bindings validate the library table. Its `open` call receives the
immutable R4SYS/R4DRAW/R4DEV table addresses and returns the standard ICD
negotiation, instance-proc and physical-device-proc entrypoints. Vulkan then
uses its ordinary x86_64 C ABI. Opening creates no Vulkan object and does not
claim GPU availability. Invalid descriptors leave the output unchanged;
repeat opens with the same boot tables are idempotent. Keep the imported
library generation alive while using its functions or objects. Contract and
API details: `Contract/LibraryContract.json` and `Docs/API.md`.

The normal build runs one generated C/Zig ABI conformance case. The independent
C consumer used for integration links no Mesa/NVK code; all Vulkan calls enter
the canonical R4VK.R4L. See the current scoped result in
`Docs/Drivers/GrafikVulkan07935.json` in the workspace Docs repository.
Full source notices accompany the artifact in `ThirdParty/NOTICES.txt`.

Native capability queries reject external memory handles consistently:
buffer queries retain the requested compatible handle type but expose no
import/export bits; image, fence and semaphore queries likewise promise no
missing transport. The one queue per logical device admits only MEDIUM global
priority. Vulkan's two required relative priority levels give no cross-device
scheduling guarantee. Sparse,
placed-map, external-FD, DRM and calibrated GPU time remain unavailable.
The native physical-device API stays at the selected 1.3 baseline until a
complete higher profile is accepted. GPU query timestamps expose 64 valid
bits and Mesa's 1 ns period; the original NVK graphics/compute/copy report
commands write GPU time directly. This does not require the unsupported
host GPU-clock callback used for calibrated timestamps. Instance API 1.4 and
separately implemented extensions such as host-image-copy remain usable. The earlier priority=1
profile was invalid: Vulkan's required minimum is 2, regardless of global
priority support. See the normative Required Limits and Queue Priority sections
in the archived Khronos specification and GrafikVulkan07935.json / nvk_limits.
The 0.79.36 shader-object checkpoint enables EXT_shader_object. Both linked
and independent SPIR-V stages run through isolated frontend jobs, retain
serialized NIR/CPU sampler data through backend compilation, and release
every owner on success or failure. Vulkan objects and GPU upload stay on the
caller. A public SMP4 consumer covers VS/FS creation, binary round-trips,
incompatible binaries, partial outputs, callback OOM rollback and a specialized
compute shader's command submission. GPU execution is modeled, not measured.
See Docs/Drivers/GrafikVulkan07936.txt/.json. R4VK 0.1.5 also enables
EXT_device_generated_commands: its initialization/processing builders and
the KHR_copy_memory_indirect helper now use isolated NIR/NAK jobs. CPU stride
and QMD requirements are published only after successful compilation; uploads
and callback allocations stay on the caller. Public SMP4 checks cover explicit
and implicit compute preprocessing, shader execution sets, graphics layout
tokens, callback rollback, indirect copies and modeled submission. Indirect
memory-to-image copy remains unsupported. R4VK 0.1.6 enables KHR_pipeline_library,
EXT_graphics_pipeline_library and KHR_pipeline_binary. Four-part graphics
libraries, fast/LTO linking, retained NIR and compiled binary round-trips use
the same native compiler/cache owners. Binary imports preserve failure codes;
compute feedback starts with no cache hit. Shared shader upload checks device
status even when a retained heap block avoids native allocation. Public SMP4 checks cover short
exports, partial callback OOM, graphics draws after library destruction,
specialized compute submission and binary import after device loss. GPU pixels
and values remain unverified. Binary retrieval from a persistent driver cache
is unavailable; pipelineBinaryInternalCache and its control properties are false.
R4VK 0.1.7 reserves complete native binding pages for image planes and aligns
the D32S8 stencil-copy plane consistently. Public requirements include padding
before later planes/zcull, preventing an out-of-bounds native image binding.
Precompiled shader validation includes task/mesh stages and preserves errors
instead of reporting all frontend payload-transfer failures as host OOM.
A scoped SMP4 scene compiles all graphics stages, records indexed textured
draws with depth/stencil/blend through legacy/dynamic rendering and generated
commands, then reads the target from a storage-image compute shader. The model
checks selected NVIDIA command encoding, native resource coverage and cleanup;
it does not execute GPU instructions or verify pixel/compute results.
Roadmap 0.79.36 software integration is complete with R4VK 0.1.8. Descriptor
pool byte calculations use checked 64-bit arithmetic; the empty heap is
initialized before fallible backing allocation so OOM cleanup is valid.
The scoped SMP4 probe covers pool rollback/reset, sampler allocation failure
and reuse, overlapping public compute-pipeline creation with a shared cache,
MSAA4 color/depth/stencil and explicit image resolves, native command encoding,
reset/device-lost and exact native BO budget return after destruction.
Existing matching compiler/cache/queue fault proofs are reused. Original
class/format tables and native capability filtering define the exposed API.
These software checks do not execute GPU instructions or qualify Vulkan CTS.
Physical follow-up remains OssiGPU.txt; native WSI/Present follows in 0.79.37.

The public C consumer verifies these queries and negative CreateDevice results.
Original host-image-copy code works on the explicitly host-visible RAM type:
RGBA8 and BC1 mip/layer subregions round-trip through real NIL tiling with
row padding preserved. This CPU data comparison does not execute a GPU copy.
An actual kernel-broker reset with modeled GPU quiescence makes the old Vulkan
device report device-lost for WaitIdle/allocation; a new instance/device then
works. Software admission reuses the matching resource/sync/error proofs;
physical execution and Vulkan conformance are not implied.

Query-copy compute shaders and Blit/Resolve fragment shaders now build in
isolated CPU jobs; serialized NIR stays alive until compilation consumes it.
The common clear builder uses the same boundary, while NVK clears use its
original hardware commands. Public SMP4 command recording/submission covers
query copies (32/64-bit, availability), linear/color/integer/depth blits and
four-sample average/sample-zero resolves, each fresh and cached. This proves
compilation, uploads and modeled receipts, not GPU pixels or query results.

`../Shared/Native/threading.zig` implements process-owned mutexes and conditions on the
R4SYS v19 notification tail (Kernel 0.1.183). An uncontended mutex uses atomic
state and current-thread identity; it performs no notification wait/wake.
`../Shared/Native/threads.zig` exports the C11 subset used by Mesa, native joinable
workers and its monotonic condition interface. Kernel thread admission checks
executable sections of the program's exact imported library generations.
The shared port retains only the immutable boot-lifetime kernel table.

Every mutex, condition and once object must belong to one calling process.
Do not place these objects in shared R4L mutable globals. Once notifications are closed after initialization is published and all
waiters are notified. A waiter racing that close succeeds only after observing
the initialized state; the flag retains the closed, never-reused identity. Mesa global
state must be audited and adapted before integrating additional source units.
An unreportable void-API lifetime failure traps; it never silently continues.
UTC timed waits and detached threads remain unimplemented. The shared native
emulated-TLS helper is available for the OpenGL integration; R4VK does not
instantiate it or substitute it for its isolated compiler-job state.

`Port/runtime.zig` binds the combined port to R4SYS v21 (Kernel 0.1.196).
The compiled `r4native` module owns locks, C11 transport and process-local
publication. Current-thread identity and equality include both generations;
older kernels fail bootstrap explicitly. This changes no public Vulkan slot
or advertised device feature.
`Port/memory.zig` implements C allocation with one explicitly owned SDK Heap
per calling process, published through program_local_get/publish. Competing
initializers discard their own metadata region and use the published winner.
Regular allocations reuse SDK blocks; OOM returns null and failed realloc
preserves its input. Process retirement reclaims VM regions without requiring
library destructors. A shared library static supplies only the unique context
key, never a cached caller pointer. The selected source set follows these
process/worker owners; new Mesa globals and host APIs require their own audit.

`Port/time.zig` connects Mesa's private monotonic time/deadline helpers to
R4SYS. Deadline sleep uses the actual event-frequency ratio and rechecks the
monotonic clock after waking. This is not a POSIX clock or UTC implementation.
`Port/MesaRuntime.patch` selects this host timestamp path with `R4OS_VULKAN`,
omits external-FD fence/semaphore entrypoints and excludes DRM device IDs from
the private nvkmd layout. Those omissions require corresponding Vulkan
extensions to remain unadvertised in the installed native provider.

NVK and the common runtime use one private `vk_image` layout, including NIL's
modifier metadata and its invalid sentinel. This does not expose the DRM
modifier query or external-memory entrypoints. `Port/math.zig` supplies the
integer rounding required by Mesa's descriptor packing: ties away from zero,
independent of the FPU rounding mode, with x86 invalid/inexact flag semantics.
It also provides MXCSR-sensitive `lrint`, signed-bit-preserving `copysign`
and `frexp` decomposition for the full NIR/format path. The private C subset
includes allocation-free nested sorting and OOM-aware string duplication.
`Port/sort.c` includes `../Shared/Native/sort.c`; the existing search/sort
algorithms are shared unchanged, and the native cache hashes this source.

`Port/stdio.c` supports caller-owned, seekable output memory streams for Mesa
diagnostics. Growth failure preserves the buffer, position and ownership;
close publishes the buffer for the caller to free even after a write error.
Seek beyond the end allocates on the next write, which zero-fills the gap;
`SEEK_END` refers to the full buffer length. Explicit flush publishes the
smaller of position and length, following the [POSIX memory-stream contract](https://pubs.opengroup.org/onlinepubs/9799919799/functions/open_memstream.html).
This is a private Mesa subset, not a public libc: global `fflush(NULL)` and
closing console identities return an error. Filesystem streams and shared
stream registries are not provided. Mesa must serialize each individual stream.
The targeted Linux host probe checks these primitives with ASan/UBSan and
the floating-point boundaries with all four MXCSR rounding modes.

The complete selected NVK/Vulkan/NIR/format/push-diagnostic C source set now
compiles (514 translation units) and links with original NAK and native NIL.
The native device path excludes calibrated
timestamps, RMV and swapchain dispatch; swapchain-image requests return unsupported
until the native presentation integration exists. Experimental NVX CUBIN imports are
excluded consistently with the native instance's disabled experimental flags.
The selected shader-job and resource-provider paths are integrated; native
swapchain presentation remains roadmap work.

CPU capability/once state, GLSL interned types, shader-printf caches and NIR
diagnostic mutexes belong to the calling process. Generic C state publication
checks size/alignment and zeroes before publication. Instance lifetime owns
GLSL cache references; initial cache OOM fails construction. CPU instruction
facts come from CPUID/XCR0. Topology and affinity remain unknown; this selected
runtime must not use generic Mesa worker-pool scheduling based on those fields.

Private C errno and diagnostic buffers belong to an admitted compiler worker
call. Native options preserve upstream defaults; environment-driven shader
dump/replacement files are excluded. Assertion/abort on that worker fails its
job; outside it the failure traps. This is not general TLS or a filesystem.
Each commandbuffer owns its own OOM runout buffer. Generated helper printf
metadata is registered per process/job. Graphics pipelines, shader objects
and generated commands use these owners in completed software 0.79.36.

NVK's NIR-to-machine-code phase now uses an isolated CPU job. Original const
NIR serialization/deserialization gives the worker its own graph and interned
types. GLSL/printf caches and diagnostic mutexes are job-owned there; every C
allocation is tracked separately from Rust backing blocks. OOM/abort retires
the worker, and exact join precedes disposal of all remaining storage. The
borrowed device compiler is immutable. No GPU resource or callback-owned
Vulkan object is created inside this boundary. On success, ordinary shader
storage receives the code, constants and optional diagnostics before the job
is destroyed; upload then uses the existing caller-side rollback path.

Public compute pipelines also run SPIR-V translation, specialization and NIR
preprocessing in an isolated job. The original precompiled-shader wire format
crosses that boundary; Vulkan allocation callbacks, cache insertion and GPU
uploads remain outside it. The compute backend deserializes cached NIR inside
its own job, without creating a caller-owned intermediate graph. Frontend
warnings/errors are captured in bounded stack-owned storage and delivered to
Vulkan debug callbacks after join, including failure; truncation is reported.
The native builtin-NIR frontend likewise serializes/deserializes its types.
Graphics pipeline inputs now use the same serialized boundary described below;
shader objects and the selected builtin builders use that boundary as well.

A targeted SMP4 probe passes private-cache isolation, allocation overflow,
bounded C-heap exhaustion, abort while holding a private diagnostic mutex,
unchanged failed-owner output, and two real NAK compute compilations/uploads
with balanced cleanup. A subsequent public compute probe also passes a valid
SPIR-V storage-buffer shader with specialization, compile-required cache miss,
cache hits and export/import, frontend OOM/abort, translator error callbacks
and valid retry. Callback allocations and the final C heap balance. The GPU
peer models uploads and does not execute the machine code. Graphics linking,
shader objects, shader printf and Vulkan conformance are not established by
these checks.

Native pipeline-cache exports retain the standard Vulkan header and add a
versioned envelope with BLAKE3 record checksums. Import validates the entire
envelope before creating raw cache objects; incompatible initial data yields
an empty cache. Lazy typed deserialization preserves allocation/device errors
and keeps bytes for retry. NVK checks shader metadata and complete payload
extents before allocating/uploading; diagnostic string OOM remains an error.
Failed optional insertion retains only the caller's usable object, while
mandatory import and merge allocation failures unwind and return OOM. Short
exports contain complete records, and serialization diagnostics run after unlock.
The provider's cache identity includes the verified native sources, compiler
archives and build options; Tools/BuildNative.ps1 emits the required digest.
Since 0.1.40, the native C/NIL identities bind the verified R4NAK archive
instead of the entire diagnostic `build.json`. Its elapsed build time must
not change the driver or pipeline-cache identity when compiler bytes and
recipe are unchanged. Record, source and archive verification still run.
The targeted SMP4 cache probe passes corrupted/truncated inputs, import and
lazy-load OOM, full-table insertion/merge failure and retry, partial export
reuse and final zero C allocations. Its first failure exposed a string-reader
assertion after an earlier bounds error; blob reads now retain that error.

Compute meta copy/fill NIR builders now run as isolated CPU jobs. They publish
serialized bytes through a private native NIR-stage input, retained until
pipeline creation returns. Hashing consumes those bytes directly; the normal
isolated frontend reconstructs its graph. No GPU resource or Vulkan allocator
callback is created on the builder worker. Vulkan util sources/headers share
the same prepared private layout as runtime consumers.
The targeted SMP4 probe covers public descriptors/samplers, Fill/Copy/Update,
barriers, decoded compute launch methods, QueueSubmit2 binary/timeline chains,
fence timeout/completion/reset and command-pool reuse. Injected meta-builder
OOM/abort reaches EndCommandBuffer; retry succeeds and final allocation counts
balance. The backend models receipts without executing the GPU instructions.
The following image checkpoint extends this proof; final software admission and installed packaging are documented in GrafikVulkan07935/36.

Image command integration now includes RGBA8 graphics/compute and BC1/D32
copy-engine paths, mip/layer subregions and padded rows. The native meta NIR
builder is shared by copy/fill and rectangle stages; graphics pipeline inputs
also remain serialized until the backend job. Scalar tessellation state is
passed separately, without a caller-owned NIR graph. This does not establish
all geometry/tessellation, pipeline variants or shader-object paths.
Command buffers request their actual structure alignment; the image probe
exposed an aligned SSE store on an allocation previously requesting only eight
bytes. Meta cache initialization, keys and mandatory insertion now report OOM
and destroy unretained objects. Cache lookups capture object pointers while
holding the mutex, before another insertion can invalidate table entries.
Temporary compute-meta push descriptors are freed after their bytes have been
uploaded into command-owned memory, before restoring the caller state; the
second guest exposed their previous loss during final allocation accounting.
The bounded SMP4 probe checks decoded compute/draw/DMA commands, vertex OOM,
fragment abort, meta retention OOM/rehash/retry and final cleanup. Model
completion does not prove image contents or physical memory visibility.

`Tools/BuildNative.ps1 -CompilerRoot <native-NAK> -MesaRoot <prepared-Mesa>
-ShaderRoot <prepared-helpers> -OutputRoot <native-output>` now owns the native
C dispatch build. Paths resolve against the mapped workspace. It reuses the
NAK owner's ABI flags/source selection, validates preparation records and all
outputs, and compiles the selected 512 C units without fixture interceptors.
Source/header/tool hashes and compiler arguments determine the generated
`r4vk_build_identity`; `native.json` records the archive and object hashes.
An unchanged cache is verified, while damaged outputs are rejected.
One deterministically ordered combined archive member preserves weak Mesa
dispatch implementations; a response file avoids Windows command-line limits.
The Linux build, cache reuse/rejection and R4M link pass. Windows execution
remains unchecked. The R4VK module build links the
archive with matching native NAK/NIL and the R4VK Zig runtime. The archive
build alone does not grant Vulkan capabilities.

`Tools/Prepare.ps1 -OutputRoot <workspace-relative-or-absolute-output>` verifies
the existing pinned Mesa source manifest, creates private C/header overlays
and runs the original Vulkan/NVK/NIL table generators. Prepare the shared
Mesa toolchain through `R4NV/Tools/Compiler` first. The script does not download
sources, alter the pinned source tree or build a complete provider. Consumers
must compile the private NVK, Vulkan-runtime, compiler and util source/header
trees together, with `R4OS_VULKAN`
and the generated headers, so relative includes cannot bypass the port.

`Port/process_local.zig` publishes resident process-owned contexts for the
heap and loader state. `Port/loader.zig` implements ICD negotiation v1-v7,
rejects v0, and preserves the lowest negotiated version within one process.
Mesa's instance path uses the native enumerator in `Port/nvk_enumerate.c`.
It scans all bounded inventory slots, skips holes/incompatible devices and
publishes the complete list only after revalidating each captured incarnation.
Failure destroys all newly created devices; an inventory without eligible
NVIDIA hardware succeeds with an empty list. Missing platform tables remain
an initialization error. `Port/platform.zig` retains only immutable boot-time
table addresses. The verified native build supplies the required build digest.

The private NVK patch rejects external FD memory before GPU allocation,
removes its Linux-only entrypoints, rolls back failed internal map counts,
unlinks failed mapped allocations and destroys each retired BO's map mutex.
The canonical provider uses this construction and discovery path.

The private original `nvk_device.c` now checks the exact native backend's loss
state and marks the Vulkan device lost. Devices without execution queues do
not inspect a nonexistent shader-printf buffer. Native device initialization
omits DRM FDs and DRM sync-payload copying; ordinary native queue submission
remains the synchronization path. The host GPU-clock callback explicitly returns unsupported without modifying
output until the owner exposes that operation. Ordinary command-buffer
timestamp queries use the independent GPU report path.
Failed device construction destroys initialized meta state, and a zero-queue
cache-allocation failure skips resource owners that were never initialized.
The targeted SMP4 integration now passes public device/queue construction,
first-allocation OOM, buffer map/binding, optimal image/view creation, idle and
balanced destruction. Internal streams use Mesa timelines backed by native
fences; direct NVKMD calls allocate/unwrap points before submitting and publish
only successful signals. Timeline OOM/retry and zero/completed waits pass.
A zero M2MF class denotes an absent engine and emits no legacy setup commands.
These checks use a modeled GPU peer with real kernel brokers, not GPU execution.
Later command/shader and scoped fault checkpoints extend this initial integration proof.

`Port/Include/assert.h` follows C's NDEBUG and re-inclusion rules. The compiler
port's unconditional assertion macro is unsuitable for Mesa release structures
whose debug-only fields are absent. Assertions remain active in debug builds.

`Port/nvk_va.c` implements NVK's private VA allocation/bind/unbind/free operations
through the SDK's R4DRAW virtual-resource broker. Its context belongs to one
NVK device and requires that device's canonical BO-reference accessor. The
kernel takes its own BO loan; neither a caller pointer nor a C destructor is
retained in a driver. Non-sparse bindings may alias the same backing at several
addresses. Exact unbind waits for confirmed retirement. Free closes the parent
and requests ordered child cleanup, which may continue after C metadata is freed.

Finite operations use one native clock snapshot for the broker deadline and
the rounded wait duration. Failed allocation leaves the output unchanged;
timeout, stale epochs, malformed completion and uncertain cleanup set the
context's device-lost state. NVK device/queue status propagates this state.
R4DRAW36 plus explicit architecture revision3 IMAGE_LAYOUTS permits
uncompressed NVIDIA PTE kinds1..6 in system memory and VRAM. Kind travels in
the broker's opaque layout byte; the driver supplies matching RM depth/packing
attributes and requires exact allocation/map acknowledgements. Old backends
and kernels retain linear-only support. Compressed/unknown kinds, sparse/replay
VA, overlapping replacement and partial unbind remain unsupported.
The installed R4VK provider owns these backend components.

`Port/nvk_mem.c` owns native NVK memory through the common BO and native VRAM
brokers. Each allocation has its canonical BO reference and a bound VA range;
failure unwinds in reverse order. Kernel loans retain backing through late
VA retirement. Internal and client CPU mappings share one persistent kernel
lease while NVK retains its own internal map count. Persistent mapping requires
R4DRAW's optional `gfx_buffer_map_persistent` tail (v33, Kernel 0.1.189).
It holds write-back system RAM without excluding device/queue use. The caller
must synchronize actual CPU/GPU accesses; this lease is not a GPU barrier.

Mappable or explicitly coherent LOCAL memory uses GART. Explicit VRAM allocations never silently
change location, and CPU VRAM/BAR maps, external memory, fixed maps and overmap
are unsupported. Host coherence is accepted only from architecture-properties
revision 2's explicit system-memory capability: native x86_64 WB RAM, cached
RM registration and acknowledged snooped/GPU-uncached maps. Revision 1 and
revision 2 without that bit remain noncoherent; mismatched versions or unknown
flags fail without output mutation. Coherent explicit VRAM remains unsupported.
Noncoherent maps use Mesa's actual cache operations. Admitted devices require
explicit host coherence; memory types expose RAM and VRAM without a BAR heap
or unsupported budget telemetry. Memory and VA contexts share one atomic
device-lost state and outlive their NVK objects; the kernel never retains their C addresses or destructors.

`Port/nvk_device.c` reads NVIDIA's architecture facts through the optional
R4DRAW v34 backend-properties slot (Kernel 0.1.190, NVIDIA 0.1.130). It validates
the exact backend/memory generation, protocol and supported chip identities
before constructing Mesa's `nv_device_info`. PCI identity, active GPC/TPC counts,
VRAM and VA limits come from the driver's captured/acknowledged records. Shader
geometry uses the pinned SM86/89 definitions; CPU cache granularity comes from
CPUID. Errors preserve output, and stale epochs report device-lost.

The kernel copies one immutable bounded payload per backend incarnation,
authenticates the publishing driver and invalidates it on reset. Old backends
without properties remain usable through their original interface. The native
driver publishes these facts after CE startup, independently of display registration
(NVIDIA 0.1.131). Provider admission validates these records. Architecture
classes describe hardware methods, not admitted command queues. No BAR mapping,
transfer queue, 2D/M2MF, ZCULL or Vulkan qualification is inferred. Host coherence
uses the explicit native mapping-policy capability above, not GPU class IDs.

`Port/nvk_resource_device.c` creates native `nvkmd_pdev` and `nvkmd_dev` objects
for an exact backend incarnation. Mesa's original dispatch/list/refcount code
reaches the R4OS memory/VA adapters through their device operations. Creation
and resource allocation revalidate the binding; a missing former incarnation
sets sticky device-lost instead of selecting a replacement. Logical devices
have separate memory lists and loss state. They retain their physical owner;
memory and standalone VA objects retain their logical owner through destruction.
Final C cleanup may precede resident broker retirement without leaving caller
pointers in the kernel. Partial construction preserves output and unwinds.

Compute and graphics pipeline creation revalidate this native owner after
initializing all pipeline outputs to null. A resident shader-cache hit must
not create a live pipeline on a lost logical device. The check also covers
imported binaries and linked graphics libraries. Saved compiler bytes and
global pipeline keys retain their compatibility identity across a GPU reset;
a new logical device imports them into its own current native incarnation.

The original NVK physical-device constructor now has a native entry receiving
an exact R4OS backend and the immutable platform tables. `Port/nvk_physical.c`
revalidates the captured NVKMD owner and describes two heaps: non-mappable
device-local VRAM, and cached/coherent system memory. System capacity comes
from R4DEV total physical RAM minus the application reserve, rounded to the
backend binding alignment; allocation budgets still apply independently.
One graphics/compute/transfer queue is exposed by the resource description,
with medium priority, 64-bit GPU query timestamps and no sparse claim. Native filtering
removes FD/DRM, placed mapping, capture/replay, sparse, calibrated timestamps,
memory-budget telemetry and HDR metadata that lack native implementations.
The port does not inherit Linux NVK's conformance version.

The constructor is compiled in assertion/release modes. Final API/feature
and logical-device admission are documented in GrafikVulkan07935/36.
The targeted SMP4 fixture executes the original public CreateInstance and
DestroyInstance, complete physical-device construction and native enumeration
with real NAK/NIL, generated queries, OOM and partial-enumeration cleanup.
GPU facts remain modeled; VKPORT is a temporary test module, not an installed
R4VK provider or a complete logical VkDevice.
`Port/compiler.zig` gives the real Rust NAK compiler its own
process-owned arena, retained by the native physical device. Creation and
destruction run on joinable workers; Rust OOM/panic terminates that worker
without unwinding through C. The parent waits for exact retirement before
releasing storage. Failed owners cannot be reused, and separate owners can
run concurrently. The process registry contains active calls only; no caller
pointer lives in shared R4L BSS. Both outputs remain unchanged on create failure.

This adapter links the verified freestanding Rust NAK archive, not R4NAK's
job runtime or its complete C archive. Successful creation retains the actual
NAK object, and destruction normally calls its original Rust destructor. If
a destructor worker cannot start, the arena can release this compiler's CPU
allocations directly; the pinned object contains no external resources.
The arena records bounded diagnostics and uses the native process allocation
budget. Full shader jobs still require C/NIR global-state ownership, their
allocation/abort boundary, cancellation/deadlines and output lifetimes.
Those are not supplied by wrapping the physical-device constructor alone.
No successful replacement compiler or default build identity is provided.

`Tools/BuildNil.ps1 -CompilerRoot <R4NAK-cache> -MesaRoot <prepared-Mesa>
-OutputRoot <separate-output>` builds original freestanding NIL from the same
verified Mesa source. It checks the current NAK build inputs and archive,
matches Rust dependency object code against that archive, regenerates target
bindings, and records tool/input/output hashes in `nil.json`. It requires the
existing R4NAK preparation and `Tools/Prepare.ps1` outputs; no temporary helper
or host libc is part of this build. Verified unchanged outputs are reusable.

The two image constructors are private unchecked Rust entries. `Port/nil.c`
owns their native boundary: a separate short-lived compiler arena runs each
calculation on a joinable worker and publishes its local image only after
success. Original layout assertions become format rejection; worker/arena
OOM and initialization errors retain their distinct Vulkan results. NVK's
four construction sites propagate these results. No Rust unwind crosses C,
and an invalid image cannot poison a physical device's NAK compiler. Other
NIL descriptor/copy operations retain their original valid-input contracts.
This boundary runs at image construction, not per submitted frame.

Native image-format queries reject external handles, DRM tiling and sparse
flags with zeroed base properties. Calibrated-clock enumeration is excluded;
the native API version cannot be raised with Mesa's environment override.
Formatting uses the existing licensed stb_sprintf implementation; ordinary
C string operations are provided without the R4NAK job runtime.

Generated native entrypoints preserve weak ELF binding with default visibility.
R4XBuilder leaves only fully linked, verified ABS64 weak-undefined NULL pointers
unrelocated. Strong/local undefined targets, nonzero values/addends/pointers,
unlinked inputs and relaxed GOT relocations remain errors. Manifest-selected
R4M exports and the loader format are unchanged.

The original public NVK instance entrypoints use per-instance native defaults
from `Port/nvk_options.c`, matching the pinned baseline values. Linux DRIRC,
identity/experimental overrides and RMV/file tracing are excluded from this
policy. Instance failure unwinds copied application/engine names, creation
messengers and initialized mutexes; mutex OOM preserves its Vulkan error kind.

Original Mesa error/debug functions are linked to the process-owned C heap.
Creation callbacks are considered even in a release logging build; diagnostic
allocation failure cannot turn a returned Vulkan error into a NULL access.
`Port/console.zig`, `stdio.c` and `log.c` send unbuffered diagnostic output
through the current caller's R4SYS console. Formatting uses bounded streaming
scratch space without heap allocation. This supplies console streams only;
no filesystem FILE, caller stream handle or Linux environment is fabricated.

`Tools/Archive.ps1` preserves Mesa's required `link_whole` dispatch semantics.
`New-R4VKDispatchArchive` combines the explicit C object set into one archive
member through Zig LLD `-r --unique`, keeping same-named static sections
separate for final garbage collection. This retains weak-only generated
query implementations while excluding unrelated shader globals. Rust archives
retain normal selective extraction. Rebuilds replace the archive completely.
The public-instance SMP4 probe covers function lookup, allocation-failure
rollback, repeated/incomplete enumeration, physical properties and actual
creation/runtime debug callbacks with zero remaining C allocations.

`Port/nvk_submit.c` connects NVK contexts to the canonical native queue. It
translates GR/compute/copy engine bits, including NVK's copy-only upload
context through a GR channel with paired CE. Initial admission waits for an
actual fence; class IDs alone do not suffice. Push lists split at complete
method groups, preserve no-prefetch and use the R4NV packet contract.

Submissions retain all live bindings, including aliases after their original
BO object closes. The broker owns these loans independently of C metadata.
Because indirect GPU addressing prevents precise access discovery here,
device queues conservatively chain on genuine GPU fences. This matches the
currently serialized physical publisher and avoids spurious cross-queue
writer conflicts. Empty fence batches need no caller binding snapshot.
The retained device tail is explicitly released at logical device close.
No resource/submit mutex spans a GPU wait; failed allocation preserves the
buffered batch. Queue capacity applies bounded backpressure.

`Port/nvk_sync.c` supplies native binary events; Mesa's original timeline
implementation wraps their actual submitted points. Pending submission is
distinct from GPU completion. Dependencies pin their kernel handles while
being copied, completed points release public metadata, and reset/failure
propagates device-lost. Objects own their mutexes/conditions; no shared R4L
mutable cache or invented GPU completion is used. Native absolute waits use
R4SYS time; the POSIX MESA_VK_MAX_TIMEOUT debug override is excluded.

Uncompressed tiled allocations and images use the explicit VA kinds above;
sparse-bind contexts, compression allocation and external handles remain unsupported;
Calibrated GPU time and usage telemetry have no native owner callback. BAR mapping,
sparse, compression and external-FD remain unadvertised. The provider filters
features and limits to the native adapter contract. It does not inherit
upstream Linux conformance; the published conformance version is zero.

`Tools/PrepareShaders.ps1 -OutputRoot <output>` builds the original Mesa CLC
and NIR binding generator in a private source tree. It generates the NVK
query and indirect-copy helpers as native C with unchanged SPIR-V/NIR data.
`Port/MesaGenerators.patch` exposes the complete immutable printf metadata
through an explicit accessor instead of a C++ global constructor/destructor.
The provider registers it in its process-owned compiler context.
These host tools are not linked into R4OS. The shared Mesa lock and
`Tools/ShaderTools.lock.json` pin dependencies; `shaders.json` records options,
input/tool/output hashes. Windows and Linux use the same PowerShell path;
only Linux execution has been checked. Host prerequisites include LLVM/Clang
19 development files, SPIRV-Tools and LLVM-SPIRV with matching pkg-config data
(Debian: llvm-19-dev, libclang-cpp19-dev, libllvmspirvlib-19-dev, spirv-tools).

Earlier bounded SMP4 proofs use temporary native C/R4L fixtures. Actual
Mesa/NVK resource, sync and timeline code uses real kernel
queues and brokers with explicitly modeled GPU/VA receipts. Diagnostic-only
fixture replacements preserve negative errors and Mesa's lost flag; they do
not complete work. This does not validate physical GPU execution or DMA.
Evidence and software admission are recorded in GrafikVulkan07935.txt/.json
and GrafikVulkan07936.txt/.json under the workspace's Docs/Drivers directory.
Physical GPU validation remains in `ExFiles/Reports/OssiGPU.txt`.

A small public ICD consumer is available in Examples/Enumerate.zig.

## Raven2 identity (0.80.39)

RADV now accepts the paired Raven2 GC9.2.2/SDMA4.1.1 receipt and external
revisions81..88, with ASIC revisions8..15 and measured CU/RB masks bounded
by3/1. Picasso retains its11/2 maxima. Original Mesa helpers receive the
actual IP and classify CHIP_RAVEN2, including compiler workaround selection.
Generation, memory, timestamp and backing checks remain mandatory. This
host-checked admission does not constitute physical GPU qualification.
