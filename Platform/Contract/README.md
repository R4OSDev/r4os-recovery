# R4OS Platform Contract

This repository is the canonical API and ABI definition for the R4OS platform.
It contains the R4M0 container contract, shared layouts and error codes,
platform API groups, generated bindings, conformance fixtures, and the
contract generator.

The active platform contract is generation 2. `API/ApiContract.json` owns all
533 slots, their signatures and semantics, `Query2:2` and `R4XStart2:2`.
`API/Generation2.json` independently describes the driver, protocol and audio
records, typed callbacks and SDK selection. Current tables and technical
records are emitted directly; they do not compact or copy an older ABI.

The accepted baselines cover both canonical files. During the planned
provider cutover, `API/LegacyProjection.json` contains only the four inert
historical holes and reverse header metadata. The generator derives that
temporary compatibility view from the active slots. Independent Runtime-R4L
interfaces and shared payload revisions keep their own contracts.

R4AUDIO v3 (Contract0.64.51, 0.87.53) appends stream progress, explicit
continuous-source expectation and close-with-progress after the unchanged
200-byte prefix (total224). Its original23 slots, including both tombstones,
are preserved. Nine separate fixed v1 records carry bounded playback and
AUDSVC transport receipts; existing payloads and constants are unchanged.
The optional R4D playback descriptor v5 preserves the 104-byte idle prefix
and appends atomic tracked acceptance, cursor and flow callbacks (total128).
Canonical frames mean 48-kHz stereo S16 PCM. Acceptance, DMA submission,
validated DMA consumption and reset-unconfirmed tail are distinct quantities;
none is a receipt for a speaker. Backend registration, output/reset epoch,
kernel stream generation and service/logical stream generation bind each
observation to its owner. Repeated reads never extend a source deadline.

Contract0.64.66 extends the retired audio-duration contract to AUDSVC.
From AUDSVC0.1.22, `AudioServiceStatus` and `AudioServiceStreamResult` set
`audio_service_flag_duration_unavailable`; all six status and both result
request/write duration fields equal `audio_duration_ticks_unavailable`.
Exclude these values from arithmetic. Historical providers without the flag
retain their original measured values. Record versions, sizes, offsets and
all existing flag values stay unchanged. The actual 500 ms Close deadline,
selection thread Join, PCM work and error/progress counters remain active.

Contract0.64.61 retires the unused audio write/refill duration collection.
All nine `ProgramPerformanceSummary` duration fields and all six
`AudioBackendStatus` duration fields retain their names, offsets and layouts.
Current providers return `audio_duration_ticks_unavailable` (`UINT64_MAX`)
and clear `performance_flag_audio_latency_ready`. This is unavailable data;
exclude it from arithmetic, latency displays and scores. Historical exports
keep their actual values. No diagnostic window remains active or can enable
this retired collection. Accepted PCM, DMA progress, functional deadlines,
worker completion, errors and drain receipts keep their existing contracts.

R4DEV35 (Contract0.64.45, 0.86.80) retires V1 diagnostic slots27/29/30
in place as zero tombstones. Current storage/registry V2 slots, table size728,
all other offsets and current payload layouts remain unchanged. The unused
V1 registry records are removed; there is no old OS runtime projection.
Graphics requests use complete current records: registration48, backend152,
submission512, driver job296, color192 and buffer statistics136 bytes.
Short headers are refused without taking jobs, publishing data or writing
beyond the caller's actual capacity. Optional current capabilities remain
explicit; hardware generations and data formats are independent of OS age.

R4DEV v17 appends `smp_kernel_check` and `performance_smp_tlb` after the
preserved 416-byte prefix (total432). Fixed v1 payloads separately expose
explicit owned functional SMP work (224bytes) and passive remote-TLB/clock
facts (184bytes). Exact own task/ACK/backing receipts determine success;
global timeout injection remains isolated. Existing slots, layouts and
constants are preserved.

Optional Runtime-R4L APIs are intentionally not defined here; each independent
library owns its own contract and bindings.

R4DEV v29 appends the passive 192-byte `CpuIdleInfo` receipt. Separate
`CpuIdleDescriptor` and `CpuIdlePolicy` records extend the optional driver CPU
mechanism to184 bytes. ACPI declarations and software entry attempts are
distinct from unavailable physical residency, wake-latency and energy data.
Every previous fixed record, table prefix and callback meaning is preserved.

## Build and validation

Use the repository starter with the workspace toolchain:

    ./Build.sh test      # Linux
    Build.bat test       # Windows

