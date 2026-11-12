# R4NAK runtime compiler

R4NAK.R4L translates caller-provided SPIR-V through pinned Mesa 26.2.2
NIR and NAK into NVIDIA machine code. It runs on R4OS, independently of R4NV's
nine fixed shader profiles. Its `COMPILER_V1` contract, generated C/Zig
bindings and ABI baseline are owned by this unit.

## Build

From the workspace, use `Repositories\Libraries\Build.bat R4NAK` on Windows
or `./Repositories/Libraries/Build.sh R4NAK` on Linux. Both run the same PS7
recipe. Paths are derived from the scripts and Libraries `Settings.R4S`;
the working directory is irrelevant. Use the workspace starter, which selects
the matching Contract and SDK through the normal dependency forks.

The native compiler requires the pinned tools documented in
`../R4NV/Tools/Compiler/README.md`: Rust 1.85.1, Clang/libclang 19.1.7,
bindgen 0.71.1, cbindgen 0.27.0, Meson 1.7.0, Ninja 1.12.1, Python and its
Mesa generator dependencies. Windows additionally requires the native x64
Rust/MSVC/Windows SDK environment, `clang.exe` and `clang-cl.exe` on PATH.
PowerShell 7, Git, curl, tar/xz and the workspace Zig toolchain are required.
The Windows execution proof is pending; it is not inferred from Linux.

`Tools/Build.sh -Offline` or `Tools\Build.bat -Offline` prepares only the
native archive, without network access. Its `-OutputFile` is optional and
workspace-relative; `-Rebuild` rebuilds the selected private cache directory.
The regular library build accepts `R4NAK -Doffline=true` and adds the Zig
provider, contract checks and R4M0 container. The flag reaches the same native
source owner; a missing source archive fails instead of starting a download.
A cached build verifies the recipe, host tool versions and archive
hash. Initial source preparation reuses the verified Mesa host-build owner.

The source closure combines the existing Mesa/six-crate lock with
`Tools/Sources.lock.json`: official Rust sources, compiler_builtins,
hashbrown without optional features, and the pinned stb_sprintf header.
No Cargo download or system Rust standard library enters the target.
Generated C/Rust bindings use the explicit R4OS target ABI on both hosts.
Original sources, overlays, generated bindings and objects are separate under
`DevKit/Toolchains/R4NAK/<recipe-hash>`; `build.json` records inputs, sizes,
timing and the archive hash. These files are build products, not sources.

## Runtime ownership

`Bindings/Zig/worker.zig` supplies a consumer-owned asynchronous worker using
R4SYS thread handles, program generations, allocation, monotonic time and
atomic file replacement. `Worker.init2` resolves the actual generation2 system
slots and independent `COMPILER_V1` binding from an `App2`. `Worker.init` is the
explicit transitional entry for generation1 applications. Both use the SDK's
complete lightweight lifecycle reader: busy, restart, invalid, partial or
over-capacity snapshots never authorize stale-owner reclamation. A close
request is insufficient; only program state `done=2` or absence from a fully
validated snapshot proves retirement. No full task/VM diagnostic scan is used.

Keep the App/context, worker, request, source, code and log at
stable addresses until `join` succeeds. Never compile or wait in a frame
callback. Contention for the library-wide compiler owner returns `busy`.

All native allocations, including persistent Mesa type tables, belong to one
bounded job arena. Success frees its entire arena. OOM, panic, cooperative
cancellation or an expired deadline frees it and terminates the disposable
worker; C/Rust frames are never resumed or unwound across the language
boundary. A timeout does not permit early release of caller storage. Close
requests propagate as cancellation. After whole-program forced retirement,
a new caller can reclaim a stale owner only with a coherent proof that its
exact program generation is fully retired; old callbacks are never invoked.

The compiler-typed C/Rust helper boundary exposes `CompilerContext2.init`
over the real Start2 record and its `nakWorker` constructor. The bridge
constructs the private Zig App2; foreign App layouts are never cast to it.
Keep that context and its start record stable until every worker joins.

The linked target uses freestanding Rust core/alloc/compiler_builtins and a
small serial C/Rust runtime, without Linux, host libc, TLS, files, dynamic
linker or a Rust std dependency. Static large-model native objects use R4M0
absolute relocations; the existing module loader remains unchanged. This
compiler uses one worker at a time; the OS and tests still run with SMP4.

## ABI1 scope

Supported targets are SM75, SM86, SM89 and SM120, with vertex, fragment and
compute stages. Requests contain SPIR-V 1.0–1.6, at most 16,384 words/IDs,
an entry name of at most 63 bytes, an explicit memory budget up to 256 MB,
optional deadline/cancellation, and caller-owned code/log buffers. Code is
bounded to 16 MB; logs to 1 MB. Invalid and overlapping buffers are rejected.

ABI1 implements stage I/O and local arithmetic/control flow. Descriptor,
push-constant, shared-memory and external-resource lowering belongs to the
Vulkan pipeline work in 0.79.35/36 and is explicitly unsupported here.
Successful compilation supplies code and the NAK header; it does not allocate
GPU resources, submit commands, prove physical shader execution or advertise
Vulkan conformance. Seven format queries describe the established R4GFX
fourcc formats using Mesa's format table, independently of device support.

The little-endian executable byte cache contains a 464-byte header and code,
bound to source/pipeline hashes, compiler revision, GPU/chipset/SM, driver,
command/resource/constants ABIs, format, pipeline layout and device/reset
generations. SHA-256 covers metadata and code. Incompatible or corrupt entries
are misses with unchanged outputs. Transient timing/heap/log values are not
cached. The optional disk adapter publishes through private staging/backup
names and atomic replacement. The renderer must recreate and own GPU
resources; cache bytes never resurrect handles. Bump `compiler_revision`
and the compiler fingerprint whenever a released lowering/runtime changes.

## Validation and licensing

The normal build runs one generated C/Zig ABI conformance case.
`DISPLAYD /COMPILER` exercises runtime compilation, changed input, four target
hashes, worker OOM recovery, deadline, malformed/aliased input, executable
cache identity/integrity, atomic file publication and format queries. It
performs CPU work and temporary cache I/O only, with no GPU access. The
targeted SMP4 report is `Docs/Drivers/GrafikCompiler07934.json` in the workspace.
The native Windows-host qualification remains 0.82.38/T15. The shared PS7
build, package and SMP4 replay is documented in
`Docs/Deployment/GrafikFreigabe07945.txt` in the workspace. Physical NVIDIA
execution has separate, version-bound evidence from 0.82.10; the compiler
guest alone does not establish it.

Original R4OS glue is Apache-2.0. Upstream code retains its original terms.
`ThirdParty/NOTICES.txt` contains the complete collected notices;
`ThirdParty/notices.json` identifies their source files and hashes. The same
notice file is installed as `R4OS/LICENSES/R4NAK-NOTICES.txt`. See the parent
repository's `THIRD_PARTY_NOTICES.md` and both source locks for provenance.
