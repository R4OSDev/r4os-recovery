R4AMD Runtime-R4L API
=====================

AMD command encoding and rendering/media library. Only AMDGPU owns hardware; encoder capabilities are intersected with the active common backend.

INFO_V1
-------

Independent immutable library identity, append-only interface.

- ELF-Symbol: `r4amd_info_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f53:0x414d4431`
- Tabellengroesse: 40 Byte

- Slot 0, Offset 32: `get_info` - Return source/build identity. Zero capabilities is deliberate until real implementation; source compatibility is not device admission.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: No retained memory, allocation, hardware access or shared mutable state..

BACKEND_V1
----------

AMD-only negotiation; separate from NVIDIA BACKEND_V1 even if individual payload sizes coincide.

- ELF-Symbol: `r4amd_backend_v1`
- ABI-Major: 1
- Revision: 4
- Interface-ID: `0x52344f53:0x414d4432`
- Tabellengroesse: 72 Byte

- Slot 0, Offset 32: `negotiate` - Validate the AMD-specific versioned protocol and report only implemented command capabilities. Zero features is a valid foundation result; it cannot select an accelerated provider.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Pure bounded negotiation; no device access, allocations or pointers retained..
- Slot 1, Offset 40: `encode_copy` - Bounded SDMA4.1 packets into disjoint caller memory; failure changes neither commands nor written count. No fence or device access is implied.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Pure encoding into caller-owned output. No allocation, hardware access or retained pointers..
- Slot 2, Offset 48: `encode_fill` - Bounded SDMA4.1 packets into disjoint caller memory; failure changes neither commands nor written count. No fence or device access is implied.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Pure encoding into caller-owned output. No allocation, hardware access or retained pointers..
- Slot 3, Offset 56: `encode_pm4_frame` - Emit 48 graphics or 32 compute PM4 dwords; disjoint buffers and all fields are validated before output writes. No allocation, retention, submission or hardware access.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Pure encoding into caller-owned output. No allocation, hardware access or retained pointers..
- Slot 4, Offset 64: `media_caps` - Query bounded Picasso VCN1 hardware/firmware eligibility. No GPU or codec execution is claimed; reject unsupported codec/profile/depth combinations transactionally.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Pure bounded negotiation; no device access, allocations or pointers retained..

IMAGE_V1
--------

GFX9 source-backed image layout and immutable provider descriptors, separate from active driver operations.

- ELF-Symbol: `r4amd_image_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f53:0x414d4433`
- Tabellengroesse: 72 Byte

- Slot 0, Offset 32: `calculate` - Calculate real GFX9 Addr2 surface and mip geometry. Outputs unchanged on failure; scratch may change. At most64KB scratch,15mips,64MB image. No retained allocations.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Caller-owned disjoint inputs, outputs and 16-byte-aligned workspace. No heap, globals, hardware I/O or retained pointers. Do not reuse workspace concurrently..
- Slot 1, Offset 40: `address` - Actual Addr2 coordinate calculation including tiled/mip/MSAA addressing.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Caller-owned disjoint inputs, outputs and 16-byte-aligned workspace. No heap, globals, hardware I/O or retained pointers. Do not reuse workspace concurrently..
- Slot 2, Offset 48: `metadata` - Reference-only DCC/HTILE geometry from Addr2. Never enables compression or accepts unknown metadata states.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Caller-owned disjoint inputs, outputs and 16-byte-aligned workspace. No heap, globals, hardware I/O or retained pointers. Do not reuse workspace concurrently..
- Slot 3, Offset 56: `import_image` - Recompute and validate BO import. Exact modifier/topology/epoch; insufficient or misaligned backing rejected. No BO retain or mapping: owner must retain it separately.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Caller-owned disjoint inputs, outputs and 16-byte-aligned workspace. No heap, globals, hardware I/O or retained pointers. Do not reuse workspace concurrently..
- Slot 4, Offset 64: `descriptors` - Recompute image layout before building uncompressed GFX9 texture/sampler/color resource descriptors; no caller-forged internal layout.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: Caller-owned disjoint inputs, outputs and 16-byte-aligned workspace. No heap, globals, hardware I/O or retained pointers. Do not reuse workspace concurrently..

RENDER_V1
---------

Bounded native GFX9 shader profiles and real PM4 render encoding; active AMDGPU capabilities remain authoritative.

- ELF-Symbol: `r4amd_render_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52344f53:0x414d4434`
- Tabellengroesse: 56 Byte

