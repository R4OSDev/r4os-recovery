/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
 * R4OS ownership adapter to unmodified Mesa AddrLib. Caller scratch only;
 * upstream Addr2 types never cross the public R4L ABI. */
#include "addr_bridge.h"
#include "addrinterface.h"
#include "amdgpu_asic_addr.h"
#include "addrlib.h"
#include <string.h>

namespace {
struct Arena {
    unsigned char *base;
    uint32_t capacity, used = 0, active = 0;
    void *blocks[8] = {};
    bool broken = false;
};
void *ADDR_API allocate(const ADDR_ALLOCSYSMEM_INPUT *in) {
    auto &a = *static_cast<Arena *>(in->hClient);
    const uint32_t start = (a.used + 15u) & ~15u;
    if (in->size != sizeof(*in) || in->flags.value != 0 || !in->sizeInBytes ||
        start > a.capacity || in->sizeInBytes > a.capacity - start) return nullptr;
    unsigned slot = 0;
    while (slot < 8 && a.blocks[slot]) ++slot;
    if (slot == 8) return nullptr;
    void *p = a.base + start;
    a.used = start + in->sizeInBytes; a.blocks[slot] = p; ++a.active;
    return p;
}
ADDR_E_RETURNCODE ADDR_API release(const ADDR_FREESYSMEM_INPUT *in) {
    auto &a = *static_cast<Arena *>(in->hClient);
    for (auto &p : a.blocks) if (p && p == in->pVirtAddr && in->size == sizeof(*in)) {
        p = nullptr; --a.active; return ADDR_OK;
    }
    a.broken = true; return ADDR_ERROR;
}
AddrFormat format(uint32_t f) {
    switch (f) {
    case 875713112: case 875713089: return ADDR_FMT_8_8_8_8; // DRM XR24/AR24
    case 808669784: case 808669761: return ADDR_FMT_2_10_10_10; // XR30/AR30
    case 1211384385: case 942948929: return ADDR_FMT_16_16_16_16; // AB4H/AB48
    case 538982482: return ADDR_FMT_8;
    case 0x38385247: return ADDR_FMT_8_8;
    case 0x20363152: return ADDR_FMT_16;
    case 0x32335247: return ADDR_FMT_16_16;
    case 0x01000001: return ADDR_FMT_32; // D32_FLOAT
    case 0x01000002: return ADDR_FMT_16; // D16_UNORM
    case 0x01000003: return ADDR_FMT_8; // Separate S8
    case 0x01000101: return ADDR_FMT_BC1;
    case 0x01000103: return ADDR_FMT_BC3;
    case 0x01000105: return ADDR_FMT_BC5;
    case 0x01000107: return ADDR_FMT_BC7;
    default: return ADDR_FMT_INVALID;
    }
}
ADDR2_SURFACE_FLAGS flags(uint32_t usage, bool metadata = false) {
    ADDR2_SURFACE_FLAGS f = {};
    f.texture = (usage & 1) != 0; f.color = (usage & 2) != 0;
    f.unordered = (usage & 4) != 0; f.display = (usage & 8) != 0;
    f.depth = (usage & 16) != 0; f.noMetadata = !metadata;
    f.needEquation = 1;
    return f;
}
int32_t code(ADDR_E_RETURNCODE rc) {
    if (rc == ADDR_OK) return R4AMD_STATUS_OK;
    if (rc == ADDR_OUTOFMEMORY) return R4AMD_STATUS_OOM;
    if (rc == ADDR_NOTSUPPORTED || rc == ADDR_NOTIMPLEMENTED) return R4AMD_STATUS_UNSUPPORTED;
    return R4AMD_STATUS_INVALID;
}
}

