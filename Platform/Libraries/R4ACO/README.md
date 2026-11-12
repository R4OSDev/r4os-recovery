# R4ACO

R4ACO is the CPU shader compiler for Picasso gfx902 and Raven2 gfx909.
It links the real Mesa 26.2.2 SPIR-V frontend, NIR and ACO into R4ACO.R4L.
`INFO_V1:1` reports CPU compilation; `COMPILER_V1:1` compiles and serializes
shader caches. Physical device access belongs to AMDGPU.R4D. External ASIC revisions select the exact Mesa family; Raven2 omits the Raven LS-VGPR initialization workaround. Cache identity and generated metadata distinguish gfx902/909. The offline compiler accepts an optional final external-revision argument (for example 0x82); omitted means Picasso 0x41.

Build from Libraries with `./Build.sh R4ACO` or `Build.bat R4ACO`. Shared
PowerShell 7 orchestration reads the workspace Settings.R4S. It requires
Clang/LLVM 19.1.7, the bundled Zig 0.16.0 libc++ headers/sources, Python 3,
Mako and PyYAML. Tools/Build.ps1 verifies 621 unchanged Mesa files, the ordered
job-isolation patch and pinned runtime sources before generating and linking
373 compiler units plus 18 runtime/bridge units. Shared native math and scan
archives are separate dependencies. No ELF startup constructors are required.

Each compile runs in an exclusive, disposable worker with caller allocation,
clock, cancellation and retirement callbacks. Allocation graphs and emulated
TLS belong to the job. OOM, deadline and compiler abort release that graph
before terminating the worker; callers retain all storage until join.
Bindings/Zig/worker.zig supplies the R4SYS integration and atomic file-cache
helpers. `Worker.init2` uses actual generation2 system slots and the independent
`COMPILER_V1` binding; `Worker.init` explicitly supports applications awaiting
migration. The App/context and all worker storage must remain at stable
addresses until join. The common complete lightweight lifecycle reader grants
no retirement authority on partial, busy, restarted, invalid or over-capacity
snapshots. Program state `done=2` or coherent final absence is required; a close
request is insufficient. Full task/VM diagnostics are not used for membership.
Prepare shaders before rendering; never compile or join in a frame.

The compiler-typed C/Rust helpers provide `CompilerContext2.init` over the
actual Start2 record and `acoWorker`. The original owner constructs its Zig
App2 without reinterpreting a foreign App layout. Keep the context and start
record stable until every derived worker joins.

Native resource ABI 1 supports vertex pulling through buffers, one fragment
color output, compute, static shared memory, 16 buffer bindings and 256 bytes
of push constants. Stages are vertex 0, fragment 4 and compute 5, wave64.
The target is PCI 1002:15D8 with separately confirmed external ASIC revision
0x41..0x48. The `request_textures` flag selects resource ABI 2: the same
buffer table plus four combined 2D image/sampler records at byte 256,
64 bytes each. Direct set1 bindings support sampling, explicit LOD and texel
fetch. Arrays, MSAA, shadow, nonuniform descriptors, storage images and
broader Vulkan semantics remain outside this fixed renderer ABI.
Returned ACO symbols retain upstream semantics; constant-data offsets are
already resolved. GPU resource allocation and register encoding belong to
R4AMD and AMDGPU.

Caches bind original SPIR-V, compiler/toolchain identity, device/revision,
resource/command/driver ABI, pipeline and memory/reset epochs. Corruption
returns a cache miss. The compiler never accepts a caller-supplied compiler
identity and never reads environment-selected replacement shaders.

Normal Linux builds run real CPU compilation and failure/cache tests plus
C/Zig ABI conformance. Windows builds the same freestanding ELF runtime and
host ABI check; its CPU integration runs through the SMP4 guest probe.
`DISPLAYD /AMDCOMPILER` tests the loaded module, real R4SYS workers/clock,
six shader fixtures, including a real texture sample, OOM recovery and actual
atomic cache files.
Tests/Fixtures and Tools/ShaderFixtures.json preserve self-authored GLSL and
SPIR-V identities. Original GPU ISA is checked independently with LLVM's
gfx902 disassembler. None of these CPU checks executes an AMD GPU.

The optional `compiler` build step creates `zig-out/bin/r4aco-compiler` on
Linux. It uses the same bounded worker/runtime to prepare the six immutable
R4AMD render profiles from self-authored GLSL/SPIR-V. R4AMD/Tools/Shaders.ps1
checks source, code and metadata hashes and compiles twice during regeneration.
Normal driver builds consume the verified programs; frames never compile.

Sources and licenses are pinned in ThirdParty/Sources.json and
Tools/CppSources.json. Tools/ExportLegal.ps1 collects original notices,
libc++, stb and shared math/scan terms for distribution.
`IMAGE_SCOPE=none` remains until package integration. Further details are in
Docs/Drivers/AMDShaderCompiler08013.txt in the workspace and Docs/API.md here.

Original R4OS code: Apache License 2.0. Third-party material retains its
own license; see the repository THIRD_PARTY_NOTICES.md.
