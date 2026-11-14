# R4GL

Native Mesa EGL/OpenGL runtime for R4OS. Version34 admits the real generation2
startup context through `Query2:2` and the independent `EGL_V1:1` interface.
`R4GlRuntime` keeps version1 and its24-byte layout; application contains the
actual Start2 address for new callers. The process owns a stable startup
snapshot and explicit C view, together with its heap, TLS and finalizers.
Keep its startup imports and library objects alive through thread release and
runtime finish. Explicit legacy admission remains during the staged migration.

The initial software profile uses
softpipe without LLVM/JIT and works without a native GPU backend.
Version 0.1.28 negotiates EGL 1.5, OpenGL 3.3 Core for Softpipe/NVK, and
OpenGL 4.6 Core / GLSL 4.60 for the admitted AMD RADV profile. Zink connects
directly to the native R4VK ICD. Its pbuffer and native window profiles
have passed GLSL drawing submission, EGL fences, resize and buffer retirement
with modeled NVIDIA and AMD Picasso devices. On physical GA106, R4GL19 with
R4VK35 now produces 64 actual green pbuffer pixels and 64 unchanged guard bytes,
byte-identical to Softpipe, with a basic fence and exact warm BO retirement.
R4GL22/R4VK35 also pass four unchanged EGLImage, lifecycle, level and import
case groups on physical GA106: 444 complete RGBA records (7,104 pixels) match
the actual Software profile byte-for-byte, alongside the original integer,
PBO and neighbor predicates. EGL, thread/runtime and warm BO retirement pass.
R4GL24/R4VK37 also pass the regular Triangle GUI cycle on physical GA106:
three stable frames, fullscreen/restore, real border resize, occlusion,
pixel readback/capture, unchanged context/thread binding and exact warm BO
retirement. A separate controlled MMU fault and physical FLR qualify old
context loss and complete EGL cleanup, followed by fresh pixels from a new
context in the same GUI process. These are headless GPU execution results;
physical display transport and visual acceptance remain deferred. R4GL27
with R4VK39 passes genuinely outstanding fences on physical GA106: zero/1-ns
polls, a server wait returning while its producer remains pending, exact
shared compute results and deletion with an already held wait dispatch.
Both context threads, all EGL/runtime resources and warm BOs retire. The
same27/39 stand also passes the four unchanged image groups, with all7104
GPU pixels matching the software reference. Earlier
failed runs remain recorded, including the unassigned 4-KiB cold-to-warm
RAM/mapping increase; warm runs show no further growth.

Version25 adds optional monotonic runtime markers under
`R4GL_STARTUP_TRACE=1`. Physical timing with GL25/VK39 locates about328 ms
inside the next batch's BeginCommandBuffer; the original pending-fence
predicate still fails. Version26 prepares the next recording batch before
submitting the current batch for NVK with non-threaded CPU submission. The
current batch retains its exact query, submission and CPU flush receipt;
the prepared batch remains owned for cleanup also on device loss. Other
drivers and threaded submission keep their original order. Actual old/new
Mesa functions pass30 CPU controls under ASan/UBSan; the26 build and fresh
SMP4 pass. Physical H still fails its unchanged pending predicate and shows
that26 never enters preparation. Version27 includes NVK's threaded CPU
submission mode as well, retaining exact old/next batch ownership. Actual
26/27 functions pass30 CPU controls covering both modes, loss and foreign
driver/build behavior. Its build, SMP4 and physical pending/image
qualification pass; the physical marker confirms threaded NVK preparation.
Runtime markers never establish GPU completion and stay disabled by default.

Version20 discards a software window frame when its exact live Desktop
configuration advances after EGL's geometry check. The next drawable frame
uses the new geometry. Same-revision geometry errors, future storage,
foreign owners, invalid configurations and device loss remain errors. This
closes a reproduced resize/publication race; controlled owner regressions
also retain the existing FIFO drain and outstanding-consumer ownership rules.
Version28 handles a later resize during chain creation, attachment,
acquisition or presentation. Only a known OUT_OF_DATE reply for the exact
surface and a fresh validated higher configuration can discard the obsolete
software frame. Consumer/fence loans remain with the retired chain. Unknown
mutations, unchanged or unconfirmed revisions, invalid/foreign replies and
device loss remain errors. Actual old/new owner functions pass94 CPU
controls under ASan/UBSan, including FIFO draining and consumer retirement.
The original27 fullscreen-return failure remains recorded. Version28 now
passes the complete unchanged software and native GUI cycle with VK39, a
short native pbuffer, and one controlled held-context MMU/FLR loss followed
by full EGL cleanup and fresh pixels in the same process. Exact warm BO
accounting returns. The nine native/EGL/image/fence source pins are unchanged
from27; physical pending and image proofs retain their actual27/39 scope.
See GrafikEGL07939.txt/.json in Docs for the precise candidate and limits.