extern "C" int32_t r4amd_addr_compute(const R4AmdImageRequest *r, void *workspace, uint32_t bytes,
                                    R4AmdImageLayout *layout, R4AmdMip *mips,
                                    const R4AmdCoordinate *coord, R4AmdImageAddress *address,
                                    R4AmdMetadata *metadata) {
    Arena arena{static_cast<unsigned char *>(workspace), bytes};
    ADDR_CREATE_INPUT in = {}; ADDR_CREATE_OUTPUT out = {};
    in.size = sizeof(in); out.size = sizeof(out);
    in.chipEngine = CIASICIDGFXENGINE_ARCTICISLAND;
    in.chipFamily = FAMILY_RV; in.chipRevision = r->chip_revision;
    in.regValue.gbAddrConfig = r->gb_addr_config;
    in.callbacks.allocSysMem = allocate; in.callbacks.freeSysMem = release;
    in.hClient = &arena; in.createFlags.fillSizeFields = 1;
    auto rc = AddrCreate(&in, &out);
    if (rc != ADDR_OK) {
        if (out.hLib && AddrDestroy(out.hLib) != ADDR_OK) return R4AMD_STATUS_INVALID;
        return arena.active || arena.broken ? R4AMD_STATUS_INVALID : code(rc);
    }
    ADDR2_COMPUTE_SURFACE_INFO_INPUT si = {};
    ADDR2_COMPUTE_SURFACE_INFO_OUTPUT so = {};
    ADDR2_MIP_INFO mi[15] = {};
    si.size = sizeof(si); so.size = sizeof(so); so.pMipInfo = mi;
    si.flags = flags(r->usage); si.swizzleMode = static_cast<AddrSwizzleMode>(r->swizzle);
    if (r->format == 0x01000003) { si.flags.depth = 0; si.flags.stencil = 1; }
    si.resourceType = static_cast<AddrResourceType>(r->resource_type); si.format = format(r->format);
    si.width = r->width; si.height = r->height; si.numSlices = r->depth;
    si.numMipLevels = r->mip_count; si.numSamples = r->samples; si.numFrags = r->samples;
    // Public pitch is bytes; all accepted formats have integral bytes/elements.
    const uint32_t elem = r->format >= 0x01000101 && r->format <= 0x01000107 ? (r->format == 0x01000101 ? 8 : 16) :
                          ((r->format == 538982482 || r->format == 0x01000003) ? 1 : (r->format == 0x01000002 || r->format == 0x38385247 || r->format == 0x20363152) ? 2 :
                           (r->format == 1211384385 || r->format == 942948929 ? 8 : 4));
    si.pitchInElement = r->pitch / elem;
    rc = Addr2ComputeSurfaceInfo(out.hLib, &si, &so);
    // Check padded storage before metadata's 32-bit dataSurfaceSize cast.
    if (rc == ADDR_OK && so.surfSize > 64u * 1024u * 1024u) {
        if (AddrDestroy(out.hLib) != ADDR_OK || arena.active || arena.broken) return R4AMD_STATUS_INVALID;
        return R4AMD_STATUS_LIMIT;
    }
    if (rc == ADDR_OK) {
        *layout = {};
        layout->version = 1; layout->size = sizeof(*layout);
        layout->byte_length = so.surfSize; layout->slice_bytes = so.sliceSize;
        layout->alignment = so.baseAlign; layout->modifier = r->modifier;
        layout->pitch = so.pitch * (so.bpp / 8); layout->height = so.height; layout->depth = so.numSlices;
        layout->epitch = (so.epitchIsHeight ? so.mipChainHeight : so.mipChainPitch) - 1;
        layout->block_width = so.blockWidth; layout->block_height = so.blockHeight; layout->block_depth = so.blockSlices;
        layout->first_mip_tail = so.firstMipIdInTail; layout->mip_count = r->mip_count;
        layout->pixel_bits = so.pixelBits; layout->element_bits = so.bpp;
        layout->resource_type = r->resource_type; layout->swizzle = r->swizzle;
        layout->flags = ((r->usage & 8) ? 1 : 0) | (r->swizzle ? 2 : 0);
        layout->gb_addr_config = r->gb_addr_config;
        for (unsigned n = 0; n < r->mip_count; ++n) {
            mips[n] = {mi[n].pitch, mi[n].height, mi[n].depth, mi[n].pixelPitch, mi[n].pixelHeight,
                       mi[n].equationIndex, mi[n].offset, mi[n].macroBlockOffset, mi[n].mipTailOffset,
                       mi[n].mipTailCoordX, mi[n].mipTailCoordY, mi[n].mipTailCoordZ, 0};
        }
    }
    if (rc == ADDR_OK && coord && address) {
        ADDR2_COMPUTE_SURFACE_ADDRFROMCOORD_INPUT ai = {};
        ADDR2_COMPUTE_SURFACE_ADDRFROMCOORD_OUTPUT ao = {};
        ai.size = sizeof(ai); ao.size = sizeof(ao);
        ai.x = coord->x; ai.y = coord->y; ai.slice = coord->slice; ai.sample = coord->sample; ai.mipId = coord->mip;
        ai.swizzleMode = si.swizzleMode; ai.flags = si.flags; ai.resourceType = si.resourceType; ai.bpp = so.bpp;
        const bool bc = r->format >= 0x01000101 && r->format <= 0x01000107;
        ai.unalignedWidth = bc ? (r->width + 3) / 4 : r->width;
        ai.unalignedHeight = bc ? (r->height + 3) / 4 : r->height;
        ai.numSlices = r->depth; ai.numMipLevels = r->mip_count; ai.numSamples = r->samples; ai.numFrags = r->samples;
        ai.pipeBankXor = r->pipe_xor; ai.pitchInElement = si.pitchInElement;
        rc = Addr2ComputeSurfaceAddrFromCoord(out.hLib, &ai, &ao);
        if (rc == ADDR_OK) *address = {1, sizeof(*address), ao.addr, ao.bitPosition, ao.prtBlockIndex};
    }
    if (rc == ADDR_OK && metadata) {
        if (r->usage & 16) {
            ADDR2_COMPUTE_HTILE_INFO_INPUT hi = {}; ADDR2_COMPUTE_HTILE_INFO_OUTPUT ho = {};
            hi.size = sizeof(hi); ho.size = sizeof(ho);
            hi.hTileFlags.pipeAligned = 1; hi.hTileFlags.rbAligned = 1;
            hi.depthFlags = flags(r->usage, true); hi.swizzleMode = si.swizzleMode;
            hi.unalignedWidth = r->width; hi.unalignedHeight = r->height; hi.numSlices = r->depth;
            hi.numMipLevels = r->mip_count; hi.firstMipIdInTail = so.firstMipIdInTail;
            rc = Addr2ComputeHtileInfo(out.hLib, &hi, &ho);
            if (rc == ADDR_OK) *metadata = {1, sizeof(*metadata), 2, 0, ho.htileBytes, ho.baseAlign, ho.sliceSize,
                ho.metaBlkWidth, ho.metaBlkHeight, 1, 8, 8, 1, 0};
        } else {
            ADDR2_COMPUTE_DCCINFO_INPUT di = {}; ADDR2_COMPUTE_DCCINFO_OUTPUT d = {};
            di.size = sizeof(di); d.size = sizeof(d); di.dccKeyFlags.pipeAligned = 1; di.dccKeyFlags.rbAligned = 1;
            di.colorFlags = flags(r->usage, true); di.resourceType = si.resourceType; di.swizzleMode = si.swizzleMode;
            di.bpp = so.bpp; di.unalignedWidth = r->width; di.unalignedHeight = r->height; di.numSlices = r->depth;
            di.numFrags = r->samples; di.numMipLevels = r->mip_count; di.dataSurfaceSize = static_cast<UINT_32>(so.surfSize);
            di.firstMipIdInTail = so.firstMipIdInTail;
            rc = Addr2ComputeDccInfo(out.hLib, &di, &d);
            if (rc == ADDR_OK) *metadata = {1, sizeof(*metadata), 1, 0, d.dccRamSize, d.dccRamBaseAlign, 0,
                d.metaBlkWidth, d.metaBlkHeight, d.metaBlkDepth, d.compressBlkWidth, d.compressBlkHeight, d.compressBlkDepth, d.fastClearSizePerSlice};
        }
    }
    const auto destroyed = AddrDestroy(out.hLib);
    if (destroyed != ADDR_OK || arena.active || arena.broken) return R4AMD_STATUS_INVALID;
    return code(rc);
}