Both delegate to the SDK-owned PowerShell host launcher and the pinned
workspace toolchain.

Generated files are checked during normal builds. Intentional contract changes
must use the repository's explicit generator write workflow and update the
matching baseline.

`Generated/SDK/Rust/` is the standalone `no_std` Rust projection of the same
canonical platform and technical ABI. `write` generates Zig/C first, then
reflects their current typed definitions into Rust. Normal builds and `check`
compare Rust output without writing it; `test` also compiles both Rust targets
and runs the existing Contract gate with a native Rust/Zig/C callback fixture.
Use the pinned workspace Rust launcher; standalone tests require Rust 1.99.0.
See `Generated/Inventory/RustABI.json` and the workspace guide
`Docs/API/RustContractBindings.txt`. Binding generation preserves the platform
API versions, slot numbers and canonical schema/baseline.

The C header also includes `abi_technical_generated.h`, reflected by the same
tool from the append-only technical Zig types. This adds the previously missing
driver/protocol/DMA/USB and service payload declarations without copying their
schema. All wire enums use their exact integer width, including the corrected
8-bit `R4AppProfile` and 16-bit `R4ErrorDomain` C typedefs. Use these typedefs,
not C enum tags. Existing enumerator names/values remain available; additional
typed technical enum constants use `R4ABI_`. C keyword fields have a trailing
underscore (`register_`). Normal `write`/`check` covers this header as well.

Contract0.64.55 also reflects the existing `GuiWindowFlag` namespace as
`R4ABI_GUI_WINDOW_FLAG_VISIBLE`, `...MINIMIZED`, `...MAXIMIZED` and
`...CLOSE_REQUESTED`. The generator reads the canonical declarations; no wire
value, payload layout or provider slot changes. Raw focus and font event kinds
already exist as `R4ABI_GUI_EVENT_KIND_FOCUS_GAINED`, `...FOCUS_LOST` and
`...FONT_CHANGED`.

The technical `DriverApi` facade lives outside the marked generated exports
block in `Generated/SDK/Zig/abi.zig`; the generator preserves that area.
DriverApi34 appends two optional DMA range-sync callbacks after the unchanged
632-byte v33 prefix (total 648). `ABI/R4DDriver.txt` defines their ownership,
bounds and ordering; SDK conformance and the kernel enforce the layout.

Detailed German migration notes are preserved in
`DOCUMENTATION.de.txt`.

DriverApi v24 and NetBackend v2 provide append-only network capability
selection. Every packet descriptor retains canonical flat fallback bytes;
the current single-queue implementation admits only validated RX TCP/UDP
checksums and rejects all other optional offloads explicitly.

## License

Original R4OS material is licensed under Apache License 2.0. See `LICENSE`,
`NOTICE`, and `THIRD_PARTY_NOTICES.md`.

Kernel provider builders follow the canonical `required` flag: required
callbacks must be supplied, while optional callbacks default to null and
produce a zero capability slot. The table layout and Query import stay
unchanged when a provider omits a capability.

GPU telemetry identifies one exact adapter and memory generation. A surviving
driver advances its memory generation monotonically after a GPU reset. The
common cache accepts that newer epoch, discards the old demand and rejects
older publications or queries. Fault handling publishes unavailable metrics
without reading the device; cached measurements are not reset evidence.

The optional `GfxDriverMemoryApi.device_lost` slot at byte200 extends the table
to208 bytes; its wire version remains1 and every old slot keeps its offset.
The exact driver invalidates native BOs for one adapter and memory epoch.
Logical loss rejects new uses but retains DMA. An independently proven stop
then allows physical backing release once all device/queue leases end, even
while applications retain invalid handles that they can still close. CPU BOs
and newer generations are unaffected. This metadata call neither resets the
GPU nor confirms restoration of the boot framebuffer. The baseline change
also updates the default caller capacity and documents this release rule;
it does not change the layout of release tickets or the outer DriverApi.

The optional display reset pair extends `GfxDriverDisplayApi` from120 to136
bytes without changing wire version1 or the prefix. `device_reset` at120
invalidates one exact display/backend generation; a separate proven-stop
call retires its queue, mode, cursor and additional-output consumers. The
original boot hold remains sealed. `prepare_reset` at128 admits a strictly
newer queue generation and creates a fresh native display generation; it
does not reuse the immutable boot-hold ID or grant access to bootfb. Both
callbacks are required for this capability. Only the existing physical
restore callback can authorize restoration of the held boot framebuffer.