Version21 retains Kopper's rotating back resource when no front resource has
been requested. Version22 creates a front resource from the exact existing
back resource, and prepares a replacement back before its front alias during
transactional resize. The actual owner regressions cover rollback,
front-only, software and pbuffer controls. These corrections are insufficient
for the original physical native-window second-frame failure. R4VK37
addresses the separate previous-image residency conflict. The canonical
Triangle example also rechecks EGL extent after rendering/readback and
repaints if Desktop resized the drawable meanwhile. Version24 returns that
obsolete acquired frame through eglSwapBuffers before repainting. Its
same-extent green predicate remains exact. The complete native cycle is
qualified above with24/37.

Build from the workspace with `Repositories/Libraries/Build.sh R4GL`
(Windows: `Repositories\Libraries\Build.bat R4GL`). Add `-Doffline=true`
to require cached source archives. Shared PS7 orchestration derives paths
from Libraries/Settings.R4S. Dependencies: pinned Clang/LLVM 19.1.7, the
workspace Zig toolchain, Python 3 with Mako/PyYAML/packaging, Bison, Flex,
glslangValidator, Git and tar; online source acquisition also uses curl.
The software build needs no host Rust compiler or Meson installation.

`Tools/NativeInputs.json` owns the native unit/flag selection;
`Generators.json` owns the ordered upstream generator calls. The shared
Mesa source lock and ordered `Port` patches identify the source. Sources,
generated files and archives live below the configured artifact root.
Build receipts verify input and output hashes before cache reuse. The C++
and shared math/scanner sources are pinned separately. Backend admission uses
the actual Vulkan features and limits, independently of archive contents.

Import `R4GL:EGL_V1:1` and the R4SYS/R4DRAW/R4DEV platform groups. Call
`open` with the actual application startup context, then resolve standard
EGL/GL commands through the returned resolver. C consumers include
`Bindings/C/r4gl_api.h`; Zig consumers use the generated `r4gl.zig` binding.
Use standard API queries and context negotiation for supported capabilities.
For ordinary application C stdio, also import `R4DESK:Query2:2`, including in
console diagnostics. The Mesa C runtime can write diagnostic stderr through
that platform group; the minimal EGL/GL binding alone does not provide it.
`EGL_DEFAULT_DISPLAY` selects the opened process profile. Native window handles
encode the application's WINSVC window ID; pbuffer rendering is also supported.
EGL configs advertise swap intervals 0..1 only when a current output reports
synchronized FIFO presentation. Otherwise they advertise 0..0; the firmware
framebuffer does not promise VSync. When synchronized configs are offered,
additional 0..0 configs remain available for unsynchronized window targets.
Choose a compatible config for the window; creating a synchronized surface
on an incompatible output fails with `EGL_BAD_MATCH`. Intervals are clamped
by EGL to the selected config's limits. The default is 1 where supported.

Interval 0 selects MAILBOX when available, otherwise FIFO without a timing
promise. Interval 1 requires the exact output lifetime's synchronization
capability and selects FIFO. A change takes effect on the next swap; already
queued FIFO frames drain before the old chain closes. Outstanding consumer
loans keep their fence metadata and storage until release. A transient timeout
retains that state for retry. Losing synchronization rejects interval-1 posting;
the app can select 0 or recreate a compatible surface. No synthetic VBlank or
extra pixel copy is introduced. Evidence/EGLSwapIntervals covers the native
admission and chain transitions with controlled host responses, and the real
SMP4 firmware fallback. Physical VSync remains in Roadmap 0.82.37;
visual acceptance is 0.82.38.

