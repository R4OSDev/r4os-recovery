# R4OS SDK

The active compiler/component selection is defined only by `Profiles/`.
Version-specific notes below describe their dated changes.

SDK0.64.181 provides normal generation2 application entry. Select
ENTRY_MODE=app with r4os-zig-generation2, r4os-c-generation2 or
r4os-rust-generation2 and Query2:2 imports for platform groups. Zig implements
r4_app_main(*r4os.App2), C implements r4_app_main(R4App2*) from r4os/app2.h,
and Rust uses r4os_sdk::app2!(main) with App2. The SDK emits R4XStart2:2 and
complete ordered manifest facts. Console, GUI, service and subsystem roles
retain their own rules; named library revisions remain independent.
Handle-based GUI/subsystem launches retain the existing desktop attachment
handshake: associate the exact process handle with its window before waiting
for entry completion. The normal console fixture's lifecycle mode performs
that original host operation explicitly.

App2 borrows the actual 120-byte context and canonical tables. Keep its Zig
object stationary while facades or allocators borrow it; return only after
all tasks, callbacks and argument/import loans retire. Rust App2 stays local
to the executing thread. Startup copies only admitted resident heap/entropy
callbacks. C/Rust retain the existing pooled VM heap and its exact instance,
generation, Busy, pending and release-acknowledgement rules. Optional Rust
alloc uses the same heap and an SDK-owned callback copy across workers.
Panic paths terminate the exact module or fault through UD2.

SDK0.64.213 selects generation2 for every central Zig/C/C++/Rust module
default. New application, driver and protocol templates use the matching
Query2 and Start2/DriverInit2/ProtocolInit2 identities. Runtime libraries
select Query2 metadata while keeping their independent API revisions.
SDK0.64.218 removes the retired module profiles, startup implementations and
positive SDK adapters. Unversioned App/context helpers now use generation2.
Historical wire records and explicit rejection fixtures remain in Contract;
they do not provide an executable generation1 path. Rebuild C/Rust projections
and native runtime objects together after this SDK change.
SDK-private native facade storage has changed: rebuild generated headers,
Rust projection and runtime objects together. Targeted checks are
platform2-test, vm-allocator-test, Tools/Test-RustHeap.ps1 (current default),
Tests/Simulation/App2Startup.c and Tests/Build/App2Zig, App2C and App2Rust.

SDK0.64.174 adds copied family-aware Query2 service clients in Zig
(`network_family`), C (`r4os/network_family_platform2.h`) and Rust
(`network_family`). They share the existing TCP/UDP/DNS providers and expose
explicit families, checked absolute budgets, provider/socket generations,
immutable resolver pages, stream prefixes and datagram truncation. Close is
explicit; a transport timeout grants no resource-retirement acknowledgement.
The initial providers support IPv4 and report IPv6 unavailable. The normative
wire and ownership contract is `Contract/API/NetworkFamily.txt`; the workspace
guide is `Docs/API/NetworkFamily.txt`. Consumer migration remains separate.

SDK 0.64.149 adds an optional synchronous `DownloadOptions.head_observer`.
It observes the decoded response and original headers before any sink write;
returning false rejects that response. Header slices and the observation are
borrowed only until callback return. Cancellation is checked again afterward.
`max_retries` defaults to the existing one read retry; set it to zero when an
outer transaction owns the shared retry budget. The C/Rust transport projection
and callback kind `download_head` expose the same native implementation.

The host-neutral R4OS SDK provides Zig, Rust and C module roots, current
platform and library helpers, build profiles and general project templates.
The platform API and ABI remain canonical in the separate Contract repository.

SDK0.64.91 retains the completed functional language-parity work47–71 and
closes the remaining SDK current-contract gaps in0.86.78.
Select SDK, Contract, Libraries and the matched toolset explicitly; all are
independent archives described by SDK-Release.json. Genuine host R4X, R4L,
R4D and R4P roots, app/lowlevel entry and GUI subsystem hosts are available
in all three languages. The common creator has33 host templates and retains
the two separate native C templates. Project pins and version selection belong
to the external caller; technical dependency/toolchain pins remain enforced.

Linux builds and local KVM-SMP4 functionality have qualified evidence in
[Inventory/LanguageParity.json](Inventory/LanguageParity.json), including
real C/Rust SHELL hosts with the current Desktop imports and WindowService
claim. Windows execution was explicitly skipped by the user on2026-10-22;
prepared Windows binaries do not qualify execution or cross-host identity.
Native R4CC remains a C subset; native Zig/Rust compilers are unavailable.
Rust uses its qualified integer codegen profile; direct Rust FP/SIMD,
physical hardware and performance remain separate qualifications.

The existing SDK module-test/test also run the small source review gate:

    zig build language-parity-check -Dparity-library-root=/LIBRARIES
    pwsh -File Tools/Test-LanguageParity.ps1 -SdkRoot /SDK -ContractRoot /CONTRACT -LibraryRoot /LIBRARIES

Use the ordinary matched Contract dependency/fork for the Zig command.
The gate compares actual owner bodies, shared bridges, generated C/Rust
projections and their functional-evidence mapping. A changed/new/deleted
input fails until its affected implementations and evidence are reviewed;
it never automatically refreshes hashes or grants functional qualification.
Unchanged evidence can be reused. The historical47 inventory stays dated;
current review identities live in drift_guard, with BOM/LF/CRLF normalized
only for this review. Real build receipts still hash exact compiler bytes.
Further public API changes must update the affected language facades/packages
and evidence in this same matrix, including later Desktop/Library work.

The historical SDK0.64.117/Contract0.64.61 combination used Libraries0.64.39 for its higher
Rust helper projection. Its compiler-owned aliases include R4AUDIO v4,
DriverApi v39 and the copied audio catalog records. The library C boundary,
native fingerprint and installed R4L binaries are unchanged. A platform record
extension requires checking this reachable projection as well as the SDK
projections. The0.88.56 matrix update records that library review.

SDK0.64.116 evaluates subsystem Runtime.run waits after guest, presentation
and I/O work using the current host clock. Absolute deadlines age during
that work; new relative retries keep their full interval from the actual
callback return. Guest time is projected on a copy without consuming virtual
work. Public cycle retains its explicit tick snapshot, and all public layouts,
generated C/Rust headers, ownership contracts and native fingerprints remain
unchanged. The0.88.58 review qualifies36 runtime groups, original native
C/Rust consumers and the full current BASIC/GB/SNES acceptance on KVM-SMP4;
it makes no isolated performance or physical audio claim. An earlier normal
SNES run reported one unexplained audio Write failure; another diagnostic
run stopped at a short test guest's focus timeout. The unchanged later normal
full run passes, while findings 0.88.88/89 retain these unresolved failures.
That positive run does not establish their cause or exclude SDK involvement.

Current operations require their actual callbacks: complete glyph bitmap,
real font revision/metrics, Unicode input, generation-bound network service
requests and V2 default storage summaries. Missing capabilities fail without
simulating an earlier OS. GUI beginPaint requires the existing six-callback
frame transaction. Exact slot bounds, optional groups/hardware, direct drawing
inside a valid transaction remain distinct. SDK92/Contract45 retires V1
diagnostic slots27/29/30 in place as zero tombstones in R4DEV35. Registry
V2 callers initialize version2 and complete224/136-byte records; short
headers fail without mutation. See DOCUMENTATION.de.txt for operation minima;
toolchain pins and caller project independence remain unchanged.