The 0.79.37 `WindowGraphics*` payloads add four userland WINSVC operations
for common GPU-window publication, producer/consumer leases and finite
change waits. Consumer fence acknowledgements add two constants without
changing payload layouts. R4DESK v15 appends the optional
`desktop_activity_notify` slot; all old function slots are unchanged.
Opaque color bytes carry the existing R4GFX
description; they do not add kernel color or window-presentation policy.
The service implementation is available; Desktop and Vulkan WSI consumers
are still being integrated.

R4DEV v18 appends `storage_block_queue_check` at offset432 after the unchanged
432-byte prefix. `ProgramKernelBlockQueueCheck` v1 is fixed240bytes. It reports
only its own synthetic cases, exact request/task/device receipts and retained
resources; no global queue reset, physical test disk or separate score.

R4DEV v19 appends `storage_nvme_check` at offset440 after the unchanged
440-byte prefix; its fixed v1 report is296bytes. The optional technical
`StorageObservedRequest` is80bytes and retains the complete56-byte
`StorageRequest` prefix. Only the observation flag and an advertised backend
capability select it. Its synchronous104-byte callback record identifies the
actual CQE, IRQ-driven worker and acknowledged DMA release before logical
completion. Normal56-byte requests and their callbacks remain unchanged.

R4DEV v20 appends `usb_contract_check` at offset448 after the unchanged
448-byte layout prefix. Its fixed32-byte v1 report covers the existing local
ring-cycle and event-router cases. It is bounded and reentrant, borrows only
caller output and touches no live USB controller, mailbox or hardware.

SerialLink retirement (0.84.34 / package0.64.20)
--------------------------------------------
R4NET slots27-31 and all published names/signatures/payload layouts remain
frozen. These five compatibility stubs always return err_no_fn and touch no
buffer, UART, loader or work queue. SerialLink runtime/modules/SDK facades are
removed. A table pointer does not imply that the retired transport is available.
Only the five descriptions changed in the controlled documentation baseline;
all other schema values and generated Zig/C/Rust bindings are byte-identical.

Machine Check receipts (0.64.34 / 0.85.32)
----------------------------------------
R4DEV30 appends passive `cpu_machine_info` and `cpu_machine_bank` after its
unchanged656-byte prefix (complete table672bytes). Independent fixed144-byte
`CpuMachineInfo` and112-byte `CpuMachineBank` distinguish retained boot-passive
scans from terminal #MC captures. Bank copies require exact CPU/original epoch/
capture sequence; refusal/end leaves output and tails unchanged. Actual bank
count, read faults, truncation, status validity and changed readbacks remain
explicit. No query runs CPU instructions, callbacks, recovery or status clears.
Existing CrashReport, DriverApi37, DriverCpuPowerApi184 and R4SYS27 stay fixed.
CPUPOWER's appended model-support flags describe documented decode profiles,
without claiming actual bank presence, enabled reporting or current health.

Early microcode receipt (0.64.35 / 0.85.33)
------------------------------------------
R4DEV31 appends copy-only `cpu_microcode_info` at slot82/offset672, complete
table680bytes. Independent fixed144-byte `CpuMicrocodeInfo` keeps actual
revision read validity, exact initial CPU/platform/package identity, virtual
origin, firmware prerequisites and update/readback failure distinct. Initial
boot loading remains an internal necessary CPU owner operation; no public
reload or arbitrary data/register endpoint is added. Logical CPU restart
requalifies without applying updates while consumers exist. Diagnostic finite
CPUID fingerprints do not replace feature or PAT/FPU admission. All preceding
fixed records/constants/slots, DriverApi37, CPUPOWER184 and R4SYS27 are unchanged.

Optional CPU work window (0.64.37 / 0.85.35)
-------------------------------------------
R4DEV33 appends passive `cpu_acceleration_info` and bounded
`cpu_acceleration_work` after the original704-byte prefix, complete720.
Independent128-byte records distinguish cached feature/OS facts, universally
valid REP performance hints, and an exact local baseline/SHA callback window.
Only a qualified resident callback may execute optional SHA; cached dispatch
alone does not survive CPU migration. Task/lifecycle ownership, actual IF
restoration and hardware-clock acceptance remain separate receipt flags.
`CpuPureWorkFn` is borrowed through a typed nullable slot pointer. The original
88-byte/version1 ProtocolApi gains two typed nullable tail fields, complete104;
old size/null providers retain their fallback. Six optional feature IDs append
after the existing55; the common AVX2 compiler baseline stays unchanged.
No memory/hash algorithm, SIMD instruction, PMU programming or arbitrary
feature-mask interface is added to the kernel contract.

