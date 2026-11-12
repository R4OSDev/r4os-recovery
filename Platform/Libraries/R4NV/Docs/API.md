R4NV Runtime-R4L API
====================

NVIDIA backend command encoding and explicit software/driver protocol pairing. Physical GPU ownership remains in NVIDIA.R4D.

BACKEND_V1
----------

Versioned, allocation-free NVIDIA encoding backend.

- ELF-Symbol: `r4nv_backend_v1`
- ABI-Major: 1
- Revision: 3
- Interface-ID: `0x52344f5330373931:0x52344e5642454e44`
- Tabellengroesse: 64 Byte

- Slot 0, Offset 32: `negotiate` - Validates a driver-supplied profile; reported features describe encoding support, not physical qualification.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure encoding into caller-owned output. No allocation, hardware access or retained pointers..
- Slot 1, Offset 40: `encode_copy` - Encodes virtual CE copies and system-scope semaphore release. Validation precedes every output write.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure encoding into caller-owned output. No allocation, hardware access or retained pointers..
- Slot 2, Offset 48: `encode_copy_layout` - Encodes pitch/blocklinear conversion through C6B5/C7B5, bounded by max_layout_command_words. Original encode_copy and its limits remain available. No retained state or device access.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure encoding into caller-owned output. No allocation, hardware access or retained pointers..
- Slot 3, Offset 56: `image_layout` - Checks known C797/SM86 image layouts against texture/render/scanout use. Suggests an explicit compatible CE conversion for known readable views; never guesses an unknown modifier.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure metadata negotiation; no allocation, maps, hardware access or retained pointers..

SHADER_V1
---------

Independent fixed-shader metadata and executable byte-cache boundary. BACKEND_V1 remains unchanged; native rendering, GPU memory and compilation are separate owners.

- ELF-Symbol: `r4nv_shader_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f5330373934:0x52344e5653484452`
- Tabellengroesse: 56 Byte

- Slot 0, Offset 32: `shader_info` - Returns metadata for a pinned fixed shader, including the matched solid vertex/fragment pair, without publishing rendering capability.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Bounded pure operation over caller-owned storage. No allocation, I/O, GPU access, retained pointer or compilation. Rejection preserves all outputs..
- Slot 1, Offset 40: `shader_cache_write` - Writes the checked key, compiler identity, original NVIDIA header and machine code with an integrity digest. No compiler work or hardware submission. Output bytes, written count and key must not overlap.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Bounded pure operation over caller-owned storage. No allocation, I/O, GPU access, retained pointer or compilation. Rejection preserves all outputs..
- Slot 2, Offset 48: `shader_cache_read` - Returns a view only after exact key/compiler/layout/length/integrity and fixed-program matching. Incompatible or damaged cache data returns CACHE_MISS with output unchanged. The input key must come from the current driver/renderer, not the cached entry.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Bounded pure operation over caller-owned storage. No allocation, I/O, GPU access, retained pointer or compilation. Rejection preserves all outputs..

RENDER_V1
---------

Pure public fixed-render encoder for the native graphics producer. Color and YUV metadata policy remain with R4GFX. The canonical BO/VA and native queue owners retain all GPU resources through physical drain. No driver-private implementation imports are required by consumers.

- ELF-Symbol: `r4nv_render_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f5330373934:0x52344e56524e4452`
- Tabellengroesse: 56 Byte