Rust host modules use the Contract's `Module/RustModuleV2.txt` and the matched
isolated tool profile. SDK0.64.60 supplies the actual no_std source-to-R4M0
builder and normal R4X startup, with console/hosted GUI/service helpers in
[Rust/README.txt](Rust/README.txt). Module/Cargo identities remain separate.
SDK0.64.64 completes the three independent Rust templates and the Linux
build/container/local KVM-SMP4 console, visible GUI close and service
registration/status/stop checks. Release metadata identifies exact component
archives, source revisions, tool hashes and separate evidence.
Windows tools/PS7 are prepared, not execution-qualified.
SDK0.64.65 corrects the capability catalog's linker origin: rust-lld is
provided by the pinned rustc host archive. llvm-tools-preview supplies the
separate inspection tools. Module codegen and Rust helper sources are unchanged.
Native guest Rust and other module roles remain separate explicit capabilities.
SDK0.64.70 binds Contract0.64.43 and Rust build profile/plan2. Cargo owns TOML,
locked local dependency graphs and features; explicit external roots and C
companions are supported with real compiler input accounting. Pure Rust builds
keep the independent toolset; native C sources explicitly select pinned Zig.
The SDK owns no Studio integration, component version selection or project pins.
SDK0.64.71 binds Contract0.64.44 and projects all twelve library-owned
contracts into local Rust consumer crates. Checked SDK `r4l` clients borrow
the App; C gains explicit optional admission and Query metadata access.
Library implementations and baselines stay with their owners; Rust provider
implementation roles remain separate from consuming those libraries.
SDK0.64.72 completes the storage/path/registry/console facade group for Rust
and C. Rust reuses compiler-projected C facades and the existing Zig save,
recent-document, hive and Unicode buffer owners through matched SDK objects.
The same release fixes the current recent-document write capacity and keeps
Cargo feature selection distinct from required hardware and effective Rust flags.
SDK0.64.73 adds complete current Rust/C process, thread, VM, notification and
async-I/O facades, reusing the existing C resource owner. Safe owned I/O keeps
all native buffer addresses until exact close ACK, including drop/forget;
borrowed asynchronous admission is explicitly unsafe. Generation, partial
progress, optional-slot and CPU-placement metadata retain their contracts.
SDK0.64.74 adds typed Rust/C service connections, endpoints, bounded service
loops, tray calls, clocks, request deadlines, serial ownership and sockets.
A compiler-typed scalar bridge reuses all 157 existing R4NET context methods;
C/Rust share the original service-loop and networking owners. Owned async
network requests keep stable buffers through actual close ACK, even after
drop/forget; raw borrowed admission is unsafe. Rust service templates now use
the common loop. Native release/negative consumers and a mixed-language
KVM SMP4 service/TCP/UDP/tray fixture qualify this group; physical serial
hardware and Windows execution remain separate qualifications.
SDK0.64.75 adds the full shared GUI/input/Canvas/FrameCanvas/widget/shape,
clipboard and WindowService host boundary for C and Rust. Compiler-generated
typed calls execute the original Zig owners; opaque native storage has a
checked layout/dispatch fingerprint. Rust offers pinned, allocation-free
sessions, exclusive paint loans, typed events and borrowed Unicode editors.
Host admission does not require an app window; exact process/epoch bindings
and explicit service reconnection remain separate from Desktop startup policy.
Other facade groups remain in their respective parity waves.
SDK0.64.76 extends that compiler-typed boundary to all public Zig graphics
owners: buffers/imports/maps, outputs/modes, queues/fences, cursor/present,
telemetry and coherent graphics status. Rust `graphics` provides a separate
pinned context without a window or host claim. Resource close and native
completion remain explicit; no drop/submit/copy implies scanout visibility.
Original native oracles and a real Rust/C KVM4 offscreen CPU-copy consumer
qualify this group. Native GPU/hardware and higher R4GFX helpers remain separate.
SDK0.64.80 adds `data` and `r4os/data_helpers.h`: typed calls into the original
JSON/ZIP protocol facades, raster/ICO, encoding/URL, manifest/project/artifact
metadata and CPU/hash/entropy owners. Rust provides pinned context/arena
storage, borrowed JSON/manifest/image views and streaming codec/hash wrappers.
The complete native operations remain in `data::raw`; retain ZIP work, archive,
entry and output storage through their final step. Protocol calls still require
R4DEV and the installed JSON/R4ZIP providers; no parser is embedded in an app.
`Data::sha256` selects the caller's executor per instance, retaining fresh OS
admission and the original software path. `readU64` now rejects overflow.
Named enum tags and immutable string constants are generated from their owners.
Build the data header with `-Ddata-bridge-generator-only=true`; its tool supports
`write`/`check` for the header and `r4os/generated/data_fingerprint.zig`.
The existing facade generator then projects this same C boundary to Rust.
`Tools/Test-RustData.ps1` is the small native consumer gate;
`Tests/Build/RustData` reuses the selected R4Zip owner's fixtures with an explicit
`-DependencyRoot` and uses real protocols in the guest. Qualification and limits:
[Language parity matrix](Inventory/LanguageParity.json).
SDK0.64.67 binds Contract0.64.42's complete technical C projection. Driver,
protocol, DMA/USB and service records now come from the canonical Contract;
the three manually duplicated network reply records are removed from the SDK.
Wire enums use exact-width integer typedefs, including R4AppProfile/u8 and
R4ErrorDomain/u16. Existing enum value names remain; use the typedef names,
not enum tags. This does not qualify new module roles or complete the higher
Rust/C SDK facades. Their scope and evidence live in Inventory/LanguageParity.json.

SDK0.64.68 generates normal Rust/C startup facts from the common manifest
parser and current Contract table defaults. Optional missing providers and
named library exports are supported. Rust exposes all six checked platform
views and the instance-bound import context. Startup does not query an app
window, allowing the desktop-host role. Generated Rust compiler inputs are
included in build receipts and removed with failed output; local library
resolvers and higher facades remain separate work.

SDK0.64.69 adds instance-bound pooled C/Rust heaps backed by the existing
Zig VM allocator. Rust's optional `alloc` feature supplies Box/Vec/String
through the pinned target liballoc and a matched prebuilt SDK runtime object;
exported Rust consumers still need no Zig compiler. Heap release retains
pending VM identities, including multiple failed direct frees. Fully linked,
proven local GOTPCREL slots close onto existing R4M0 REL32/ABS64 relocations;
relaxed GOTPCRELX and address-limited ABS32 remain rejected.

SDK0.64.145 supersedes the historical caller-owned system selection below:
build/tool policy, Contract and system libraries now come only from the three
SDK Profiles JSON originals. Callers select locations and pin extra libraries.

SDK0.64.66 leaves project version selection and project locks to the caller.
Generators and builds use explicit component directories; technical SDK/Contract
dependency hashes, Cargo.lock and the pinned toolchain remain enforced.
The general release manifest is SDK-Release.json. Capability schema2 removes
the former project-pin metadata; existing generated wrappers need the migration
described in [Templates/R4OS/README.txt](Templates/R4OS/README.txt).


Host consumers can read the versioned compiler-free capability
interface using `module-catalog capabilities --json` from the exported toolset.
[Capabilities.txt](Tools/ModuleCatalog/Capabilities.txt) defines schema3, exact
component identities, shared support/admission, real template file maps,
required tools and separate qualification/availability. The C host is Zig/Clang;
R4CC is the smaller native guest C compiler. No Rust compiler is needed to read
this interface. Existing manifest2, semantic plan1 and runtime catalog4 remain.

The optional `cpuIdleInfo` facade reads the separate R4DEV v29 idle receipt.
Driver CPU mechanisms negotiate `idlePublish` and `idlePolicy` individually
after the preserved168-byte prefix. Old tables return `err_no_fn` without
changing output. ACPI declarations and software attempts do not represent
measured hardware residency, wake latency or energy.

The shared update engine and recovery core accept only `R4U_JOURNAL=5`.
Formats 2–4 are unsupported; no compatibility conversion authorizes file
changes. V5 checksums, exact identities, copy selection, restart batches and
rollback remain supported, including new targets with `old_known=false`.

The shared update engine exposes SYSUPD's explicit `ARCHIVE-BOOT-BACKUP`
maintenance command. Its `system_update_backup` helper orders reference
checks, durable copy, complete comparison and conditional removal. Both
journal slots, boot configuration and sibling FAT identities must exclude
the candidate. Active stages, targets and retained journal backups stay
bound; no general cleanup or raw filesystem write is exposed.

Mixed Zig/C drivers use one Zig root followed by ordered C `SOURCE` entries
in their canonical `module.R4MF`, with `C_INCLUDE`, `C_DEFINE` and `C_FLAG`
for their C inputs. The SDK builds those companions into the same R4D ELF
and container, preserving the driver's entry and dependency contracts. The
existing mixed R4L path remains available; Zig R4X/R4P still have one source.
`R4DModuleOptions` and `R4DOptions` also expose the four corresponding C
options for direct build callers. Consumers that need the canonical parser
in a host build can use `build_api.module_manifest` instead of parsing a
second manifest format. After changing SDK manifest semantics, rebuild the
SDK host tools before running an image plan with an installed ModuleCatalog.

Subsystem R4X hosts can compose the allocation-free `subsystem_host` video
and input layer with `subsystem_runtime` for bounded guest slices, monotonic
guest time, lifecycle control, paced frames, and buffered S16LE audio through
the regular app audio facade. Discrete streams materialize on their first
non-silent quantum; initial silence keeps its queue position and may be
suppressed only when due. Active zero PCM retains its duration and stream.
Continuous sources materialize real zero PCM as well. Pause, mute, reset and
stop explicitly release the sink without changing guest time or video.
Waiting guests refill only after a guest step or
a due quantum; repeated host polls cannot consume future silence. A temporary
empty producer buffer keeps the stream open and schedules a bounded retry.
Pause, mute, reset and shutdown still release it, and resume/unmute schedule
a fresh refill even if the guest remains waiting. Pending video is published
before audio work, and each host cycle performs at
most one open, write, or close service operation. Optional source-frame
feedback distinguishes accepted, suppressed, and discarded PCM. Continuous
sources can additionally query generation-bound device progress; unknown
device evidence remains explicitly unconfirmed.
Runnable slices with completed operations yield cooperatively; a progress
result with zero operations and no deadline waits one bounded host tick so an
idle guest cannot turn into an active scheduler scan loop.

SDK0.64.102 keeps active zero PCM on the same stream for discrete and
continuous producers. Only initial unmaterialized discrete silence may be
suppressed. Explicit producer pause/mute/stop or final shutdown owns Close;
sample values never stand in for an idle receipt. The native sink continues
Close with the existing owned asynchronous request and original generation,
and terminal shutdown waits for actual stream/buffer release. No guessed
timeout, new timer/thread, ABI/layout change or HDA drain shortcut is added.
The existing signal/null/signal owner case and a pending-zero partial-receipt
pause case retain exact accepted/discarded bytes and actual close ordering.

SDK0.64.101 added continuous source deadlines and per-stream progress through
AUDSVC15 and R4AUDIO3/224. The original200-byte ABI prefix and minimum
version2 are retained. Progress distinguishes accepted source bytes, canonical
backend frames, actual DMA frames, consumed frames and unconfirmed frames;
canonical units are48kHz/stereo/S16. Service, logical-stream, kernel-stream,
backend, output and reset identities prevent reuse of an old cursor. A device
reset retires only its known prefix; remaining accepted data is unconfirmed.
Queue age uses the oldest outstanding source timestamp. Continuous sources
declare a fixed source deadline and explicit end; polling/retries never renew
the deadline. Initial discrete silence suppression remains available, while continuous
zero PCM advances its clock through the real sink.

The native subsystem audio transport still owns one copied PCM prefix and one
IO request at a time. Initial discovery, flow configuration and tracked write
form a bounded chain under the original absolute request budget; each request
is retired before the next starts. All continuation polling follows host input
and any ready frame publication. SNES29 uses20/40ms low/high watermarks across
the complete pipeline. Device-consumed frames are not a physical speaker
receipt, and missing device support must never be reported as played audio.

