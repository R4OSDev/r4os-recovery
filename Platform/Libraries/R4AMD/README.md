# R4AMD

R4AMD owns AMD image geometry, descriptors and command encoders.
`INFO_V1:1` and `BACKEND_V1:4` retain their layouts and slots; `IMAGE_V1:1`
provides stateless image layout, address, metadata, import and descriptor
calls. `RENDER_V1:1` provides six actual ACO shader roles per ASIC profile and transactional
GFX9 pipeline/direct/indexed draw encoding.
AMDGPU.R4D owns devices and publishes measured architecture and memory
versions through the common graphics backend properties.

Generation2 consumers resolve the generated clients with `init2` and the
library's `Query2` descriptor. Its independent tables, generated shader bytes
and device identities keep their existing revisions. Caller scratch belongs
to each call; this provider needs no platform table, process inventory or
additional worker/heap owner.

GC9 ACQUIRE_MEM uses a 40-bit size in 256-byte blocks: the high size word
contains only eight implemented bits. The PM4 encoder clears its reserved
upper bits for both graphics and compute queues. Hardware completion remains
the driver's responsibility; an encoded packet is not an execution receipt.

The R4L links all sixteen original Mesa 26.2.2 AddrLib translation units,
including factory dependencies, plus three private R4OS C++ bridges. Runtime
admission pairs 1002:15D8 with Picasso GC9.1/SDMA4.1.0 (gfx902) or
Raven2 GC9.2.2/SDMA4.1.1 (gfx909). External revision and image/render
profile must match. Shader IDs0..5 retain Picasso; IDs6..11 are Raven2. No AddrLib or C++ type
crosses the fixed Zig/C interface. Each call constructs and destroys AddrLib
in disjoint caller scratch (16-byte aligned, at most 64 KB). No heap, TLS,
OS allocator, exceptions or RTTI is required. The pure-virtual failure
helper traps; memory operations use the compiler runtime. Outputs are
unchanged on errors.

Images support bounded linear/tiled surfaces, mips, arrays, volumes, MSAA,
selected color/depth/BC formats and real Addr2 coordinate calculations.
Size, pitch, alignment and topology are checked before import. GFX9 texture,
sampler and color state follows original Mesa descriptors and generated
register masks. DCC/HTILE queries describe geometry only: compression stays
disabled and unknown/compressed modifiers cannot be imported as linear.
Scanout admission uses the DCN1 32-bit standard-swizzle restrictions.
See workspace Docs/Drivers/AMDImageLayouts08012.txt for limits and units.

Source/copy.zig and Source/pm4.zig remain shared with AMDGPU. They emit
bounded SDMA linear/row/fill commands and GFX9 PM4 frames, with exact fences
and the GFX9 EOP workaround. Encoder flags 27 do not advertise tiled copies,
render execution, Vulkan, media or a compute-language runtime. The separate
render owner provides one color target, vertex pulling, sampling, blending,
depth/stencil and bounded raster state. Native GPU capabilities require
confirmed driver prerequisites; physical laptop validation is in 0.80.39.

The shared driver provider translates up to sixteen common render commands
into genuine PM4 plus 4 KB of job parameters. R8 text masks, premultiplied
alpha, nearest/bilinear scaling, affine grids and the common color program
use immutable shaders and retained native BOs. NV12, P010 and YUV420P use
integer plane fetches, explicit range/matrix/transfer conversion and a
504-byte native queue description. The canonical queue uses BACKEND_V1's
profile identity/revision 1; this is separate from the R4L table revision.
Linear aligned video planes are supported; tiled YUV, compressed images,
dual-source blending, MRT and arbitrary Vulkan pipelines are not advertised.

Source/Shaders and Source/Generated/Shaders preserve GLSL, SPIR-V, genuine
R4ACO machine code and reproducibility hashes. Tools/Shaders.ps1 validates
them during each native build. Its explicit `-Write` mode regenerates with
glslang 15.2.0 and the pinned R4ACO offline compiler, twice per profile.
AMDGPU statically links the same image/render archive through the SDK's
Zig R4D NATIVE_ARCHIVE path; no loaded R4L is required in driver startup.

Build with ./Build.sh R4AMD or Build.bat R4AMD from Libraries. Both use
PowerShell 7 and workspace-relative Settings.R4S paths. The normal build
checks source/patch hashes, compiles the genuine C++ closure, creates
runtime/host archives, checks C/Zig ABI conformance and exercises the linked
library on the host. Linux uses ELF; Windows also builds COFF objects for
host tests. The Windows path is implemented but not yet tested.

Clang/LLVM 19.1.7, Python 3 and configured Zig 0.16.0 headers are required.
Shared/Native/BuildPortability.ps1 isolates output by module/host/version
under Artifacts/Native. portability.json records object hashes and inputs;
the native archive manifest records archive hashes. No prepared NAK/NVK
source or cache is reused. DISPLAYD /AMDIMAGE checks the loaded R4L on the
CPU, including C++ vtables/relocations, without GPU access. `/AMDRENDER`
checks loaded shader bytes, native pipeline/draw calls and failure output
integrity. IMAGE_SCOPE=none
keeps the provider out of ordinary profiles until its consumers are ready.