For sRGB window/pbuffer attachments, request `EGL_GL_COLORSPACE_SRGB` and
use `glEnable(GL_FRAMEBUFFER_SRGB)` for linear shader output. EGL's default
linear surface remains linear even when the GL switch is enabled. The window
transport presents the stored SDR bytes without a second encoding pass;
alpha remains linear. Surface queries and GL attachment encoding agree after
rebinding and resizing. Evidence/EGLColorCore covers actual pixel values,
shader blending, core platform/image/sync calls, 64-bit attribute rejection
and window resource retirement in SMP4. This is focused software evidence,
not a full conformance certification. The core fence API requires EGL 1.5;
`eglCreateSync64KHR` independently requires the unadvertised CL extension.

`EGL_KHR_fence_sync` and `EGL_KHR_wait_sync` use Gallium fences from the
actual GL command stream. Softpipe completes rendering synchronously.
Client waits, server waits, status queries and deletion share resource
ownership; deleting a handle defers storage release until active calls return.
Fences retain their display backend and survive destruction of their creating
context. Reusable syncs and OpenCL event interop are not advertised.

The EGLImage frontend exports GL 2D textures, cube faces, 3D slices and
renderbuffers, and imports them through Mesa's GL image commands. Consumers
retain storage after the EGLImage handle is destroyed. Native metadata tracks
image siblings and detaches shared storage on respecification; framebuffer
and sampler views carry the selected mip level and layer. Focused software
probes cover these paths, including independent contexts and same-size
respecification. Structural changes clone distinct shared allocations before
publishing new storage; ordinary subimage writes and complete mipmap generation
keep sharing. Incomplete mipmap generation detaches siblings, and renderbuffer
exports use an atomic claim. Uploads, readback, copies and clears share physical
level/layer addressing, including immutable views of imported storage. Exports
and renderbuffer imports preserve the view's format. Focused SMP4 probes cover
five image/view families and RGBA8/R32UI reinterpretation. Imports acquire and
validate storage before replacing the old image; a rejected import preserves
its contents and mutability. Native image shape is independent of its backing
allocation. Surface resources use the final EGL reference callback, including
outstanding dispatcher loans after handle deletion. Evidence/EGLImageImport
covers these cases. Before exporting mutable storage, compatible defined mips
share a complete allocation that stays stable across BaseLevel/MaxLevel changes.
An existing complete allocation is reused. Evidence/EGLImageLevels covers both
range changes, inactive mip exports and a non-power-of-two root. These focused
proofs do not claim complete EGLImage conformance.

AMD Picasso uses the same profile-1 Zink/R4VK path with the RADV provider.
R4GL does not require a fabricated Vulkan border-color-swizzle extension:
when it is absent, Vulkan sampler views retain identity component mappings
and NIR applies the final GL mapping per stage and sampler binding. Float and
integer constants, sampler arrays and gathers retain their types and texel
order. Rebinding changes the shader key. Bindless textures are not offered
on this fallback because their handles have no fixed per-binding key.
Missing native stipple modes select Zink's existing geometry/fragment shader
lowering when the actual geometry and sample-shading features support it.
R4VK 0.1.21 pools small private AMD allocations and retains closed byte extents
until all submissions using their native root have completed. The native
32-root-binding limit remains unchanged. See AMDEGL08026.txt/.json in Docs.

Choose profile 0 for software rendering, or profile 1 for Zink pbuffer/window rendering. Profile 1 additionally requires the application's ordinary
`R4VK:VULKAN_V1:1` import; keep both library generations loaded through GL
cleanup. `open` creates no GPU device. `eglInitialize` checks the real Vulkan
baseline and reports `EGL_NOT_INITIALIZED` if it cannot create a suitable
backend. Failed initialization can be retried. The process profile is immutable;
there is no implicit switch to software after selecting Zink. Profile 0 remains
usable without an R4VK import.

