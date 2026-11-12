R4NAK Runtime-R4L API
=====================

Freestanding Mesa SPIR-V/NIR/NAK compiler, executable byte cache and format helpers. Independent R4L, no host runtime and no GPU ownership.

COMPILER_V1
-----------

Runtime compiler and cache ABI1.

- ELF-Symbol: `r4nak_compiler_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x50494c4552303031:0x52344e414b434f4d`
- Tabellengroesse: 64 Byte

- Slot 0, Offset 32: `compile` - Run only on a disposable worker with at least1MB stack; panic/OOM/cancel terminates that worker after freeing its job allocations. Parent must join before touching or freeing buffers. No longjmp across Rust, no frame-path compilation.
  Semantik: may_block, thread_safe, not_reentrant; Fehlerdomaene `R4NAK_STATUS`; Besitz: Caller owns inputs, output and worker. Compilation holds one library-wide owner; contention returns busy without waiting. Cache and format functions retain nothing..
- Slot 1, Offset 40: `cache_write` - Serialize exact identity, metadata, shader header and code; no allocation or file access.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NAK_STATUS`; Besitz: Caller owns inputs, output and worker. Compilation holds one library-wide owner; contention returns busy without waiting. Cache and format functions retain nothing..
- Slot 2, Offset 48: `cache_read` - Incompatible or damaged cache returns cache_miss without modifying outputs; owner discards/recompiles the file. No GPU resource is resurrected.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NAK_STATUS`; Besitz: Caller owns inputs, output and worker. Compilation holds one library-wide owner; contention returns busy without waiting. Cache and format functions retain nothing..
- Slot 3, Offset 56: `format_info` - Query the pinned Mesa format table through stable R4GFX fourcc values.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NAK_STATUS`; Besitz: Caller owns inputs, output and worker. Compilation holds one library-wide owner; contention returns busy without waiting. Cache and format functions retain nothing..

Typen
-----

- `R4NakHeader`: 128 Byte, Alignment 4. Opaque 32-word native NAK program header; owned by output and included in executable cache integrity.
- `R4NakDigest`: 32 Byte, Alignment 8. SHA-256 stored as 32 little-endian bytes.
- `R4NakRuntime`: 72 Byte, Alignment 8. Version1 callbacks use C ABI. allocate(user,bytes,alignment)->u64, release(user,address,bytes,alignment), clock_ns(user)->u64 monotonic; abort_worker(user,status:i32) must terminate the current disposable worker without unwinding or returning. owner_retired(user,generation)->u32 returns1 only after that exact program generation is fully retired; unknown remains0. cancelled(user)->u32 is optional. Allocations belong to the caller program; callbacks and input live through worker retirement.
- `R4NakRequest`: 88 Byte, Alignment 8. SPIR-V words:5..16384, id bound1..16384, version1.0..1.6. Entry1..63 UTF-8 bytes. Budget includes tracking overhead and is1..256MB; zero deadline means no deadline. Caller-owned disjoint immutable input and writable code/log/result buffers. VS0, FS4, CS5 with stage I/O and local arithmetic/control flow. Resources requiring device/pipeline lowering return unsupported; GPU execution belongs to the driver.
- `R4NakBinary`: 232 Byte, Alignment 8. One CPU compilation result. Code is executable GPU machine code but never installed or submitted by this library. Source hash binds words, entry, stage and target. Status is readable only after the compiler worker joins; abnormal termination records a negative status then exits the worker.
- `R4NakCacheKey`: 136 Byte, Alignment 8. Exact caller device/driver/pipeline identity; nonzero driver/ABI/generations required, constantsABI4, vendor10de. Compiler/source-lock identity is appended by R4NAK, never supplied by caller. Cache data contains no GPU virtual addresses.
- `R4NakFormat`: 40 Byte, Alignment 4. Mesa format description for established R4GFX fourcc values. Format availability does not imply hardware support.

Besitzregeln
------------

- worker: Compiler calls run outside interactive frame paths on a dedicated worker. Return and abnormal exit both release compiler memory/owner; caller always joins. Whole-program forced exit uses exact program generation retirement before later jobs can reclaim a stale owner; never call old allocator callbacks after retirement.
- cache: Caller owns filesystem, file naming and atomic replacement. Cache functions are pure byte operations; caller discards misses and queues compilation. Payload SHA-256 detects accidental corruption; it is not a signature or trust boundary.
- fallback: R4NAK is optional. Missing library, busy worker, unsupported resources or failed compilation keeps the existing software renderer available.
