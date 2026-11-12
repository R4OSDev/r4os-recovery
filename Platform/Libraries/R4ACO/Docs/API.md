R4ACO Runtime-R4L API
=====================

Pinned Mesa26.2.2 SPIR-V/NIR/ACO compiler and cache for Picasso gfx902 and Raven2 gfx909, with bounded isolated jobs. CPU compilation never admits a GPU.

INFO_V1
-------

Independent immutable library identity, append-only interface.

- ELF-Symbol: `r4aco_info_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f53:0x41434f31`
- Tabellengroesse: 40 Byte

- Slot 0, Offset 32: `get_info` - Return source/build identity. Capability bit0 reports CPU shader compilation only. Source compatibility and compiler availability never admit a physical GPU.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4ACO_STATUS`; Besitz: No retained memory, allocation, hardware access or shared mutable state..

COMPILER_V1
-----------

Pinned Mesa26.2.2 SPIR-V/NIR/ACO for Picasso/Raven2 native buffer ABI1 and combined 2D texture ABI2. Vertex, fragment, compute. CPU compilation only.

- ELF-Symbol: `r4aco_compiler_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f53:0x41434f32`
- Tabellengroesse: 56 Byte

- Slot 0, Offset 32: `compile` - Blocking CPU compilation exclusively on an isolated worker, never a frame/paint/IRQ callback. Busy returns immediately. Abort/OOM discards the entire private compilation allocation graph and terminates that worker; joining remains the caller's responsibility.
  Semantik: blocking, thread_safe, not_reentrant; Fehlerdomaene `R4ACO_STATUS`; Besitz: Caller-owned inputs and buffers stay alive through worker join. The library retains no pointer after normal completion or its abort callback. All callbacks belong to the admitted job..
- Slot 1, Offset 40: `cache_write` - Serialize explicit little-endian scalar metadata and original ACO output into caller storage; checksummed and compiler-bound. No filesystem access. Outputs unchanged on error.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4ACO_STATUS`; Besitz: No retained pointers, allocation, filesystem or device access..
- Slot 2, Offset 48: `cache_read` - Validate the complete cache identity, metadata and digest before publishing any code. Corruption, old compiler, wrong ASIC/layout/epoch are cache misses; never GPU submissions.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4ACO_STATUS`; Besitz: No retained pointers, allocation, filesystem or device access..

Typen
-----

- `R4AcoInfo`: 32 Byte, Alignment 4. Fixed ABI1 source/build identity, not a measured hardware profile.
- `R4AcoDigest`: 32 Byte, Alignment 8. SHA-256 bytes, no host pointer or padding.
- `R4AcoRuntime`: 72 Byte, Alignment 8. Callbacks are borrowed for the entire compile. One isolated SIMD-capable worker; abort_worker must terminate it without unwinding or returning. owner_retired must prove exact program retirement before replacing a previous owner. Callbacks use the x86_64 C ABI; alloc(user,bytes,alignment)->address; release(user,address,bytes,alignment); clock(user)->ns; abort(user,status); retired(user,generation)->0/1; cancelled(user)->0/1.
- `R4AcoRequest`: 88 Byte, Alignment 8. 1002:15D8, external ASIC revision 0x41..0x48 selects Picasso gfx902; 0x81..0x88 selects Raven2 gfx909. Both use GFX9 wave64; native ACO receives the exact Mesa family and compiler errata. Cache keys and returned gfx_profile distinguish the families. Flags0 selects buffer resource ABI1; request_textures selects ABI2 with four combined 2D textures in set1. Other flags rejected. SPIR-V<=65536 bytes, entry1..63 UTF-8 bytes; budget1..256MB; code<=16MB, log<=1MB. All input/output spans disjoint. Deadline uses caller clock; allocation/pass checkpoints cooperate with cancellation; parent retains worker and buffers until join.
- `R4AcoSymbols`: 256 Byte, Alignment 8. At most32 original ACO symbols, low32 kind and high32 code DWORD offset. Kinds1/2 identify scratch descriptor address words when present. Kind3 annotates a PC-relative constant-data offset already resolved by ACO fix_constaddrs; consumers MUST NOT add the load address again.
- `R4AcoBinary`: 424 Byte, Alignment 8. Actual ACO code/configuration and complete bounded fixup list. No BO, GPU address or hardware capability. rsrc registers are encoded by R4AMD from this configuration. Failed compile initializes status/log only; code and successful metadata become valid only on status0.
- `R4AcoCacheKey`: 136 Byte, Alignment 8. Exact compiler/profile/ASIC/driver/command/resource/pipeline/generation identity. Compiler identity is embedded and verified by the cache implementation; no user-provided compiler digest is trusted.

Besitzregeln
------------

- hardware: Only AMDGPU.R4D owns hardware. The foundation interface touches no device.
- provider: Table pointers live for the loaded provider generation. No pointer is retained from the caller.