The Zink path uses native ICD dispatch and process-owned instance/device caches.
It has no host Vulkan loader or installed layers and does not read host drirc.
Version18 admits the exact authenticated headless Desktop CPU consumer
independently of its native GPU renderer. Its output remains all-zero and its
portable BO stores remain CPU-owned. Roadmap0.82.29 separately qualifies
the physical NVIDIA producer, regular headless GUI and controlled context
loss. This admission alone is not a GPU-pixel proof. Actual Zink construction and the pbuffer/image pixel proofs
above are recorded separately.
Set the caller-local environment variable `R4GL_STARTUP_TRACE=1` for optional
bounded Zink constructor markers. Version19 distinguishes its logical-device
owner gate, device set and actual Vulkan call. Together with R4VK34's
`R4VK_DEVICE_TRACE=1`, these markers follow the actual requested device
construction. Both are silent by default and leave constructor order intact.
AMD Core admission checks the pinned Zink GL 4.0..4.6 baseline against actual
RADV features, limits and eleven required formats. Mesa then computes the
context version from its normal GL extension and limit requirements; a missing
prerequisite retains the 3.3 ceiling and reports the failed condition. NVK and
compatibility contexts retain their separately qualified 3.3 ceiling. Three
promoted bounded-query Core names are generated as aliases of the existing
ARB dispatch slots. Focused AMDOpenGL08027 evidence covers all 657 Core
entrypoints, GLSL460 compute/tessellation/FP64, OpenGL SPIR-V specialization,
persistent mappings/sync, bounded queries and production window retirement.
The AMD target remains Vulkan 1.3 / GL 4.6 Core / EGL 1.5; raytracing,
OpenCL/HIP/ROCm and later Vulkan versions are separate capabilities.
Native window configs additionally
require the real swapchain/mutable-format extensions and R4VK window entrypoint.
The private Kopper platform copies the application and WINSVC identity; it uses
R4VK's existing surface API and canonical GPU buffers. Zink interval 1 requires
both a synchronized output and the private R4VK queue-drain entrypoint. Config
discovery includes additional outputs; each window still checks its exact target. Evidence/EGLZinkBootstrap records the admission/cleanup proof without a
GPU, software shader pixels, and a separate actual Zink/R4VK context on controlled
GA106 metadata. The model does not execute GPU drawing or validate image output.
Evidence/EGLZinkDraw additionally covers actual GLSL330 compilation, pbuffer
drawing submission through NVK/NAK, EGL fence completion and the exact buffer
balance before process exit. Native command/resource packets are validated by
the model, which acknowledges completion without executing GPU instructions.
There is no GPU pixel or physical completion proof. A C11 barrier lifetime bug
in Mesa queue retirement was fixed by destroying the barrier only after all
worker callbacks complete; parallel work and native lifetime checks remain.
Evidence/EGLZinkWindow covers an sRGB native window, three presentations,
resize, a consumer loan surviving EGL teardown, and the exact initial buffer
balance before process exit. The last two frames do not call glFinish: the
frontend flushes pending vertices, marks the image for presentation and submits
the batch before presenting. GPU synchronization uses the presentation semaphore,
without an unconditional CPU wait in eglSwapBuffers. QueuePresent's synchronous
result is reported to EGL. A separate no-GPU run preserves admission failure,
explicit profile selection and Softpipe shader pixels.
Evidence/EGLZinkSwap qualifies native intervals with the real WINSVC and a modeled
synchronized output: FIFO timeout preserves both queued frames and order; retry
can change to MAILBOX, then back to FIFO. Loss of the output timing capability
rejects synchronized swaps before making a presentation semaphore; interval 0
can retry the still-owned image. An already acquired image is presented under
the old policy, then the replacement applies to the next image. The private
R4VK drain uses a one-second queue-wait deadline; an in-flight bounded service
RPC may finish afterwards. It does not wait for scanout or consumer-held images. Consumer loans and full buffer retirement
remain correct across teardown. No extra pixel copy or synthetic VBlank is used.
Device loss preserves the original drawable ownership for normal retirement;
Zink must not dereference a failed replacement allocation on a lost device.
Evidence/EGLZinkDeviceLoss resets the real kernel backend generation with a live
context, pending draw and consumer-held image. Repeated swaps report
EGL_CONTEXT_LOST, teardown returns the exact initial buffer balance, and the
consumer can return its retained image after EGL destruction. The GPU is modeled;
physical reset/recovery is still in OssiGPU.