ThirdParty/Sources.json pins 80 original files and the release patch
avoiding unused POSIX signal.h when DEBUG=0. Original bytes stay unchanged.
Adapted Mesa code retains MIT notices; original R4OS code is Apache-2.0.
Tools/ExportLegal.ps1 exports all compiled AddrLib and image/encoder notices
plus the complete MIT grant to the distribution.

The 0.80.23 contract additionally defines the 240-byte R4AmdDeviceFacts,
32-byte R4AmdNativeSubmit and 16-byte R4AmdNativeIb wire types. Existing
types, interface layouts and the R4AMD 0.1.5 runtime are unchanged. Backend
properties revision 2 is distinct from the IMAGE_V1 library revision and
retains the 64-byte R4AmdArchitecture prefix. Native driver profile/commands
keep revision 1 and distinguish PM4 from legacy YUV by exact payload length.

The 0.80.25 additive R4AmdDeviceFactsV3 type has a 256-byte wire layout: the
unchanged 240-byte facts prefix plus timestamp clock in kHz (zero if unknown),
native root-binding capacity and maximum backing bytes including SMEM padding.
Backend-properties revision 3 is separate from every function-table revision.
No existing type or runtime slot changes; that earlier metadata-only step kept R4AMD at 0.1.5.

## VCN1 source-profile contract (0.80.28)

R4AMD 0.1.6 appends media_caps to BACKEND_V1 revision 4, preserving the
existing slots. The exact Picasso/GC9.1/VCN1/firmware profile defines H.264,
HEVC Main/Main10, VP9 profiles 0/2, MPEG2, VC1 and baseline JPEG decode
eligibility, plus H.264/HEVC 8-bit encode eligibility. No AV1, MPEG4 Part 2
or HEVC Main10 encode is admitted. Flags explicitly identify source-profile
limits: R4VIDEO/R4ENC separately report only implemented codecs.

DeviceFacts bit 2 signals the driver's completed VCN ring self-tests. Existing
graphics flags retain their meaning. NV12/P010 use bounded, linear two-plane
UMA surfaces with 256-byte pitch and 64 KB plane/storage alignment. Shared
media owners retain decoder, DPB and presentation holds independently; no
CPU RGB intermediate is required by R4GFX. Physical qualification is /39.

## VCN1 H.264 message encoder (0.80.29)

The pure `Source/vcn_decode.zig` component is compiled into R4VIDEO. It
implements bounded progressive AVC tier-0 create/decode messages, internal
DPB/context sizing, native output geometry, slice collection and fresh
firmware feedback validation. Original Mesa C structs and `build_avc_msg`
generate three independent binary profile vectors via
`Tools/VcnDecodeVectors.ps1`; existing backend tests compare every byte.
The R4AMD runtime artifact and public ABI remain 0.1.6/BACKEND_V1:4 because
this source component is consumed by the R4VIDEO artifact. Physical proof
and verification of the exact pinned firmware feedback are reserved for /39.

## VCN1 additional codec sources (0.80.30)

`Port/vcn_codecs.c` is compiled into R4VIDEO, keeping the R4AMD runtime at
0.1.6/BACKEND_V1:4. `Tools/VcnCodecs.ps1` verifies the unchanged original
HEVC/VP9/MPEG2/VC1 structures/builders and VP9 default probabilities against
the pinned Mesa originals. The generated files retain their MIT notices.
The adapter provides bounded internal DPB/context planning, reference-slot
mapping, NV12/P010 target geometry and fresh decode feedback. Baseline JPEG
uses the separate VCN1 register command path. `VcnDecodeVectors.ps1` compares
four JPEG dimensions bytewise against the original Mesa command function,
alongside existing H.264 vectors and HEVC/VP9 storage/reference checks.

DeviceFacts bit 3 (`device_fact_jpeg1_submit`) advertises the driver's copied
VMID0 JPEG IB and cross-engine exclusion. NativeSubmit engine 4 selects JPEG;
wire sizes and function-table layouts are unchanged. Source eligibility alone
does not promise an implemented public profile or physical qualification.

## VCN1 native encoding sources (0.80.31)

The source catalog now contains90 original files. VcnEncode.ps1 verifies
and extracts unchanged Mesa26.2.2 VCN1 session/header/packet functions and
metadata. Port/vcn_encode.c provides bounded H.264/HEVC8 configuration,
CQP/CBR/VBR, session/DPB planning and IDR/P templates. It is compiled into
R4ENC0.1.3. R4AMD.R4L remains byte-identical0.1.6/BACKEND_V1:4. Original
MIT notices and sources remain included by ExportLegal.ps1. Physical
firmware/output qualification belongs to0.80.39.

## Raven2 consumer profile (0.80.39)

R4AMD0.1.7 adds paired GC9.2.2/SDMA4.1.1/VCN1.0.1 constants without
changing wire layouts or function-table revisions. The firmware eligibility
uses the independently verified Raven2 original (its VCN version equals the
Picasso version). Image geometry, render state, YUV shader selection and
media limits reject mixed profiles. The twelve fixed shader artifacts come
from real R4ACO0.1.3 compilation with two reproducibility runs per profile.
Existing host cases cover both families; physical qualification remains open.