Pause/resume retains the same guest epoch: late Close consumption still
retires its outstanding PCM. Guest reset or a new capture epoch excludes the
old source instead. The current owner cases distinguish these paths explicitly
and preserve exact asynchronous retirement through the final Close reply.
Pause/mute byte counters include only PCM actually discarded after the owned
write receipt. A full or partial accepted prefix is credited once and cannot
also appear as intentionally discarded data; its deferred discard reason
survives a concurrent resume/reset until that receipt is retired.
Input policies can preserve the default physical-key-plus-text/pointer model
or select one printable text event with pointer filtering before mapping.
Stable raw-event sequences and ticks, filter counters, and an ignored-without-
wakeup runtime result keep delivery and loss observable without event logs.
Manually constructed video backends may omit optional replacement, native
XRGB32 and shared-raster callbacks; unavailable hooks default to `err_no_fn`
with their capability flags disabled, preserving the copied full/damage path.
These are independent current callback backends. The R4OS adapter requires
the current replacement/shared-raster callbacks and refuses an incomplete
provider before starting a frame. Current ring backpressure still permits a
bounded copied frame; it does not emulate missing APIs from an older OS.

Draw-heavy Zig apps can attach a caller-owned `FrameCanvas` command/resource
buffer with `PaintContext.bufferedCanvas`. Existing Canvas widgets then share
bounded `gui_frame_append` chunks within the required current transaction.
Flush failures cancel the whole private frame, oversized individual
resources keep their ordering through a direct chunk or established draw
fallback, and per-frame statistics expose commands, bytes, flushes and actual
draw transitions without another ABI.

`r4os.subsystem_persistence` is the source-level companion for cartridge
subsystems. Consumers supply only their canonical save directories, exact RTC
record size and validator; the helper supplies one digest lease, exact reads,
immutable coalesced snapshots, a serial joinable worker, same-directory atomic
stage/target/last-good publication, bounded retry/recovery and drain-before-
release. Cartridge battery policy, memory sizing, codecs and guest clocks stay
with the subsystem. The helper is compiled into each consumer and creates no
R4L or platform ABI.

## Service loops

`r4os.ServiceLoop` is the shared main-loop mechanism for R4X services. It
combines endpoint waits, the earliest service-owned absolute deadline, a
bounded stop-safety check, and queue draining limited to the endpoint depth.
Filled queues are processed without a forced tick between requests and yield
cooperatively after the batch budget. `ServiceLoopMetrics` and `report()`
provide passive numeric wait, wake, drain, and fairness counters without an
API or ABI extension.

The append-only R4DEV tail includes a PCI inventory performance snapshot.
Zig and C facades expose its source, capacity, configuration-access, ECAM
mapping, lookup, materialization, and enumeration timing counters while
remaining optional for older kernels.

`r4dev.Context.kernelHeapCheck` explicitly runs the bounded kernel-heap
diagnostic through optional R4DEV v15. The fixed result separates its own
allocations and VM reservations from concurrent global observations.
Missing groups/functions preserve the caller output and return the existing
availability errors. A normal app has no reason to start this diagnostic;
Spectra owns `CHECK MEMORY /KERNELHEAP`, JSON presentation and export.

DriverApi v20 exposes bounded audio-refill work with an absolute tick
deadline, a stable device key, and a maximum four-tick callback budget. It is
separate from the existing normal Driver Work submission facade.

DriverApi v21 additionally lets XHCI.R4D activate the sole kernel-resident
USB-host owner. UsbHostController v2 exposes productive port, control, bulk,
interrupt, recovery and poll callbacks plus capability and activity status;
it does not authorize a second PCI/MMIO/DMA implementation in the module.

The optional `driver_queue.retainResource` tail (table 1/64) retains source
or target backing of an active native job, including after producer exit.
The 56-byte prefix remains supported. Mapping-only references (flag 2) allow
describe, DMA/GPU residency and release; execution stays with the validated
queue extent. CPU maps, sharing and new execution are rejected. Actual
Work/start ownership is checked on every call. Mapping and fence lifetimes
remain independent. See Contract/ABI/R4DDriver.txt.

The optional `driver_outputs` receiver-source tail registers immutable
receiver generations independently of execution queues. The original 24-byte
output table prefix stays valid; all three receiver callbacks require the
complete 48-byte tail. Receiver-only catalog entries carry zero source/routing
limits and cannot participate in an atomic scanout commit. Registration and
publication require the actual Init/Work owner; closed/stale sources cannot
publish. Caller records must stay resident and exclusively borrowed through
the call. Close revokes metadata without claiming GPU quiescence.

DriverApi v22 appends owner-bound registration of exactly one synchronous
display-blit backend. The callback borrows a validated XRGB32 source, target
and at most eight regions for one call; the kernel retains target ownership,
fence completion and the complete CPU fallback.

DriverApi v23 exposes `DriverContext.netScheduleRx` as the IRQ-safe publication
point for adapter RX work. `netReceiveFrame` remains task-only and copies into
Netcore's bounded ownership queue; a busy result requires the driver to retain
the current device buffer and schedule a retry.

DriverApi v24 adds `netBackendQuery` and `netReceivePacket`. A v2 backend reads
its immutable offered/accepted/rejected selection after registration. Packet
metadata never removes the mandatory canonical flat bytes; return value 1
means those bytes were accepted through software fallback. The current BSP
selection is one queue and validated RX TCP/UDP checksum metadata only.
Since Kernel0.1.304 registration requires version2 and the complete120-byte
NetBackend. V1/short descriptors are rejected before registration or callbacks.
Flat callbacks, absent transmit_packet and existing poll paths remain valid;
optional features are not required. The v2 layout and DriverApi slots stay fixed.

JavaScript programs publish a non-zero bytecode generation after validation.
Normal, generator, and async calls check that generation in constant time;
the full fingerprint remains available as an explicit integrity diagnostic.
The browser WebRuntime allocates its large JavaScript realm only when the
first script or module needs it and releases the complete realm on document
abort, replacement, or deinitialization.

Typed file and registry paths initialize only their canonical bytes and the
required trailing zero. File normalization keeps its 160 rollback positions
as 16-bit offsets, for a fixed 640-byte temporary instead of two native-word
arrays; all public length, UTF-8, device-name, and normalization semantics are
unchanged in the Zig and C facades.

## Dependency mapping

The VM allocator keeps its existing bins, boundary tags, direct cache and
retention policy. Reserve, commit, decommit and release run with private
operation identity outside the shared metadata lock. Other threads can use
existing free blocks while that work waits; completion rebinds current block
metadata. Failed releases and decommits retain their exact retry identity.
The default allocator and explicit `vm_allocator.Heap` objects use the same
path. Keep an explicit heap at a stable address until all concurrent calls
and allocations have retired, including their notification cleanup.
Each heap owner now records `Stats.peak_active_bytes` at successful allocation
and resize mutations as the historical peak of all simultaneously active
bytes. `Stats.peak_region_active_bytes` retains the former largest individual
small-region or direct-aggregate peak. The counters begin at zero for a fresh
heap/default process state and remain historical across trim and shutdown;
reinitialize an explicit heap only after all its users have retired.

Long contention uses the existing optional R4SYS notifications, observing a
revision before rechecking the predicate. Notifications close after their last
waiter; a failed close keeps the handle for retry. Older or partial tables
fall back to `sleep_ticks` where available, then the existing yield support.
No new kernel allocator API is required. Focused host validation of these
existing cases is available through `./Build.sh vm-allocator-test` (Windows:
`Build.bat vm-allocator-test`).

`Settings.R4S` maps the local Contract and workspace paths. Relative and
absolute mappings are supported. Use the repository build starters so those
mappings are applied before Zig resolves packages.

## Build and validation

On Windows:

    Build.bat test

On Linux or macOS:

    ./Build.sh test

Detailed German migration notes are preserved in
`DOCUMENTATION.de.txt`.

## License

Original R4OS material is licensed under Apache License 2.0. See `LICENSE`,
`NOTICE`, and `THIRD_PARTY_NOTICES.md`.

## File transfer counts

Kernel 0.1.291 bounds each R4SYS read/write/append/stream-write request,
including its read-buffer capacity, to `2147483647` bytes because byte results
are signed 32-bit values. Oversized requests return `io_error_too_large`
(`-10`) before queue admission or file mutation; an async request ID remains
zero. Existing 64-bit file sizes, modern range offsets, finish sizes and
lock ranges retain their previous types and limits. Split larger transfers
into suitable chunks. See `Docs/API/FileTransferLimits.txt` in the workspace.

## File copies

`Files.copy` / `file_stream.copy` and C `r4_files_copy` submit one optional
`file_copy_buffered` request with caller-owned scratch space. It checks
backend file identity before replacement and keeps the paired filesystem
request throughout copying. Results preserve exact completed byte/chunk
counts; old providers return unavailable without an unsafe truncate/read
fallback. Failure cleanup can fail and progress is not a retry offset.


Registry-Selbsttests ab 0.78.64
-----------------------------
REG WRITESELFTEST/APITEST/MIGRATESELFTEST und RegEdit /SELFTEST sind nur fuer
ein ausdruecklich privates Testimage vorgesehen. Die Test-Injection liefert
TEMP/REGTEST.R4S mit R4OS_REGISTRY_SELFTEST=PRIVATE_IMAGE; Slim/Full enthalten
diese Testdeklaration nicht. Das ist eine Diagnosekonvention und kein Rechte-
modell. Ohne Deklaration brechen die schreibenden Tests vor Mutationen ab.
REG SELFTEST bleibt ein reiner Speichertest.

Der gemeinsame SDK-Helfer registry_selftest laesst keine bereits vorhandenen
TMP/BAK-, Original-, Restore- oder Displaced-Dateien als eigenen Bestand zu.
Lesefehler werden nicht als Abwesenheit behandelt. Die Originalsicherung wird
vollstaendig mit dem zuvor gelesenen Inhalt verglichen. Zum Rueckbau entsteht
aus ihr eine gepruefte zweite Stagedatei; nur diese wird durch R4SYS atomar
uebernommen. Erst nach erfolgreichem Ersatz, Bytevergleich und Bereinigung
werden REGSYS.SAV beziehungsweise SYSTEM.REB entfernt und OK ausgegeben.
Fehler behalten die Originalkopie; ein erneuter Test ueberschreibt sie nicht.
REGs temporaere Exportdatei wird ebenfalls nur bei vorheriger Abwesenheit
verwendet. Die acht schon zuvor auf16Byte ausgerichteten Scratch-Slices
bleiben bis zur Freigabe ausgerichtet und werden jetzt rueckwaerts freigegeben.