0.64.38 appends the optional registered-device entropy contract. R4SYS28/1304
retains its complete1288-byte prefix. DriverResourceApi1/72 retains every
32/48/56/64-byte prefix and outer DriverApi37; its source table is cached
before shutdown. ProtocolApi1/120 retains104 bytes and its original88-byte
prefix, with independently size-checked typed nullable source functions.
Fixed128-byte source/completion receipts, a64-byte backend and32-byte driver
table distinguish registration, exact module/driver epoch, real used bytes,
bounded work and retained DMA. No random-value or timing-quality estimate.
RDRAND is a new named pure CPU-window kind2/mask64; existing payloads, kinds,
feature IDs, AVX2 baseline and XSTATE stay unchanged. Fresh exact local CPU/OS
admission and CF checks remain mandatory. The SDK owns source choice; the
external driver owns transport/completion/reset. No Runtime or Rust mutable
registry borrow spans callbacks; release the driver owner before a paged
caller copy while retaining the exact task. Old/missing sources fail safely.

0.64.48 appends optional R4SYS30 `drive_info_geometry` at1320 (table1328),
retaining all163 original slots and the complete1320-byte prefix; Query:1
and the other five groups stay unchanged. DriveInfo remains56 bytes. Its
reserved bit0, `drive_info_flag_free_valid`, distinguishes backend-provided
FREE values (including zero) from unknown. The geometry call never executes
FREE or reads a free-space bitmap. Existing exact mounted request admission
remains and may wait; this is no unconditional nonblocking guarantee. The
full call retains the existing FREE backend/cache and marks only valid FREE
results. The old full-call nonblocking annotation is corrected to may_block.
Source/layout prefix proof and generated Zig/C/Rust conformance pass; no new
physical timing, cache invalidation, mount lifecycle or hardware claim.

0.64.56 appends R4SYS32 observation retain/wait/read/release at1336..1360
(table1368), preserving the old165 slots and1336-byte prefix. A24-byte
ProgramObservationHandle binds a separate reference to one exact process
generation. Bind while its completion still exists; an existing binding
survives the consuming owner's reap. Default bindings end with their
creator generation; explicit portable bindings require release or boot end.
Only terminal metadata and an inactive bounded transcript survive: no task,
VM, module, live console or GUI resource. OutputAvailable includes captured
empty output; OutputTruncated/OutputIncomplete distinguish missing bytes.
The previous process wait/reap contract remains consuming and unchanged.
# Audio output catalog (0.64.60)

R4AUDIO v4 appends `audio_output_catalog` at offset224; its complete table is
232 bytes. The preceding224-byte table and scalar `audio_output_info` stay
unchanged. Supply256 caller-owned `AudioOutputInfo` rows and a disjoint
v1/224-byte `AudioOutputCatalog`. Result1 publishes the complete copied rows
and exact registry/provider witnesses. Discard scratch rows on any failure;
the receipt stays unchanged. Busy never confirms cached availability.

DriverApi v39 appends `register_audio_output_epoch`. Bind it once, after the
structured backend, from the same R4D owner. Its synchronous callback returns
a real, nonreused publication generation, count and active index under the
provider's row owner. Transitions/exhaustion return Busy. Old providers retain
scalar enumeration; a complete capture reports unsupported if any participating
provider lacks this contract. No implicit fallback invents a generation.
Catalog observations are separate from physical route, ELD, Stop and playback
acknowledgements. AUDSVC binds its copied pages to service epoch and revision.

Contract0.64.67 adds the fixed WINSVC evidence handoffV1 service payloads
DesktopEvidenceToken128 / DesktopEvidenceRequest136 / DesktopEvidenceReply288
and the desktop_evidence operation/state/result constants. These are opaque
service messages carried by the existing Service API. The six platform
function tables and all prior payload layouts remain unchanged. A controlled
append-only baseline update records the new public types; generated Zig/C/Rust
layouts and existing callback interop pass. Candidate desktop-native and final
SDK/OS qualification are tracked separately in R4OS0.88.97/99/100.

Contract0.64.70 adds the WINSVC focus observation records
DesktopFocusSnapshot112, DesktopFocusReply120 and
DesktopWindowExchangeV2=752 bytes. The latter appends a focus observation to
the existing 640-byte window exchange; existing service operations and all
platform slots remain unchanged. Technical service values 4808/4809 and
pointer kinds 4/5/6 are append-only. The snapshot carries exact window and
process generation, view/input revisions, observation tick, focus and
visible/minimized flags. WINSVC authenticates own-window reads; no focus
setter or global controller authority is introduced.