Evidence/EGLDesktop completes the ordinary Desktop integration with the public
[triangle example](Examples/README.md): actual Softpipe pixels in a decorated
window, borderless fullscreen, exact geometry restoration and runtime finish in
SMP4/1 GB without NVIDIA. Desktop retires its last image when the producer closes
the chain, including occluded windows; reader, mapping and fence ownership still
follow the acknowledged Return path. The [capability record](Docs/Capabilities.md)
separates software pixels from native model declarations and physical evidence.

Softpipe allocates each full texture cache with its actual sampler view. Bound
stage/slot copies borrow that cache; rebinding invalidates stale texels and the
last view reference releases mappings, texture references and cache storage.
Allocation failure is returned through sampler-view creation. This removes about
192 MB of unused eager caches per context without shrinking cache capacity,
texture limits or raising the process budget. Evidence/EGLSoftpipeMemory measures
four usable contexts in SMP4/1 GB with the ordinary 512-MB desktop budget, and
checks shared sampling, rebind, texture updates, deletion and software pixels.

Before an application-created rendering thread returns, call `release_thread`.
Before `finish`, stop/join application rendering threads, destroy contexts and
surfaces, and terminate displays. A busy finish retains retirement ownership
and can be retried. A completed finish closes this process's runtime permanently.
See [the generated ABI contract](Docs/API.md) for exact lifetime/error rules.

Mesa and libc++ retain their original licenses. Full texts and source/header
provenance are in `ThirdParty`; shared math/scanner notices remain with their
owners under `Shared/Native`. The distribution carries the same notice bundle.


Version 0.1.24 uebernimmt die Korrektur aus dem nicht installierten Kandidaten23:
Sie gibt native Bilder bei einem bestaetigten Geometriefortschritt
ueber ihren regulaeren WSI-Presentpfad zurueck, bevor der naechste Frame
seinen Drawable neu validiert. Der Broker verwirft die alte Revision vor
der Publication; Kopper und R4VK behalten echte eingereichte Bilder bis
zur bestaetigten Retirement. Ein OUT_OF_DATE waehrend des Handoffs gilt
nur nach erneuter Abfrage der genauen lebenden Fensterrevision als Resize.
Gleiche/future Revisionen und normale GPU-/Hostfehler bleiben Fehler.
Das kanonische Triangle gibt auch einen waehrend des Renderns veralteten
Frame zuerst mit eglSwapBuffers zurueck; sein stabiler gruener Pixeltest
bleibt unveraendert. Zwanzig gezielte CPU-Besitzerkontrollen bestehen
(Alt22 reproduziert den fehlenden Handoff).23 wurde CPU/SMP4-geprueft;
der vollstaendige physische GUI-Zyklus besteht mit der installierten24/37.


Version 0.1.24 enthaelt die Resize-Handoff-Korrektur von23 und bindet
ausstehende gewoehnliche EGL-Fences fuer einen anderen Zink-Kontext an
die bestaetigte Batch-ID der wirklichen Screen-Timeline. Der Fence bleibt
bis zur Consumer-Einreichung referenziert; ein exportiertes Semaphor
behaelt seinen bisherigen Pfad. Bereits beendete/recycelte Batches werden
nicht als neue Abhaengigkeit ausgegeben. Eine fehlende aktive Timeline
bleibt ein Fehler. Der EGL-Owner unterscheidet nativen Geraeteverlust von
erfolgreichem Fence-Abschluss, auch wenn der Gallium-Besitzer seinen
Wait nach Verlust zurueckkehren laesst. Softwarecompletion und Kontext-/
Displayvalidierung bleiben erhalten. CPU13 Zink- und CPU15 EGL-Kontrollen
bestehen; alte Funktionen reproduzieren das fehlende Server-Wait bzw. den
falschen Completionerfolg. Das sind keine physischen Pending-/Resetbelege.
23 wurde CPU/SMP4-geprueft, aber nicht auf OssiPC installiert.24 besteht
Build/Contract und frischen SMP4 und ist als einziges Update von22 nach24
vollstaendig installiert. Der native GUI- und kontrollierte Verlust-/
Wiederaufbau-Nachweis mit24/37 besteht. Der damalige Pending-Fence-Nachweis
folgte erst mit27/39, wie oben abgegrenzt. Die CPU-Kontrollen sind keine
physischen GPU-Nachweise.