Begleitkorrektur in Kernel0.1.128: Externer atomarer Dateiersatz invalidiert
betroffene Registry-Cacheansichten auch nach einem moeglicherweise partiellen
I/O-Fehler. Der interne Registry-Commit benutzt denselben Dateipfad mit
explizit internem Abschluss, damit sein eigener Kandidat erhalten bleibt.
So stimmen nach einem Restore Dateibytes und gelesene Cachegeneration wieder
ueberein. Kein neuer ABI-Slot und keine neue Kernel-Diagnoseschnittstelle.

Nachweis: vier gebuendelte Hostfaelle fuer fehlgeschlagene Kopie/Publikation,
bestehende Sicherungen, fehlend/leere Hive, beide App-Abschluesse und alle
acht teilweisen Scratchallokationen. Ein lokaler SMP4-Gast verwendet eine
frisch erzeugte private246-Byte-Hive, prueft beide vorhandenen Selbsttests,
Originalbytes, Cachegeneration1 und Bereinigung. Keine regulaere Installation
wird als Testbestand verwendet. Belege unter Temp/roadmap-078-execution/07864.


`r4os.document_save.Saver` is a caller-owned synchronous policy for small
editable documents. It stages 64 KB chunks in create-only 8.3 siblings,
confirms stream completion and uses `Files.replaceAtomic` without an
overwrite fallback. Its result distinguishes a confirmed save (including a
retained backup) from an unconfirmed save with retained copies. Callers
publish their path, Dirty flag and history only for a committed result.
The helper preserves relative-path semantics and adds no kernel ABI.


HTTP and URL boundaries (0.78.70)
---------------------------------
HTTP URL parsing and request serialization both reject literal control
bytes, whitespace, fragments and incomplete percent escapes in a request
target. The serializer preserves valid percent escapes and percent-encodes
UTF-8 and other non-URI bytes. It also validates directly constructed URL
hosts and custom header names before emitting those fields. Existing
header-value checks remain in place.

URL parts search for a query only before the first fragment delimiter.
URL and Location getters/setters and Origin parsing already use this shared
splitter. Navigation and HTTP redirects now share reference resolution and
path normalization. Only complete dot segments are removed; query and
fragment data, encoded dots and repeated path slashes retain their meaning.
The HTTP resolver still uses caller capacity rather than the browser's
767-byte navigation limit.

A complete response head now returns a specific status/version/header/
length/transfer error. Both response decoders preserve a known header error
across later EOF. Missing terminators remain need_more until EOF; a valid
response with no fields is accepted. The existing incremental body decoder,
connection rules and cache policy are retained.

Six focused host cases cover request bytes, custom headers, redirects,
precise head errors, URL parts and navigation. HTTP checks include both
complete-buffer and streaming entry points. Product builds cover R4HTTP
0.1.4, R4JS 0.54.11, Klickifax 0.29.19, KlickifaxLive 0.2.20 and UpdateService
0.2.19. Recovery 0.1.54 / Menu 0.1.19 uses the same committed HTTP/URL sources
and the updated R4HTTP artifact. These are pure parser checks; no additional
QEMU, network or full browser profile is needed.