- Slot 0, Offset 32: `render_info` - Query one pinned C597/SM75,C797/SM86,C997/SM89 or CD97/SM120 encoder profile.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure bounded encoding. Caller owns all inputs and outputs; no retained pointers, GPU allocation, execution or wait..
- Slot 1, Offset 40: `render_upload` - Write the matched immutable shader headers/code into caller storage. At least render_info.program_bytes are required; written is set only on success.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure bounded encoding. Caller owns all inputs and outputs; no retained pointers, GPU allocation, execution or wait..
- Slot 2, Offset 48: `encode_yuv` - Encode a bounded draw list and draw_count*packet_bytes bytes of TIC/CBuf/vertex data. capacity counts u32 command words; packet_capacity counts bytes. Native engine_graphics owns completion and its release sequence. Does not submit or claim a render result.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4NV_STATUS`; Besitz: Pure bounded encoding. Caller owns all inputs and outputs; no retained pointers, GPU allocation, execution or wait..

Typen
-----

- `R4NvDeviceProfile`: 48 Byte, Alignment 8. Exact live driver binding plus its pinned command/firmware profile.
- `R4NvFeatures`: 48 Byte, Alignment 8. Actual encoder limits; no rendering or hardware validation claim.
- `R4NvCopy`: 64 Byte, Alignment 8. GPU virtual operands supplied by the owning driver. Zero rows denotes a linear transfer; otherwise bytes per row.
- `R4NvDriverProfile`: 32 Byte, Alignment 4. Immutable driver protocol payload in GfxBackendProfile.data. Version 1, size 32, vendor 0x10de and actual allocated copy-engine class; reserved fields zero. Identity/revision are BACKEND_V1. Kernel-assigned adapter and generations come from the accompanying binding, never these bytes.
- `R4NvCopyBlock`: 24 Byte, Alignment 4. Optional 2D blocklinear plane. enabled is zero or one; all other fields zero when disabled. Width/pitch and x are bytes with remapping disabled; height/y are rows. 512-byte GOBs, one GOB wide, log2_gobs 0..5, depth one, no compression.
- `R4NvCopyLayout`: 112 Byte, Alignment 8. Independent copy-layout request; original R4NvCopy remains unchanged. Block operands are plane-base addresses aligned to 512; pitched operands already include logical x/y offsets. Both full plane spans and all transfer bounds must fit; aliases are rejected before command writes.
- `R4NvDigest`: 32 Byte, Alignment 8. 32-byte identity; each word is the little-endian value of eight consecutive digest bytes. No pointer or padding.
- `R4NvShaderKey`: 120 Byte, Alignment 8. Version1 exact-size key from the actual driver/renderer. Nonzero artifact-version token, device identity, input/output format and complete pipeline-state digest. Only SM86/AMPERE_B is supported. Keys contain no GPU addresses or live resource handles; GPU allocations still require current-generation binding by the renderer.
- `R4NvShaderInfo`: 88 Byte, Alignment 8. Fixed shader metadata and source/toolchain identity. Stage0 is vertex; stage4 is fragment. Header is128 little-endian bytes; code is SM86 machine code. Encoding support is not GPU qualification.
- `R4NvShaderView`: 104 Byte, Alignment 8. Borrowed byte ranges inside the caller-owned immutable cache input. Keep that storage alive until the renderer has copied/uploaded both ranges. Addresses have byte alignment and must not be cast to aligned u32 pointers without checking. No pointer is retained by the library.
- `R4NvImageView`: 64 Byte, Alignment 8. Single-plane image metadata, no CPU/GPU address. Location0=system,1=device-local; modifier0=linear. Runtime must authenticate ownership/generations and physical mapping.
- `R4NvImageRequest`: 80 Byte, Alignment 8. Prepare an image for texture1/render-target2/scanout4. Preference0=preserve suitable layout,1=linear,2=blocklinear; flags1 forces a separate copy. Render+scanout requires the later inactive-image lease and is unsupported here.
- `R4NvImagePlan`: 64 Byte, Alignment 8. Action0=reuse,1=convert through CE; layout0=linear,1=blocklinear. Unknown/undecodable modifiers fail without a plan. Proposed bytes include the pinned native64KB allocation granule; no allocation or GPU qualification occurs here.
- `R4NvArchitecture`: 120 Byte, Alignment 8. Hardware and native memory-path facts in GfxBackendProperties: BACKEND_V1 identity, data_bytes120, exact-size layout unchanged. Payload version equals properties revision. Revision1 requires flags0; revision2 permits ARCHITECTURE_HOST_COHERENT; revision3 additionally permits ARCHITECTURE_IMAGE_LAYOUTS. Identity from captured PCI/PMC; active GPC/TPC from acknowledged firmware post-init; VRAM from acknowledged static data; VA bounds from native address-space receipt. Architecture classes do not authorize GPU execution. Host-coherence bit covers canonical system BOs and acknowledged native mapping policy only; no BAR mapping, sparse, Vulkan qualification or physical-test claim. PCI domain remains zero; memory_generation matches enclosing backend inventory. Unknown/incomplete facts remain unavailable. Old readers reject unknown property revisions; backend registration/profile and all existing runtime functions remain unchanged.
- `R4NvNativeSubmitHeader`: 32 Byte, Alignment 8. Native GfxSubmission operation10 payload, BACKEND_V1 driver profile revision1. Version1 exact32-byte header followed by push_count R4NvNativePush16 records; exact total byte count, reserved fields zero. Payload contains GPU addresses only; all command/resource storage must also be listed as canonical retained GfxNativeResource bindings. The engine mask requests instantiated engines, never architecture-class availability. Unsupported bits fail. Completion means actual engine drain and system-memory ordering, not command fetch. Vulkan resource/cache barriers remain in the native command stream.
- `R4NvNativePush`: 16 Byte, Alignment 8. One subroutine-level GPFIFO push, backed by retained GPU-VA resources. Flags1=incomplete method sequence, flags2=no prefetch/SYNC_WAIT. Unknown bits fail; final push cannot remain incomplete. Addresses/counts are 4-byte aligned and must fit the instantiated FIFO. No CPU pointer or opcode validation interface.
- `R4NvRenderInfo`: 32 Byte, Alignment 4. Version1/size32. Encoder storage limits only; never evidence of physical GPU availability. Program upload address requires128-byte alignment, packet address256-byte alignment; shader/packet/target addresses are below2^40.
- `R4NvRenderRect`: 16 Byte, Alignment 4. Fixed nonempty signed rectangle; source coordinates are absolute coded luma samples.
- `R4NvRenderPlane`: 40 Byte, Alignment 8. An already acknowledged GPU view, not a BO or a CPU pointer. Explicit DRM fourcc and modifier0=linear or NVIDIA blocklinear0x0300000000606010 plus log2 GOB height0..5. Source storage R8,GR88,R16,GR1616 is sampled as unsigned integers. Address/extent/pitch bounds are validated. The caller must retain and loan the underlying canonical BO/VA to the native queue.
- `R4NvYuvDraw`: 232 Byte, Alignment 8. Fixed232-byte draw. format1=NV12,2=P010,3=YUV420P; second_chroma is all-zero for two-plane formats. filter0=nearest,1=linear RGB bilinear; chroma reconstruction is bilinear before transfer decoding. blend0=replace,1=OVER into linear optical FP16. opacity0..65535, normalized through float vertex attributes to match COLOR_V1. chroma_x/y are IEEE754 binary32 bit patterns: x0 or0.5; y0,0.5 or1. Crop preserves this coded chroma phase. P010 low6 bits are discarded before interpolation.
- `R4NvYuvRender`: 72 Byte, Alignment 8. Version1/size72. draws borrows1..16 R4NvYuvDraw values. All draws share source views, target, format, filter, blend and chroma phase; crop, geometry, scissor and opacity may vary. color_program borrows64 aligned u32 words using COLOR CBuf2/resource ABI4, source opaque/full-range; yuv_matrix borrows12 aligned IEEE754 binary32 words, row-major affine normalized YCbCr-to-electrical-RGB3x4. Inputs are copied during the call and never retained. GPU addresses are distinct from these CPU pointers. Outputs remain unchanged on every failure; all output spans must be disjoint from each other and input spans.

Besitzregeln
------------

- hardware: The library creates command words only. NVIDIA.R4D validates mappings, current generation, channel state and completion; only that driver submits or frees GPU resources.
- outputs: Inputs are immutable for the call. Output commands and written count must be separate from each other and request metadata. Rejection leaves both outputs unchanged.
- version: BACKEND_V1 is independent of R4GFX and the platform ABI. Optional consumers validate the library header and negotiate the actual driver profile; absent/incompatible backends keep software available.
- shader_cache: Immutable byte caches bind exact driver/GPU/compiler/ABI/format/pipeline identities. No executable GPU address survives in a cache. Renderer-owned native shader/pipeline allocations must be recreated or validated after device/reset generation changes.