- Slot 0, Offset 32: `shader` - Copy a fixed shader and its measured R4ACO metadata. Profiles 0 fullscreen VS/1 vertex-pull VS/2 fill PS/3 sampled PS/4 color PS/5 YUV PS. Code_address is zero until caller uploads to retained executable GPU memory. IDs0..5 are Picasso gfx902; IDs6..11 are the same six shader roles compiled separately for Raven2 gfx909.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: No allocation, retention, device access or submission; all buffers caller-owned and disjoint. Failure leaves outputs unchanged..
- Slot 1, Offset 40: `encode_pipeline` - Emit complete GFX9 pipeline and attachment state; reserve at least384 DWORDs. Color descriptors come from IMAGE_V1. Shader addresses and every attachment must remain resident until exact GPU fence retirement.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: No allocation, retention, device access or submission; all buffers caller-owned and disjoint. Failure leaves outputs unchanged..
- Slot 2, Offset 48: `encode_draw` - Emit descriptor/push binding, viewport, clipped scissor and real DRAW_INDEX_2 or DRAW_INDEX_AUTO; reserve80 DWORDs. The preceding pipeline must use the same native shader ABI. Each complete job also requires queue cache barriers and its exact completion fence.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4AMD_STATUS`; Besitz: No allocation, retention, device access or submission; all buffers caller-owned and disjoint. Failure leaves outputs unchanged..

Typen
-----

- `R4AmdInfo`: 32 Byte, Alignment 4. Fixed ABI1 source/build identity, not a measured hardware profile.
- `R4AmdDriverProfile`: 32 Byte, Alignment 4. Opaque AMD payload in common GfxBackendProfile; tagged by this BACKEND_V1 interface ID, profile revision 1.
- `R4AmdDeviceProfile`: 56 Byte, Alignment 8. Negotiation binds an AMD IP/command profile to one common device/reset epoch; memory generation remains a separate common owner field.
- `R4AmdFeatures`: 32 Byte, Alignment 4. A compatible profile is not an active GPU: effective operations are the intersection with actual common driver capabilities.
- `R4AmdCopy`: 72 Byte, Alignment 8. Fixed SDMA4.1 request; all reserved fields and unsupported modifiers must be zero. Validation precedes output writes.
- `R4AmdFill`: 32 Byte, Alignment 8. Fixed SDMA4.1 request; all reserved fields and unsupported modifiers must be zero. Validation precedes output writes.
- `R4AmdPm4Frame`: 64 Byte, Alignment 8. Bounded GC9.1 outer ring frame: HDP, pipeline/cache barriers, VMID1 IB, EOP workaround and exact 64-bit fence. No device completion or shader/API capability is implied.
- `R4AmdImageRequest`: 80 Byte, Alignment 8. Immutable GFX9 image request. Measured GB_ADDR_CONFIG and external ASIC revision, never PCI revision. Dimensions <=16384, mips<=15, samples1/2/4/8, 64MB owner bound. No compression state is accepted.
- `R4AmdImageLayout`: 104 Byte, Alignment 8. Stable derived surface description. Pitch is bytes; mip records distinguish elements/pixels and macro-block/tail positions. No upstream pointers or C++ layouts cross the interface.
- `R4AmdMip`: 64 Byte, Alignment 8. One AddrLib mip record; pitch in elements. Caller supplies at most15 records.
- `R4AmdCoordinate`: 32 Byte, Alignment 4. Coordinates in format elements; bounded to the selected logical mip/slice/sample.
- `R4AmdImageAddress`: 24 Byte, Alignment 8. Actual coordinate-to-byte result.
- `R4AmdMetadata`: 72 Byte, Alignment 8. Reference-only DCC or HTILE geometry. Flags stay zero: transitions/initialization are not enabled and this is not a usable compressed image.
- `R4AmdImageImport`: 80 Byte, Alignment 8. Import from the common BO descriptor. Metadata state must be zero; adapter/epoch, alignment, offset, pitch, size and modifier must exactly support the derived image.
- `R4AmdImageView`: 96 Byte, Alignment 8. GFX9 texture/sampler and color target descriptor request. Caller retains VA/backing through the associated queue fence. Uncompressed views only; no command submission.
- `R4AmdImageDescriptors`: 120 Byte, Alignment 4. GFX9 source-derived resource words; color words ordered as documented in the API. Immutable data, no live rendering capability.
- `R4AmdArchitecture`: 64 Byte, Alignment 8. Measured AMD image profile in common backend properties (IMAGE_V1 identity, revision1). Flags/reserved zero; describes geometry, not render/present capability. ASIC revision is external, not PCI revision.
- `R4AmdShader`: 64 Byte, Alignment 8. GFX902/GFX909 wave64 native shader ABI. Code is immutable, 256-byte GPU aligned; no scratch, LDS or interpolated varyings in this renderer. Offline metadata originates in R4ACO; CPU encoding is not hardware admission.
- `R4AmdPipeline`: 176 Byte, Alignment 4. Single-sample, one-color-target GFX9 pipeline. Hardware blend factors 0..10,13,14 (no dual-source export); combine 0 add/1 subtract/2 min/3 max/4 reverse-subtract. ROP is an eight-bit truth table. Compare/stencil operations follow Vulkan values. Primitive 0 point/1 line-list/2 line-strip/3 triangle-list/4 triangle-strip; polygon 0 point/1 line/2 fill. Cull front bit0/back bit1, front_face 0 CCW/1 CW. Depth range uses Vulkan 0..1; all floats finite.
- `R4AmdDepth`: 72 Byte, Alignment 8. Retained separate depth and stencil planes, single sample/mip/layer. Depth format 0 none/1 D16/3 D32; optional stencil is S8. Addresses, sizes and epitches must originate in AddrLib. No HTILE or compression is enabled. Empty attachment has zero fields after size.
- `R4AmdDraw`: 120 Byte, Alignment 8. Bounded direct draw. Descriptor table is 512 bytes (resource ABI2), push range 160 bytes. Index type 0 auto/1 uint16/2 uint32; index byte range covers first_index and count. Auto draws add first_vertex through native user SGPR6; indexed draws add base_vertex. Viewport and clipped scissor use the target coordinate system. Vertex pulling uses set0 binding2 with clip-space vec4 stride16.
- `R4AmdRect`: 16 Byte, Alignment 4. Pixel rectangle in the image coordinate system.
- `R4AmdYuvPlane`: 32 Byte, Alignment 8. Index into canonical native resource bindings; byte offset and pitch must match the referenced image plane. No CPU pointer or unretained GPU VA.
- `R4AmdYuvHeader`: 200 Byte, Alignment 8. Native queue BACKEND_V1 profile revision1 command kind1: this 200-byte header followed by the common 256-byte color program and 48-byte YUV matrix (12 IEEE754 float32 bits), exactly504 bytes. Format1 NV12/2 P010/3 YUV420P, filter0 nearest/1 linear RGB after EOTF, blend0 replace/1 premultiplied over, opacity0..65535. Chroma origin uses float32 bits. Unused plane2 is zero. Driver binds its immutable ACO programs and retains all canonical mappings until actual completion.
- `R4AmdDeviceFacts`: 240 Byte, Alignment 8. IMAGE_V1 backend properties revision2. Retains the exact 64-byte revision1 architecture prefix, followed by bound native device facts. No Mesa structures, pointers, feature or Vulkan admission claims. Never manufacture facts for an absent backend.
- `R4AmdNativeSubmit`: 32 Byte, Alignment 8. BACKEND_V1 native command revision1: 32-byte header then exactly ib_count R4AmdNativeIb records. Device facts revision2 flags bit0 admits PM4; 32+16*N bytes cannot collide with the legacy 504-byte YUV packet. The canonical submit retains every resident binding through actual completion. Each IB is inside a retained binding, VMID1. Provider preambles supply complete shader context; no embedded CPU pointers.
- `R4AmdNativeIb`: 16 Byte, Alignment 8. One immutable indirect-buffer descriptor. Driver validates address, length, binding identity and generation before publishing any commands.
- `R4AmdDeviceFactsV3`: 256 Byte, Alignment 8. IMAGE_V1 backend properties revision3, exactly256 bytes. Preserves the complete revision2 facts prefix and adds actual clock and memory-owner limits. The consuming runtime owns Vulkan profile admission.
- `R4AmdMediaQuery`: 64 Byte, Alignment 4. Pure VCN source-profile query; does not bind hardware or allocate codec state. Operation 0 decode / 1 encode; codec IDs match R4VIDEO/R4ENC.
- `R4AmdMediaCaps`: 64 Byte, Alignment 4. Source-profile limits only (flags=1), not a running R4VIDEO/R4ENC codec advertisement. Intersect with its implemented codec and actual device before use.

Besitzregeln
------------

- hardware: Only AMDGPU.R4D owns hardware. The foundation interface touches no device.
- provider: Table pointers live for the loaded provider generation. No pointer is retained from the caller.