References: RFC 9112 sections 3.2, 4 and 5
(https://www.rfc-editor.org/rfc/rfc9112.html), RFC 3986 section 5.2
(https://www.rfc-editor.org/rfc/rfc3986.html), and the WHATWG URL fragment state
(https://url.spec.whatwg.org/#fragment-state).


Global bindings and primitive conversion (0.78.71)
-------------------------------------------------
The realm has one stable global object and a separate declarative lexical
environment. Script var and function declarations use global object
properties; reads and writes through names and globalThis see the same
values. let/const remain lexical. Standard intrinsics are non-enumerable,
writable and configurable, except undefined, NaN and Infinity, which are
immutable. Host defineGlobal keeps its explicit constant flag.

Script this is the stable realm object even after globalThis is reassigned.
Module this is undefined; arrows preserve their defining environment across
Script/module calls. A global identifier call does not implicitly bind an
object receiver. Strict writes to immutable globals fail; sloppy writes
leave their values unchanged. Function declarations are instantiated once
per statement list and can be redeclared in a later Script.

Array and function conversion observes Symbol.toPrimitive, then ordinary
valueOf/toString in hint order. Null and undefined mean an absent exotic
converter. Custom methods and thrown errors are observable. Function source
formatting belongs to Function.prototype.toString, avoiding recursive
conversion through that method. Values and converters remain rooted during
calls. This is a targeted language correction, not full ECMAScript support.


NTFS image boundaries (0.78.73)
-------------------------------
The shared R4OS path policy is 24 components, including a final file name.
The builder checks a child's depth before insertion. ImageCreator counts
the complete destination before creating parent nodes. NtfsVerify applies
the same boundary to both files and directories. The public volume reader
uses that shared constant; its existing runtime limit is unchanged.

The builder's index bitmap now covers all 4096 permitted index blocks.
Block construction checks the same limit before allocation; resident record
capacity remains checked by prepare, before any target is opened for writing.
A 3500-file fixture needs 587 blocks and an 80-byte bitmap, including the
previously out-of-range bit 512. Verification and the final long-name lookup
both succeed.

NtfsVerify collects consecutive nonresident extents, checks physical run
ranges and logical coverage, and requires initialized size <= data size.
Ordinary attributes require data size <= allocated size and complete run
coverage of that allocation, without holes. Sparse/compressed streams and
the special $BadClus:$Bad stream are distinguished; their logical coverage
is checked without applying ordinary physical-allocation equality. Raw
readRunsInto supports sparse zeroes but rejects compressed/encrypted data,
and never reports bytes beyond its actual run array as read successfully.
This does not claim to validate decompressed or decrypted file contents.

Reference: Microsoft ATTRIBUTE_RECORD_HEADER
https://learn.microsoft.com/en-us/windows/win32/devnotes/attribute-record-header
and the existing local NTFS layout references.

R4DRAW ABI12 appends generation-bound connector/mode/EDID queries and atomic
test/commit envelopes. C and Zig facades check optional table tails before
access; DriverApi27 appends an owner-bound output publication interface.
Native hardware commits require a separately negotiated backend; the
firmware fallback retains only its actual boot geometry and unknown refresh.
Zig R4D manifests may declare compiled ZIG_MODULE helpers as R4X already do;
this adds no runtime imports or application entry/class to drivers.
Thin owner launchers can share Tools/BuildModule.ps1 through their configured
SDK_ROOT; it resolves dependency forks and forwards an explicit argument array.

DriverApi28 retains the complete v27/584-byte prefix and appends the optional
`graphicsDisplay()` query at offset 584 (total 592 bytes). The Zig
`driver_display` helper and C `r4os/driver_display.h` negotiate a 40-byte table
for boot geometry, owner-bound prepare/commit/abort/restore, and an IRQ-safe
coalesced notification of the existing graphics worker. A handled transition
can report output-lost with retained ownership; callers must inspect outcome
and the resulting generation. Device access 4 is physical backing residency,
not GPU-VA or data-access permission. Display upload operation 2 belongs only
to the kernel's bound native source queue and never implies visible VBlank.

R4D callers can negotiate DriverApi32 through `DriverContext.threads()`.
`DriverThreadContext` and `r4os/driver_threads.h` expose start, cooperative stop,
finite join, release, status, current handle, tick sleep and owner statistics.
All slots are checked by version, size and availability. Handles, context and
timeout values keep their full 64-bit width. Timeout/cancellation retains the
target; completed callbacks still require successful task/stack release.
The ordinary resource-facade conformance fixture covers both Zig and C.

DriverApi33 is negotiated through `DriverContext.semaphores()`.
`DriverSemaphoreContext` and `r4os/driver_semaphores.h` provide typed create,
acquire, single release, destroy, snapshots and current execution flags.
Zero timeout tries once; UINT64_MAX requires a real permit. Close/stop never
substitutes for successful acquisition. The same resource facade fixture
checks full-width counters/handles/timeouts and optional table boundaries in
Zig and C; callers keep ownership on busy, timeout and failed destruction.

The version-1 DriverThreadApi has optional `abort_current` at offset 72
and `current_request` at offset 80, total 88 bytes. `DriverContext.threads()` continues to accept the
complete old 72-byte prefix. `canAbort()` checks the tail; an abortable start
is rejected before dispatch if it is absent. The C facade follows the same
size/slot checks. Flag 2 opts a dedicated Task into synchronous self-abort;
flag 4 is status-only and cannot be requested at creation.

`abortCurrent(negative_result)` returns only on refusal. An accepted call
bypasses module defers and returns to the kernel's enclosing Task boundary.
The owner must quiesce peers and explicitly recover retained resources.
Calls from Init/Work, non-abortable Tasks, IRQ or kernel critical sections
are not admitted; this does not provide remote termination or an exception
handler. DriverApi remains version 33, 632 bytes; existing service offsets
and module import names are unchanged.

`hasCurrentRequest()` / `currentRequest()` expose the immutable start request
of the actual running dedicated Task. They preserve the original full-width
handler/context and creation flags, never computed status flags. The kernel
resets a valid output before a missing context/owner result; an invalid fixed
32-byte request prefix remains untouched. The caller retains the referenced
context through Task retirement. No allocation, wait, CPU-local binding or
new unwind guard is involved. C uses `r4driver_thread_current_request`.

Thread query returns the largest complete prefix fitting the caller: 72 for
capacities 72..79, 80 for 80..87, and 88 from 88 upward. The sleeping flag 8
is status-only: the real backing Task is blocked in this service's sleep
queue. It does not describe semaphore or arbitrary application waits and
cannot be requested at creation. Original minimum size/version/imports and
DriverApi33/632 remain unchanged for this thread-service extension.

DriverApi34 separately appends `syncDmaRangeForDevice` and `syncDmaRangeForCpu`
through optional slots at 632/640 (total 648 bytes). The context checks the
provider version, size and callback before dispatch; old tables return
`err_no_fn`. Offsets and nonzero lengths are byte ranges of an existing mapping.
The kernel validates its actual retained bounds and preserves other bytes.
Callers still own publication order, per-field exclusion and device quiescence
before unmap. Dedicated threads and IRQ/storage callbacks are not admitted.
The existing resource facade test covers old prefixes, partial/null tails,
full-width arguments and provider errors.


Directory continuation (0.81.26)
-------------------------------
Zig and C storage iterators use the optional R4SYS directory_next tail with
caller-owned continuation and per-entry metadata. Restart is an explicit
failure requiring a fresh complete result generation. Old providers and
intentional live-index deletion retain their previous fallback semantics.
No cursor allocation, retained mount loan or explicit close is required.


Fragmented NTFS directory allocation (0.82.28)
---------------------------------------------
The INDEX_ALLOCATION owner checks AttrScratch.runs.len (256) when growing
an I30 index. MAX_DATA_RUNS (24) belongs to a different file payload buffer.
Record, bitmap, run coverage, reservation, flush and rollback checks remain
unchanged. Kernel Support uses the exact same source; no ABI or buffer grows.
The existing CheckNtfsTreeModel0607 adds 1200 resident files interleaved with
1200 separately allocated payloads:60fragmented index runs, exact contents
and cold remount pass. The original code rejects file498 with24runs despite
free clusters. The whole existing tree/churn/append/crash suite still passes.
On OssiPC, read-only metadata confirmed TEMP had24runs/25full index blocks;
CPU-only new writes failed with FileWrite=-4. Whole-hash-installed Kernel240
now writes36files plus progress/completion successfully, with exact full
readbacks and27actual index runs. Evidence: Temp/Ossi08228/FileIO28C and
Update28A-Installed.json. Host models, SMP4 and hardware are separate proofs.

Abgeschlossener Beleg0.82.28: ExFiles/Reports/OssiGPU/20261003-profile08228/Final08228/Result08228.json; urspruengliche Fehler und neue CPU-/Metadaten-/GPU-Belege getrennt erhalten.

Freestanding Zig modules emit optimized LLVM IR with stack checks enabled.
The existing builder changes only the probe strategy to LLVM inline probes
before machine code generation; this covers large realignment gaps as well
as ordinary and dynamic frames. Other IR/ABI/target attributes stay intact,
and the codegen stage does not rerun LLVM optimization passes. Native C/C++
uses `-Xclang -fstack-clash-protection` with the freestanding target.
Probes allocate or wait nowhere. The kernel retains stack VM/fault ownership;
callers must still prepare resident headroom before a no-sleep owner region.

`r4dev.Context.kernelSchedulerCheck` explicitly selects native synchronization,
roles/fairness/inheritance, real deadlines or IRQ/FPU work through optional
R4DEV v16. Reports prove exact own task generations and work releases;
unavailable hardware and isolated boot injections stay explicit. Missing
capabilities retain the existing error and leave caller output unchanged.

`r4dev.Context.kernelSmpCheck` explicitly runs owned functional CPU/clock,
remote-TLB, mapping and heap/mutex checks through optional R4DEV v17.
`smpTlbSnapshot` only reads current CPU/clock registration and real remote
invalidation counters. Fixed v1 records are224/184bytes. Missing capabilities
leave output unchanged; global timeout injection stays isolated boot-only.

R4DEV v18 adds optional `kernelBlockQueueCheck(out)`: explicit owned synthetic
blockqueue cases and exact task/device/completion receipts. It returns raw
status; missing slots preserve caller output. No physical disk is selected.

R4DEV v19 adds optional `kernelNvmeCheck(out)`: one explicit read-only NVMe
request with matching native ticket, driver CQE/IRQ-worker and DMA-release
receipts. Its fixed296-byte result distinguishes unavailable hardware or
capabilities, failure and retained resources. Passive counters are descriptive;
they cannot prove this request completed. Old storage requests retain their
56-byte layout; only capable backends receive the optional80-byte observed
request with its synchronous104-byte callback record. The callback data must
be copied before return; the resident cookie and buffer survive until actual
completion. Missing slots leave caller output unchanged.

R4DEV v20 adds optional `kernelUsbCheck(out)` for the existing bounded local
USB ring-cycle and event-router cases. Its fixed32-byte report contains case
masks; it needs no USB hardware and performs no live controller/queue work.
The call is reentrant and retains nothing. Missing slots preserve output.

Since Kernel0.1.305 the untyped DriverApi audio/synth registration slots are
reserved: always-1, no argument reads or side effects. The SDK retains
registerSynthEngineEx and the typed AudioBackend helpers. DriverApi36/656,
slot offsets96/120 and current descriptor/Idle/Stop/cleanup contracts stay fixed.

SerialLink retirement (0.84.34 / SDK0.64.35)
-----------------------------------------
The current R4NET and program Contexts no longer expose SerialLink methods.
Frozen ABI types and slots remain at Contract for binary compatibility; the
kernel stubs return err_no_fn without UART or buffer access. COM1 debugging
remains independent. General serial/COM access is a separate platform facility.
# Serial COM API (0.64.35)

`app.serial()` returns the optional typed COM context when the running R4DEV
table supports the complete serial tail (ABI 21). Enumerate with `count` and
`portAt`, then open the exact `port_id` and `generation`, or use `openNumber`.
Port count is dynamic; enumeration indices are not stable COM identities.
`read`, `write`, `drain`, `status`, `configure`, `cancel` and `close` use the
exclusive handle of the exact process instance. C equivalents are in
`r4os/serial.h`; driver backend wrappers are in `r4os/driver_serial.h`.

Use finite system tick budgets. Zero means poll. A read returns available
bytes; a write counts bytes accepted by the provider, and `drain` separately
waits for the physical sender. Always inspect both the return code and
`info.completed`: partial data remains meaningful after timeout or cancellation.
A failed close keeps the same handle and ownership for a later close attempt.
COM1 can remain busy while kernel debugging owns it. Backend registration is
restricted to lifecycle-owned driver initialization or owned Work; cached
notifications and shutdown operations retain their existing owner context.

## Compute workers

Since 0.85.18, an R4X may declare `META=runtime.workers=owned-v1` after
reviewing its worker entry points and reachable libraries/APIs. Zig
`sys.computeWorkerCreate` / `resources.createComputeWorker` and C
`r4sys_compute_worker_create` / `r4_resources_create_compute_worker` forward
the explicit creation flag through the existing generation-safe thread slot.
Older providers refuse that flag; callers may execute preparation serially.

This declaration does not move the foreground main thread. Compute descendants
retain their role even with zero creation flags. They do not produce console
or GUI output, consume stdin, launch a console descendant or claim a prompt.
Their buffers and context must remain valid until a real successful join or
terminal process retirement; a timeout never releases them. The existing
instance-generation, VM, FPU, placement and join/exit contracts still apply.
This is an ownership contract in the trusted single-user system.

CPU performance (0.64.43): `cpuPerformance` negotiates the optional R4DEV26
624-byte tail. It returns a receipt whose state and error must be checked; a
request readback is not achieved frequency. The optional112-byte
`DriverCpuPowerContext` tail retains exact hardware-control tokens until real
return. Existing64/72-byte observation tables remain supported. The provider
requires explicit local release before CPU offline or driver unload; uncertain
state keeps its resources. HWP package activation requires separate reset-only
consent. No governor or implicit policy runs in these facades.

Machine Check observations (0.64.48): `cpuMachineInfo` and `cpuMachineBank`
negotiate the independent optional R4DEV30 tail. They only copy retained
boot-passive or terminal raw evidence. Check origin, validity/fault/truncation
flags and the exact original epoch/sequence before interpreting a bank; no
snapshot is a current-health or generic repair promise. C uses the matching
`r4dev_cpu_machine_info` / `r4dev_cpu_machine_bank` facades. Older tables refuse
without touching output or caller tail.

Early microcode observations (0.64.49): `cpuMicrocodeInfo` negotiates the
optional R4DEV31 slot82 at672bytes, complete table680bytes. Its independent
144-byte record separates actual revision validity, virtual origin, exact
firmware binding, prerequisites, failed load/readback and common post-baseline
capture. A supplied package or virtual revision is not native update success.
This facade only copies resident evidence; no public reload or arbitrary
data/register endpoint exists. The C facade is `r4dev_cpu_microcode_info`.

PMU scopes (0.64.50): `cpuPmuInfo` and `cpuPmuResult` passively copy cached
interface facts and exact original CPU/epoch/generation receipts. Three
optional R4DEV32 slots follow the preserved680-byte prefix; complete704.
Separate128/256-byte records keep raw validity, restoration, IF and scope
independent. `cpuPmuMeasure` explicitly invokes1..4096 iterations of trusted
pure resident work: no allocation, fault, blocking, yield or API/placement
call inside the callback. Warm its code/data/stack first. The facade passes
a local typed callback slot; no optional-by-value wire ABI is introduced.
Native support needs the exact qualified architecture/model; virtual or
unsupported requests return unavailable before hardware/work. Intel overflow
never becomes valid absolute count; AMD legacy exposes modulo-only data.
Inspect result status/flags: return0 means a receipt, not valid measurements.
Failed copies preserve output/tails. No arbitrary event/MSR interface or
change to STANDARD workloads/reference/scoring. C facades use the same
`r4dev_cpu_pmu_info`, `_measure` and `_result` names.

Optional CPU leaves (0.64.51): `cpuAccelerationInfo` copies cached dispatch
hints, and `cpuAccelerationWork` grants one exact CPU/epoch/OS/task/IF window
for resident pure work, with a copied typed callback slot. R4DEV33/720 keeps
the complete old704-byte prefix; old and null providers preserve output.
Legacy `ProtocolApi` keeps its88-byte/version1 prefix and appends independently
size-checked nullable info/work functions at88/96. Inspect every work receipt:
return0 alone never accepts a result. Unlike native PMU, ordinary exposed ISA
may run on a virtual CPU after its real OS-state admission.

`cpu_memory.Policy` selects REP MOVSB only for larger forward copies with a
complete common ERMS hint. Short copies and backward overlap keep the normal
path, DF stays clear, and no cache flush or speculative page read is added.
`crypto_sha256.Sha256(provider)` keeps standard streaming, padding and fallback;
only8..64 full blocks are staged on the caller stack for the guarded SHA-NI
leaf. A rejected, incomplete or over-budget receipt never commits its state.
The provider returns a resident optional work-function pointer and may prefilter
missing SHA from cached info; this hint never replaces the mandatory grant.
No optional instruction is executed for warmup. XCR0=7/common AVX2 baseline
remains sufficient, without an additional XSTATE component. Explicit per-CPU
Spectra observations are separate from STANDARD and do not promise a speedup.

`secure_random` binds optional resident source functions before App workers or
protocol callbacks start. Hardware words use work kind RDRAND, an exact fresh
CPU grant, and at most ten carry-flag attempts per word. A registered driver is
the alternative; its declared maximum bounds every request. Every incomplete
operation clears the entire caller output, including earlier successful chunks.
No clock/ID substitute or entropy pool is introduced. WebCrypto keeps this same
shared implementation. Legacy ProtocolApi prefixes fail safely without reading
absent fields. Newly compiled consumers need the matching kernel facilities;
already compiled applications retain their embedded SDK implementation.

`driver_resources.Context.entropy()` caches the optional registration table
during driver init. Unregister closes admission; it never acknowledges physical
DMA stop. The driver must obtain its real reset and resource-release receipts.
`Build.sh entropy-test` (`Build.bat entropy-test` on Windows) checks bounded CF
failure, whole-output rollback, device limits, and optional-table boundaries.

Unicode dialog buffers (0.85.43): bounded_text.assignZ and TextField.setExact
reject invalid/overlong input without changing the previous value. Use
handleCodepointChecked to retain selected text on a capacity failure.
Byte offsets remain separate from Unicode scalars; FileDialog/InputDialog
accept the actual cursor and selection. DirectoryPage retains exact full
path identities; overlong presentation labels use whole scalars plus ... .
No normalization, glyph coverage, display width or grapheme claim.

0.64.57: Shared text widgets use the external R4STD Unicode17.0.0/UAX29rev47
default extended grapheme boundaries for editing and bounded clipping.
Rendering still measures scalar glyph advances; shaping, BiDi and grapheme
display width are separate capabilities. The SDK build injects a generated byte-exact snapshot of the pinned
Libraries23 text module. R4STD remains the sole implementation owner;
Tools/Sync-R4stdGrapheme.ps1 and SOURCE.json verify its upstream bytes.
This avoids a second Libraries build identity when older consumers use
local forks. Direct low-level build options can supply its
grapheme_source; normal Sdk profiles provide it automatically.

0.64.58: optional R4DEV34 fpuObservation copies integer metadata for the exact
native task generation and retained module RIP interval. Begin/end surround
userland work; no kernel ownership or register liveness crosses an ordinary
SysV call. Rejection preserves output, and no event is synthesized.

SDK0.64.77 adds shared Rust/C Audio/PCM, Device/diagnostic/clock and Power
owners under Rust `platform` and the existing typed native boundary. Pinned
contexts are independent of GUI imports; stream writes retain frame-aligned
partial progress and explicit close receipts. C audio gains rate/channel/frame
checks, bounded write-once and Busy progress. Current storage-summary defaults
no longer emulate missing V2 through V1; explicit V1 data views remain valid.
The same Zig PCM and service/policy algorithms execute from each language.
Native owner cases and a real Rust/C KVM4 silent-stream/status consumer qualify
this group. Audio admission, hardware status and policy acceptance do not
prove audible playback, physical frequency, DMA stop or performance.

SDK0.64.78 builds optional library-owned higher helpers with an explicit
`-LibraryHelpersRoot` and pinned `-ZigRoot` in the Rust module driver. Select
`r4os-library-helpers` from Libraries/Shared/Rust for R4STD text/settings/codecs,
R4IMG images and R4FONT resources; C uses each owner's `*_helpers.h` header.
The original library algorithms, data and resource acknowledgements remain
at their owners. The core SDK only builds/links the selected boundary and
records its actual source inputs. See Libraries/Shared/Rust/README.md.

SDK0.64.81 adds the original HTML/CSS/layout/font/image/form/navigation/
JavaScript/canvas/WebRuntime owners to Rust and C. Rust `web` supplies
borrowed document/layout helpers and RAII script/canvas owners; `web::raw`
and `Shared/C/include/r4os/web_helpers.h` retain every typed native operation.
Use caller-owned `MaybeUninit` storage, typically heap allocated for the
large realm/program/layout values. Native objects stay at their borrowed
address through all referenced documents, programs, fonts, assets and jobs.

Web hooks have Zig calling conventions. Never cast a C/Rust function to a
Zig hook: use `web_callback_bridge.Table`, the typed adapter factories and
Rust `web::Callbacks`. Its one C callback has signature
`R4SdkWebSlot (*)(void *user,uint32_t kind,const R4SdkWebSlot *args,
uint32_t count,void *output)`. The enabled mask uses the generated Kind
constants. Arguments borrow only that invocation; aggregate/float results
initialize the supplied exact output and return its pointer with PRESENT.
Optional absence clears PRESENT; native errors carry a resident error name
with NATIVE_ERROR. Do not retain callback arguments, allocate or run JavaScript
from GC root hooks, recursively collect, or overlap Rust mutable references
on a reentrant callback. Descriptor/user storage stays alive until all native
retainers have closed. Program-allocation callbacks initialize `Program`
defaults before returning it; Memory's original allocator adapter does this.
The existing full WebRuntime host dispatcher needs more than2 MB of stack;
its native owner case uses8 MB, and the real R4X consumer uses SDK stack probes
and the browser memory profile. Basic document/script/canvas cases also run
on ordinary2 MB native Rust test threads. This does not qualify direct
floating-point ABI, Windows, physical rendering or external transport jobs.

`web-parity-test` and `data-parity-test` select original owner cases through
`test_owners.zig` in the same test package. Merely importing the SDK as a
dependency does not collect its internal tests. Check actual test counts.
The bounded foreign-language consumers and actual unsafe/borrow negatives
are run by `Tools/Test-RustWeb.ps1`; the shared IMAGE_SCOPE=none RustWeb
fixture also runs in R4OS. Finished work directories remain disposable.

SDK0.64.82 adds `web::transport` and `r4os/transport_helpers.h`. All nine
current HTTP/fetch/security/cache/job/resource/document modules execute the
original owners; shared URL/crypto/document types retain their single source.
Typed raw operations cover the complete native surface. Rust offers synchronous
borrowed response buffers, pinned cache leases and owned GET jobs: cancel does
not free worker storage; drop services callbacks and joins before release, while
forgetting a job keeps its backing alive. Advanced borrowed/custom-callback jobs
remain unsafe until actual collect. Runtime jobs look up the exact generation.
Seven callback kinds extend the existing table, preserving its layout and the
original Zig/C calling conventions. Normal C/Rust app startup now binds the same
optional resident entropy provider as Zig, once before main/workers. Manual/raw
entry must explicitly call `R4SdkBindProgramEntropy` before creating workers.
No HTTP/TLS/cookie/CSP/cache or entropy policy is duplicated. Build the boundary
with `-Dtransport-bridge-generator-only=true`; `Tools/Test-RustTransport.ps1`
checks projections and selected native/ownership consumers. The mixed guest
fixture is `Tests/Build/RustTransport`, with its bounded loopback counterpart
`Tests/Fixture/Browser/TransportServer.py`. Current evidence and qualification
limits remain in the language parity matrix and shared report.

SDK0.64.83 adds `update` and `r4os/update_helpers.h`: original catalogue,
inventory, batch/journal, recovery/backup and nested partition/FAT32/NTFS/
image/install/Limine owners. Existing version/R4U/artifact data types remain
canonical. The generic catalogue uses JSON.R4P; replay/archive/device callbacks
instantiate original cores without a second transaction or filesystem policy.
Rust borrows immutable inventory/catalogue input and exclusive journal/device
storage. Native plans and custom callbacks retain all original source/allocator/
identity loans. The host file adapter owns its std.Io backend, distinguishes
opened and borrowed handles, and reports HostOnly in the guest. Guest physical
writes still require the original StorageTarget claim. GPT diagnostics are
read-only; native errors use resident names. Build with
`-Dupdate-bridge-generator-only=true`. Existing owner tests use
`-Dupdate-owner-tests-only=true -Dupdate-json-core=<original json_core.zig>`;
`Tools/Test-RustUpdate.ps1` and `Tests/Build/RustUpdate` are bounded consumers.
Facade generators and C objects now include a digest of the actual SDK/Contract
C headers in their compiler inputs, preventing stale C-import reuse. Shared
callback marshalling and canonical data names retain former web/data/transport
headers and declarations. Qualification remains in the shared parity matrix.

SDK0.64.84 adds `subsystems` and `r4os/subsystem_helpers.h` for the complete
original catalogue, launch, host, runtime and persistence owners. Rust provides
source-borrowing catalogue/resolution/launch, clock/pacer and cooperative runtime
helpers; all advanced native video/input/audio/save operations remain typed
unsafe calls with the original pinned buffer/context/callback/generation loans.
The safe runtime constructor disables borrowed audio. Thirty-eight callback
kinds and real platform adapters instantiate the existing cores. Runtime save
configuration shares `R4osStore`/`AsyncStore` with static Zig configurations.
Rust's normal GUI builder now admits the canonical subsystem manifest role.
Three synthetic Zig/C/Rust hosts qualify actual installed-catalog resolution,
equal work/output, owned saves, asynchronous completion and window cleanup.
GUI guests start through Desktop Run so the desktop binds their window before
entry; SSH controls setup/readback. Fixtures use `IMAGE_SCOPE=none` and explicit
`--include-target` selection. Build owner cases with
`-Dsubsystem-owner-tests-only=true`, the generator with
`-Dsubsystem-bridge-generator-only=true`, and C/Zig guests with
`-Dsubsystem-guest-fixtures-only=true`; use `Tools/Test-RustSubsystems.ps1` and
`Tests/Build/RustSubsystem` for native and bare consumers. The original shared
Indexed8 owner now preserves its 1024-byte palette, initializes the reserved
64-byte gap and writes pixels at the unchanged offset1088. Complete boundaries,
qualification and limits remain in the shared language-parity matrix.


SDK0.64.85 adds genuine C/Rust Runtime-R4L provider roots. Zig retains its
`IMPLEMENTATION_ZIG` module; C/Rust use their generated local table contracts
without a dummy Zig implementation. Rust requires `BINDING_RUST` and builds
through `Tools/Build-RustModule.ps1` using the current `r4os-rust-r4l-generation2` profile,
`r4l_entry`, Query2 and declared independent API exports. Matched toolsets can include
both host `r4l-contract-gen` binaries; the builder checks their identity and
the original contract/baseline/bindings before compilation. The SDK R4X-global
`alloc` feature is rejected for shared providers. Keep explicit caller/session
allocators and callbacks alive through actual close/quiescence. Exclude a nested
generated `Bindings/Rust` workspace from the provider root workspace.
`r4l::provider_header`/`r4l_provider!` and C `R4L_PROVIDER_QUERY` construct the
existing common descriptors/entry. New `Templates/R4L/C` and `Rust` retain local
contract generation. `-Dr4l-provider-tests-only=true` runs current manifest and
contract cases; `-Dr4l-consumer-fixtures-only=true` builds the C/Zig consumers in
`Tests/Build/R4LConsumers`. The genuine `CR4L`/`RustR4L` fixtures and Rust consumer
use the same regular builders/loader. Current scope and six actual guest
combinations remain in the shared parity matrix and report.

SDK0.64.86 adds genuine C and Rust R4D roots. Include `r4os/driver.h` and
use `R4D_ENTRIES(init, shutdown)` in C; Rust uses `driver_entry!` and
`driver::Driver`. Both keep the original R4DEV admission and current
DriverApi37/664. Driver resources retire explicitly after real quiescence;
no Drop frees active DMA/callback state. See Docs/SDK/LanguageParity.txt and
the `drivers_current_67` matrix evidence for the exact local qualification.

SDK0.64.87 adds genuine C/Rust R4P roots using `r4os/protocol.h` and
`R4P_ENTRIES`, or `protocol_entry!` and `protocol::Protocol`. The original
resident loader, PPI identity, role/dependency metadata and explicit provider
resource close remain authoritative. Logical Gate receipts do not unload code;
the loader currently does not call ProtocolShutdown automatically. See the
`protocols_current_68` matrix evidence and Docs/SDK/LanguageParity.txt.

SDK0.64.89 supplies one complete host template for each supported Zig/C/Rust
role and entry combination. `Tools/New-Project.ps1` creates these projects,
including initial local R4L contracts; `Tools/Build-Project.ps1` uses the
original manifest builder or the existing Rust/Cargo owner. The capability
catalog projects the current language matrix separately from tool presence
and host/guest/hardware evidence. Native R4CODE/R4BUILD retain their bounded
C subset and report host-only module roles without treating them as apps.

## Terminal process evidence

SDK0.64.108 / Contract0.64.56 adds R4SYS32 evidence observations (Kernel419).
Bind the exact process ID and generation while its completion exists. An
observation survives the process owner's consuming reap and retains only
terminal metadata and the inactive transcript. Close it explicitly when done.
Default bindings also close with their creator generation; PORTABLE bindings
survive that creator and require explicit close or boot end. Exporting a
Rust token alone does not make it portable.

Zig: `app.system().programObservationRetain/Wait/Read/Release`. C:
`r4_resources_observation_retain/wait/read/release` in `r4os/app_resources.h`.
Rust: `Resources::observe_process`, `Observation::{wait_ready,read,close}`;
`export` transfers release responsibility and `adopt_observation` adopts it.
The old process wait/reap API keeps its consuming ownership contract.

```c
R4Resources resources = { .app = app };
R4ProgramObservationHandle observation = {0};
/* process contains the exact ID/generation returned by the launch. */
int32_t rc = r4_resources_observation_retain(&resources, &process, 0, &observation);
if (rc == 0) {
    R4ProgramProcessCompletion completion = {0};
    rc = r4_resources_observation_wait(&resources, &observation,
                                       r4_timeout_forever(), &completion);
    /* Only rc == 0 confirms completion.exit_code; zero output is not proof. */
    int32_t released = r4_resources_observation_release(&resources, &observation);
    /* Preserve actual wait/read/release failures in the consumer. */
    (void)released;
}
```

GUI stdout (`R4SYS.write`) and stdout/stderr (`R4DESK.console_write`) enter a
lazy console transcript without a visible console or physical TTY routing.
The live CUI console_output surface stays separate; read GUI text through
its completed observation. It is the merged, normalized UTF-8 console
representation, including CRLF normalization, bounded to16384
bytes; it is neither raw per-stream bytes nor the R4DRAW GUI image. COM1
diagnostics are separate. OutputAvailable includes captured empty output;
OutputTruncated and OutputIncomplete report known loss (overflow, editing or
capture failure). An unavailable capture is not an empty successful capture.
Validate the actual exit code and application-specific expected markers too.

### Actual filename capabilities (0.88.27, SDK109 / R4SYS33)

Use Zig `Files.nameLimits(path.asZ())`, C `r4_files_name_limits`, or Rust
`Files::name_limits` to query the actual target mount. The file need not
exist. A visible drive's `DriveInfo.kind` alone cannot identify hidden
`C:\BOOT` routing. The 56-byte record reports byte and UTF-16-unit budgets,
provider rules, independent atomic staging rules and a mount-generation
snapshot; it reserves nothing.

```c
R4Files files = { .system = &app->system };
R4FilePath path = {0};
const uint8_t name[] = "D:\\SAVE\\GAME.DAT";
if (r4_file_path(name, sizeof(name)-1, &path) == R4_PATH_OK) {
    R4FileNameLimits limits = {0};
    int32_t rc = r4_files_name_limits(&files, &path, &limits);
    if (rc == 0 && (limits.flags & R4OS_FILE_NAME_LIMITS_FLAG_KNOWN)) {
        /* Respect all reported bounds/rules; handle the actual CREATE too. */
    }
}
```

Current FAT32 and NTFS names support 255 UTF-16 units / at most 765 UTF-8
bytes; raw/resolved visible paths fit 1023 bytes excluding NUL. The SDK's
260-character syntax budget and C/Rust non-BMP syntax restriction remain
separate. Unsupported providers/callbacks return -2 with output untouched,
not fabricated zero limits.

Valid long names work with ordinary CREATE. Atomic stage/backup names have
their own short-name rule; the existing document saver already creates
unique `DSxxxxxx.TMP` / `.BAK` candidates and preserves the full target name.
Stream begin and atomic replacement now report
`R4OS_FILE_STREAM_ERROR_NAME_NOT_SUPPORTED (-64)` and
`R4OS_FILE_STREAM_ERROR_NAME_TOO_LONG (-65)` (atomic aliases use the same
values), preserving files on these preflight failures. Other errors and
cleanup obligations retain their operation-specific meaning.


### Native pointer capture and FPS mouse-look

SDK0.64.110/Contract58 expose R4DESK19 native capture. In public C, include
`<r4os/app_gui.h>`, retain `R4GuiPointerWindowIdentity` from
`r4_window_pointer_identity`, then call `r4_window_pointer_capture` with
`R4OS_GUI_POINTER_MODE_DRAG` or `R4OS_GUI_POINTER_MODE_RELATIVE` and keep its full
`R4GuiPointerCaptureHandle`. Return0 accepts PENDING; wait for the matching
`R4_MESSAGE_POINTER_CAPTURE` with state ACTIVE before mouse-look. Read
`R4_MESSAGE_MOUSE_RELATIVE` physical dx/dy and `R4_MESSAGE_MOUSE_WHEEL`;
`r4_window_pointer_status` observes state and `r4_window_pointer_release` stops
capture. Cancellation clears held game/widget interaction state.

`Examples/MouseLook.c` demonstrates real Down/Up dragging and button-free FPS
mouse-look with typed focus/cancel messages. Build its
`Tests/Build/MouseLook/module.R4MF` and launch it as a Desktop GUI app. Relative
mode hides/freezes the system cursor, uses preclamp physical movement and
restores a defined cursor position on release. Absolute remote moves cancel
relative mode; they do not supply raw deltas. Acquiring a new window incarnation
requires an intentionally refreshed identity. SDK `gui.MouseCapture` is local
widget state and does not request native capture. Zig Window pointer methods
and Rust `gui::Session` expose the same exact tokens and asynchronous grant.
Guest and physical qualification is recorded separately in the project
Docs/API/GuiFacade.md. Compilation alone does not qualify outside-client
dragging, pointer visibility or physical relative input.
# Complete audio output catalogs (0.88.55, SDK0.64.115)

`r4audio.Context.audioOutputCatalog` and C `r4audio_output_catalog` copy the
whole current catalog into at least256 caller-owned `AudioOutputInfo` rows and
a disjoint `AudioOutputCatalog` initialized to version1/size224. Only result1
publishes a complete receipt. On failure discard scratch rows; metadata and
unused caller tails remain unchanged. The scalar `audioOutputInfo` remains
available for individual consumers. Optional R4AUDIO slot26 is negotiated by
size and function presence; no legacy scan fabricates catalog generations.

The receipt binds actual registry generation, selected registration and up
to8 exact provider registration/catalog/count/active witnesses. Driver code
binds `registerAudioOutputEpoch` once from the same owner after structured
backend registration (DriverApi39/672). A provider serializes row publication,
advances a nonreused epoch for changes including ABA, and reports Busy during
transitions/exhaustion. HDA47 and AC9711 implement this contract; unsupported
providers return `err_no_fn` for complete capture. This is not a physical
route, Stop, ELD or speaker receipt.

Current compiler-generated C/Rust helpers include
`R4SdkAudioContext_audioOutputCatalog`,
`R4SdkDriverContext_registerAudioOutputEpoch` and the reachable subsystem
audio context. Driver, GUI-Audio and subsystem fingerprints/projections are
regenerated together. The source review records qualified native C/Rust
owner and negative-consumer cases plus actual KVM4 Core/provider/AUDSVC/HDA/
AC97 catalog, selection, PCM and teardown evidence in `Docs/Audio/README.txt`.
SDK0.64.117 publishes Contract0.64.61 with explicitly retired audio
detail durations. ProgramPerformanceSummary15/6352 and AudioBackendStatus128
retain every field offset and type. Current providers return the named
audio_duration_ticks_unavailable (UINT64_MAX) and clear audio_latency_ready;
exclude the sentinel from arithmetic, latency displays and scores. PCM work,
errors, actual progress and Close remain independent. SDK runtime/facade
implementation, C/Rust aliases and all native fingerprints are unchanged.
The0.88.59 source review covers the semantic retirement and current ABI/owner
cases; native Kernel/driver qualification is recorded in the Audio domain.

### Restartable Desktop evidence handoff (SDK0.64.126 candidate)

Contract67/WINSVC29/DESKRUN3 add a service-owned observation lease. The early
Desktop reference and the broker reference before Desktop ACK remain the
bridge. The observer receives completion/output evidence of that exact process
generation; Desktop keeps lifecycle and consuming reap ownership.

Use `desktop_evidence.Client` / `r4_desktop_evidence_*` /
`Services::evidence_*`. Token128, request136 and reply header288 bytes are
shared generated types. Read replies append at most3808output bytes. Transport
failure, service result and the original app exit code are separate values.
The example `Examples/DesktopEvidence.c` includes persistence hooks and recovery.

1. Keep the original DESKRUN3 launch key plus `evidence_epoch[3]` (lossless
   decimal strings), or a scope saved before that launch. Require
   `evidence_scope_available`. Numeric legacy `/STATUS` cannot supply a missing
   original epoch. Do not combine an old numeric launch key with a fresh scope.
2. Choose a nonzero receiver intent and save the pre-intent before Reserve.
   Reserve allocates no kernel reference. Save its returned nonzero serial
   before Offer. A lost Reserve response is resolved by read-only Status with
   the same saved pre-intent; an old missing serial never creates a new retain.
3. Offer binds an independent creator-bound WINSVC reference while the original
   launch reference still protects the evidence. A waiting offer is promoted
   on actual launch completion before Desktop ACK. Lost bridge means unavailable.
4. Save the canonical token, including the full process generation, before ACK.
   Status resolves lost Offer/ACK responses without another reference or app.
   It can confirm Reserved before retrying the same Offer serial. Never replace
   Unknown/Expired/Stale with a blind new retain, reservation or launch.
5. ACK leases survive observer/helper exit until explicit Release or broker end.
   Unacknowledged reservations expire after5minutes;16slots bound total live
   leases/reservations. Active leases are never evicted by launch/history pressure.
   Closed tombstones are bounded; evicted old serials remain Unknown.
6. Read Status/Read after restart using the saved token. Keep the original
   completion sequence, exit code, generation and output flags. Zero output,
   truncation, incomplete output and unavailable evidence remain distinct.
   Finally release; copied tokens alias one lease, independent observers use
   distinct intents. C/Zig close explicitly; Rust Drop attempts Release unless
   the token was exported. Persist before ACK so interrupted cleanup is recoverable.

A192bit actual-entropy WINSVC incarnation plus full broker generation binds
tokens to the current service lifetime inside one boot. Restarting WINSVC or
booting anew invalidates the old epoch even if numeric IDs repeat. This is
narrower than a boot UUID. No clock/ID entropy fallback is used; missing entropy
makes this handoff unavailable. Raw portable kernel bindings are not exported.
Desktop restart keeps already protected old evidence while the broker lives.

Four actual ownership/recovery/expiry cases and the existing14launch cases,
public C/Zig/Rust builds and the generated ABI interoperability pass. The
normal Kernel452/SMP4/Desktop197/WINSVC29/DESKRUN3 guest qualifies two original
observer leases after consuming reap, saved-record helper restart, deliberately
unexported Offer/ACK results,17new launches through16history slots, empty and
truncated output, public native Rust/Zig adoption/read/export, five wrong-token
rejections, real5minute expiry, last-reference deletion and broker orphan cleanup.
A fresh boot of the same immutable image repeats every numeric token identity;
the saved token differs only in its192bit epoch and is rejected as Stale while
the new acknowledged control remains readable. All three guests shut down
normally. First unavailable-scope and private qualifier/preflight failures remain.
WINSVC29 explicitly imports R4DEV for the existing SDK hardware-entropy provider;
without usable entropy the scope is Unavailable, never a clock-derived token.
The new service copies the entire original Completion128, including incomplete
flags; this run does not add a forced-writer-incomplete or full Desktop-restart
injection. Quota16 is covered by the four owner tests, not new native exhaustion.
Evidence: Docs/Desktop/DeskRun.txt and Core/0.88.97-desktop-evidence reports.
These remain local SDK126/Contract67 source candidates. Published immutable
SDK/Contract/Full matching belongs to0.88.99/100 after all functional work;
no Studio0.8.1, Windows, physical hardware or STANDARD qualification is implied.

## Delegated Desktop actions (0.88.98 source candidate)

SDK127 / Contract68 expose `desktop_actions.Client` (Zig),
`r4os/desktop_actions.h` (C) and `Services::action_*` (Rust). An original
DESKRUN `/CONTROLLER:pid:generation` explicitly grants resize, minimize and
restore for its actual child and exact window incarnation. Read the separate
`control_result`/lossless `control_grant`, then recover the canonical token
with read-only status. Commands require the named full controller handle.
Use one immutable operation/deadline; recover the original result by status.
`applied` is an immutable original receipt, `current` is a separate live view.
`frameReady`/`action_frame_ready` require the matching real composed view.
Release the bounded grant when finished. A copied token grants no foreign
mutation or reap right. Launch receipt slots are one-based; native action GUI
indices are zero-based. The broker adapter performs this conversion.

The normal C/Zig paint path acknowledges only explicitly tagged delegated
views after successful frame commit. Ordinary FPS frames add no new RPC.
The existing Desktop mode RPC is replaced one-for-one by a640-byte envelope;
no extra permanent poll or worker. Native CPU KVM4 qualification includes
the same C child/window across all actions, actual pixels and PS2 input,
exact same persisted144-byte-token C/Rust/Zig readers, normal exit37 and a
separate native GUI-slot reuse case. Existing four owner cases cover quota,
deadlines and late immutable ACKs. First failed binding attempt is preserved.
See workspace `Docs/Desktop/DeskRun.txt` and `Core/0.88.98-window-actions`.
These are source candidates; published matching belongs to0.88.99/100.
No Studio0.8.3, native GPU, Windows, physical hardware or STANDARD claim.

Matched0.88 SDK delivery (01.11.2026)
------------------------------------------
SDK0.64.127 is matched to Contract0.64.68 and Libraries0.64.40 for the final
R4OS0.88.107 runtime. The source Contract pin is immutable. Public delivery
also requires the separately matched technical=false Linux/Windows host-tool
profile and the exact bare runtime objects; a source commit alone is not a
complete standalone SDK release. Brokered desktop evidence requires the
current WINSVC service; delegated window actions require WINSVC0.1.31 and
Desktop0.1.198. A missing/restarted broker or desktop yields the documented
unavailable/stale results, not an implicit platform ABI extension.
C, Zig and host Rust share the public observation/action contracts. Retain
an original launch token and epoch before submission, use status to resolve
an unknown result, and release independent evidence references explicitly.
See desktop_evidence, desktop_actions and Examples/DesktopEvidence.c.
The historical SNES Write and placement-wake investigations0.88.88/101 were
explicitly discarded by the user01.11.2026; their causes remain unknown.
Package validation does not imply a fix for these historical findings,
Windows execution, native Rust compilation or physical GPU/audio hardware.

SDK package interface (0.64.144)
-------------------------------
Tools/Package.ps1 -Action Describe reads the three original profiles without
a compiler. Manifest binds clean sources and matching assets; Verify checks
the downloaded/extracted set. This is derived schema1 metadata, not another
profile authority. Schema3 capabilities includes build_profiles,
component_sets and profile_sources. Generated project starters forward
LibrariesRoot, DevelopmentProfile and AdditionalLibrariesFile. Studio selects
the SDK/profile; Server serves the immutable matching original assets.

## Provider transport adapter

`r4os.network_transport` is a provider-only copied adapter for NetTcp/NetUdp
and their managed service brokers. It reuses the existing IPv6 packet/source/
route owner and ICMPv6 pseudoheader codec, and does not keep socket or routing
state. It requires whole optional PPI2 dispatch/link/process-status callbacks.
Public Query2 callers keep `network_family` in Zig/C/Rust; Accept success
returns a distinct child identity while WouldBlock retains the listener.
The normative lifetimes, finite budgets and limits are in
Contract/API/Ipv6Transport.txt. Existing application profiles stay unchanged.

## Optional PCM capture

SDK0.64.180 exposes copied AUDSVC capture clients in Zig, C and Rust. Use
`audio_capture` or `audio_capture_platform2.h` with explicit stream Stop/Close
and separate channel Disconnect. Final caller capacity, complete S16LE frames,
exact generations and the existing checked read budgets remain explicit.
Rust transport errors and the copied reply result are distinct. Uncertain
reads or mutations never authorize automatic replay or implicit resource release.

The infrastructure adapter and optional DriverApi2 tail share the original
service/R4D owners. Negotiate the whole optional pointer; the original656-byte
driver prefix remains valid. Contract/API/AudioCapture.txt defines the wire
and lifetime. CONTROLLED input is a fixture capability; shipped HDA/AC97
backends expose no qualified ADC. Application migration remains separate.
