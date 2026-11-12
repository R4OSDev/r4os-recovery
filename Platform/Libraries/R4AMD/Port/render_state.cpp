/* Copyright 2016 Advanced Micro Devices, Inc.
 * Copyright 2024 Valve Corporation. Copyright 2026 R4.
 * SPDX-License-Identifier: MIT
 * GFX9 specialization of Mesa radv_cmd_buffer.c/radv_shader.c/ac_descriptors.c.
 * Original sources and their complete license notices remain in ThirdParty.
 * No allocation, hardware access or hidden device state occurs here.
 */
#include "r4amd.h"
#include "amdgfx9regs.h"
#include <string.h>
namespace {
uint32_t bits(float f) { uint32_t u; memcpy(&u,&f,4); return u; }
float number(uint32_t u) { float f; memcpy(&f,&u,4); return f; }
bool finite(uint32_t u) { return (u & 0x7f800000u) != 0x7f800000u; }
bool range(uint64_t address,uint64_t bytes,uint64_t alignment) {
    return address && !(address & (alignment-1)) && bytes && address < (1ull<<48) && bytes <= (1ull<<48)-address;
}
bool shader(const R4AmdShader &s,uint32_t stage) {
    return s.version==1 && s.size==sizeof(s) && s.stage==stage && (s.resource_abi==1 || s.resource_abi==2) && !s.reserved &&
        range(s.code_address,s.code_bytes,256) && s.code_bytes<=65536 && s.code_bytes%4==0 && s.exec_bytes &&
        s.exec_bytes%4==0 && s.exec_bytes<=s.code_bytes && s.sgprs>=16 && s.sgprs<=102 && s.vgprs>=4 && s.vgprs<=256 &&
        s.float_mode<=255 && s.user_sgprs==(stage==0?9u:6u) && s.input_vgprs==(stage==0?4u:24u) &&
        s.spi_ps_input_ena==(stage==0?0u:0xffffu) && s.spi_ps_input_addr==(stage==0?0u:0xffffu);
}
bool factor(uint32_t v) { return v<=10 || v==13 || v==14; } // Fixed PS has one color export; no SRC1 factors.
bool state(const R4AmdPipeline &s) {
    if(s.version!=1 || s.size!=sizeof(s) || s.reserved1 || !s.gb_addr_config || (s.gb_addr_config&7)>5 ||
       s.blend_enable>1 || !factor(s.src_rgb) || !factor(s.dst_rgb) || !factor(s.src_alpha) || !factor(s.dst_alpha) ||
       s.rgb_func>4 || s.alpha_func>4 || s.write_mask>15 || s.rop>255 || s.cull>3 || s.front_face>1 || s.polygon>2 || s.primitive>4 ||
       s.depth_test>1 || s.depth_write>1 || s.depth_compare>7 || s.depth_clip>1 || s.depth_bounds>1 || s.stencil_test>1 ||
       s.stencil_compare>7 || s.stencil_fail>7 || s.stencil_pass>7 || s.stencil_depth_fail>7 || s.stencil_read_mask>255 ||
       s.stencil_write_mask>255 || s.stencil_ref>255 || s.back_compare>7 || s.back_fail>7 || s.back_pass>7 ||
       s.back_depth_fail>7 || s.back_read_mask>255 || s.back_write_mask>255 || s.back_ref>255) return false;
    const uint32_t values[]={s.blend_r,s.blend_g,s.blend_b,s.blend_a,s.depth_min,s.depth_max,s.line_width};
    for(uint32_t v : values) if(!finite(v))return false;
    return number(s.depth_min)>=0 && number(s.depth_max)<=1 && number(s.depth_min)<=number(s.depth_max) &&
        number(s.line_width)>0 && number(s.line_width)<=8191 && (!s.blend_enable || s.rop==0xcc);
}
bool depth(const R4AmdDepth &s) {
    if(s.version!=1 || s.size!=sizeof(s) || s.reserved)return false;
    if(!s.depth_address && !s.stencil_address)return !s.depth_bytes && !s.stencil_bytes && !s.width && !s.height &&
        !s.depth_format && !s.depth_swizzle && !s.depth_epitch && !s.stencil_swizzle && !s.stencil_epitch;
    if(!s.width || !s.height || s.width>16384 || s.height>16384)return false;
    if(s.depth_address) {
        if(!range(s.depth_address,s.depth_bytes,256) || s.depth_bytes>64*1024*1024 || (s.depth_format!=1 && s.depth_format!=3) ||
            (s.depth_swizzle!=4 && s.depth_swizzle!=8 && s.depth_swizzle!=20 && s.depth_swizzle!=24) || s.depth_epitch>65535 ||
            uint64_t(s.width)*s.height*(s.depth_format==1?2:4)>s.depth_bytes)return false;
    } else if(s.depth_bytes || s.depth_format || s.depth_swizzle || s.depth_epitch)return false;
    if(s.stencil_address) {
        if(!range(s.stencil_address,s.stencil_bytes,256) || s.stencil_bytes>64*1024*1024 ||
            (s.stencil_swizzle!=4 && s.stencil_swizzle!=8 && s.stencil_swizzle!=20 && s.stencil_swizzle!=24) ||
            s.stencil_epitch>65535 || uint64_t(s.width)*s.height>s.stencil_bytes)return false;
    } else if(s.stencil_bytes || s.stencil_swizzle || s.stencil_epitch)return false;
    return !s.depth_address || !s.stencil_address || s.depth_address+s.depth_bytes<=s.stencil_address || s.stencil_address+s.stencil_bytes<=s.depth_address;
}
struct Writer {
    uint32_t *out; uint32_t n=0;
    void put(uint32_t v) { out[n++]=v; }
    void packet(uint32_t op,uint32_t count) { put(0xc0000000u|(count<<16)|(op<<8)); }
    void regs(uint32_t op,uint32_t base,uint32_t reg,const uint32_t *values,uint32_t count) {
        packet(op,count);put((reg-base)/4);for(uint32_t i=0;i<count;i++)put(values[i]);
    }
    void context(uint32_t reg,uint32_t value) { regs(0x69,0x28000,reg,&value,1); }
    void sh(uint32_t reg,const uint32_t *values,uint32_t count) { regs(0x76,0xb000,reg,values,count); }
    void uconfig(uint32_t reg,uint32_t value,uint32_t index=0) { packet(0x79,1);put((reg-0x30000)/4|(index<<28));put(value); }
    void program(const R4AmdShader &s) {
        uint32_t r1=S_00B128_VGPRS((s.vgprs-1)/4)|S_00B128_SGPRS((s.sgprs-1)/8)|S_00B128_FLOAT_MODE(s.float_mode)|S_00B128_DX10_CLAMP(1);
        if(s.stage==0)r1|=S_00B128_VGPR_COMP_CNT(2); // VertexID, InstanceID and PrimID match the compiler ABI.
        uint32_t words[]={uint32_t(s.code_address>>8),uint32_t(s.code_address>>40),r1,S_00B12C_USER_SGPR(s.user_sgprs)};
        sh(s.stage==0?R_00B120_SPI_SHADER_PGM_LO_VS:R_00B020_SPI_SHADER_PGM_LO_PS,words,4);
    }
};
}
extern "C" int32_t r4amd_native_pipeline(const R4AmdShader *vs,const R4AmdShader *ps,const R4AmdPipeline *s,
    const R4AmdImageDescriptors *color,const R4AmdDepth *ds,uint32_t *out,uint32_t capacity,uint32_t *written) {
    if(capacity<384)return R4AMD_STATUS_LIMIT;
    if(!shader(*vs,0) || !shader(*ps,4) || !state(*s) || !depth(*ds) || color->version!=1 || color->size!=sizeof(*color) ||
       !G_028C70_FORMAT(color->color4) || color->color6 || color->color7 || color->color8 || color->color9 || color->color10 ||
       color->color13 || color->color14 || G_028C74_NUM_SAMPLES(color->color5) || G_028C74_NUM_FRAGMENTS(color->color5) ||
       ((s->depth_test || s->depth_write || s->depth_bounds) && !ds->depth_address) || (s->stencil_test && !ds->stencil_address))return R4AMD_STATUS_INVALID;
    const bool float_color=G_028C70_NUMBER_TYPE(color->color4)==V_028C70_NUMBER_FLOAT;
    if(float_color && s->rop!=0xcc)return R4AMD_STATUS_UNSUPPORTED;
    Writer w{out};w.program(*vs);w.program(*ps);
    uint32_t alloc[]={S_00B118_CU_EN(0xffff),0};w.sh(R_00B118_SPI_SHADER_PGM_RSRC3_VS,alloc,2);
    w.context(R_0286C4_SPI_VS_OUT_CONFIG,0);w.context(R_02870C_SPI_SHADER_POS_FORMAT,V_02870C_SPI_SHADER_4COMP);
    w.context(R_02881C_PA_CL_VS_OUT_CNTL,0);w.context(R_0286CC_SPI_PS_INPUT_ENA,ps->spi_ps_input_ena);
    w.context(R_0286D0_SPI_PS_INPUT_ADDR,ps->spi_ps_input_addr);w.context(R_0286D8_SPI_PS_IN_CONTROL,0);
    w.context(R_0286E0_SPI_BARYC_CNTL,0);w.context(R_028C40_PA_SC_SHADER_CONTROL,0);
    w.context(R_028710_SPI_SHADER_Z_FORMAT,0);w.context(R_028714_SPI_SHADER_COL_FORMAT,V_028714_SPI_SHADER_32_ABGR);
    w.context(R_02823C_CB_SHADER_MASK,15);w.context(R_028238_CB_TARGET_MASK,s->write_mask);
    w.context(R_02880C_DB_SHADER_CONTROL,S_02880C_Z_ORDER(V_02880C_EARLY_Z_THEN_LATE_Z)|S_02880C_DUAL_QUAD_DISABLE(1));
    w.context(R_028B54_VGT_SHADER_STAGES_EN,S_028B54_MAX_PRIMGRP_IN_WAVE(2));w.context(R_028A40_VGT_GS_MODE,0);
    w.context(R_028A84_VGT_PRIMITIVEID_EN,0);w.context(R_028AB4_VGT_REUSE_OFF,0);
    w.context(R_028C58_VGT_VERTEX_REUSE_BLOCK_CNTL,S_028C58_VTX_REUSE_DEPTH(30));
    uint32_t primitives[]={V_030908_DI_PT_POINTLIST,V_030908_DI_PT_LINELIST,V_030908_DI_PT_LINESTRIP,V_030908_DI_PT_TRILIST,V_030908_DI_PT_TRISTRIP};
    w.uconfig(R_030908_VGT_PRIMITIVE_TYPE,primitives[s->primitive],1);
    w.uconfig(R_030960_IA_MULTI_VGT_PARAM,S_030960_PRIMGROUP_SIZE(127)|S_030960_SWITCH_ON_EOP(1)|S_030960_WD_SWITCH_ON_EOP(1)|S_030960_PARTIAL_VS_WAVE_ON(1),4);
    w.uconfig(R_03092C_VGT_MULTI_PRIM_IB_RESET_EN,0);
    w.context(R_028C44_PA_SC_BINNER_CNTL_0,S_028C44_BINNING_MODE(V_028C44_DISABLE_BINNING_USE_LEGACY_SC));
    w.context(R_028A4C_PA_SC_MODE_CNTL_1,S_028A4C_WALK_FENCE_ENABLE(1)|S_028A4C_WALK_FENCE_SIZE((s->gb_addr_config&7)==1?2:3)|
        S_028A4C_SUPERTILE_WALK_ORDER_ENABLE(1)|S_028A4C_TILE_WALK_ORDER_ENABLE(1)|S_028A4C_MULTI_SHADER_ENGINE_PRIM_DISCARD_ENABLE(1)|
        S_028A4C_FORCE_EOV_CNTDWN_ENABLE(1)|S_028A4C_FORCE_EOV_REZ_ENABLE(1)|S_028A4C_WALK_ALIGN8_PRIM_FITS_ST(1));
    w.context(R_028A48_PA_SC_MODE_CNTL_0,S_028A48_VPORT_SCISSOR_ENABLE(1));w.context(R_028BE0_PA_SC_AA_CONFIG,0);
    w.context(R_028BE4_PA_SU_VTX_CNTL,S_028BE4_PIX_CENTER(1)|S_028BE4_ROUND_MODE(2));w.context(R_0286D4_SPI_INTERP_CONTROL_0,0);
    w.context(R_028C4C_PA_SC_CONSERVATIVE_RASTERIZATION_CNTL,0);
    w.context(R_028804_DB_EQAA,S_028804_HIGH_QUALITY_INTERSECTIONS(1)|S_028804_INCOHERENT_EQAA_READS(1)|S_028804_STATIC_ANCHOR_ASSOCIATIONS(1));
    w.context(R_028B70_DB_ALPHA_TO_MASK,0);w.context(R_028C38_PA_SC_AA_MASK_X0Y0_X1Y0,0xffffffff);w.context(R_028C3C_PA_SC_AA_MASK_X0Y1_X1Y1,0xffffffff);
    w.context(R_028BF8_PA_SC_AA_SAMPLE_LOCS_PIXEL_X0Y0_0,0);w.context(R_028C08_PA_SC_AA_SAMPLE_LOCS_PIXEL_X1Y0_0,0);
    w.context(R_028C18_PA_SC_AA_SAMPLE_LOCS_PIXEL_X0Y1_0,0);w.context(R_028C28_PA_SC_AA_SAMPLE_LOCS_PIXEL_X1Y1_0,0);
    w.context(R_028818_PA_CL_VTE_CNTL,0x3f);w.context(R_028810_PA_CL_CLIP_CNTL,S_028810_DX_CLIP_SPACE_DEF(1)|
        S_028810_DX_LINEAR_ATTR_CLIP_ENA(1)|S_028810_ZCLIP_NEAR_DISABLE(!s->depth_clip)|S_028810_ZCLIP_FAR_DISABLE(!s->depth_clip));
    w.context(R_028814_PA_SU_SC_MODE_CNTL,S_028814_CULL_FRONT(s->cull&1)|S_028814_CULL_BACK(s->cull>>1)|S_028814_FACE(s->front_face)|
        S_028814_POLY_MODE(s->polygon!=2)|S_028814_POLYMODE_FRONT_PTYPE(s->polygon)|S_028814_POLYMODE_BACK_PTYPE(s->polygon));
    w.context(R_028A08_PA_SU_LINE_CNTL,S_028A08_WIDTH(uint32_t(number(s->line_width)*8)));
    w.context(R_028A0C_PA_SC_LINE_STIPPLE,0);w.context(R_028BDC_PA_SC_LINE_CNTL,0);
    w.context(R_028A00_PA_SU_POINT_SIZE,8|(8<<16));w.context(R_028A04_PA_SU_POINT_MINMAX,8|(8<<16));
    w.context(R_028200_PA_SC_WINDOW_OFFSET,0);w.context(R_02820C_PA_SC_CLIPRECT_RULE,0xffff);
    w.context(R_028030_PA_SC_SCREEN_SCISSOR_TL,0);w.context(R_028034_PA_SC_SCREEN_SCISSOR_BR,0x40004000);
    w.context(R_028204_PA_SC_WINDOW_SCISSOR_TL,0x80000000);w.context(R_028208_PA_SC_WINDOW_SCISSOR_BR,0x40004000);
    w.context(R_028240_PA_SC_GENERIC_SCISSOR_TL,0x80000000);w.context(R_028244_PA_SC_GENERIC_SCISSOR_BR,0x40004000);
    uint32_t guards[]={bits(1),bits(1),bits(1),bits(1)};w.regs(0x69,0x28000,R_028BE8_PA_CL_GB_VERT_CLIP_ADJ,guards,4);
    // All other render targets stay disabled, irrespective of previous context state.
    const uint32_t colors[]={color->color0,color->color1,color->color2,color->color3,color->color4,color->color5,
        color->color6,color->color7,color->color8,color->color9,color->color10,color->color11,color->color12,color->color13,color->color14};
    w.regs(0x69,0x28000,R_028C60_CB_COLOR0_BASE,colors,15);w.context(R_0287A0_CB_MRT0_EPITCH,color->color15);
    for(uint32_t i=1;i<8;i++)w.context(R_028C70_CB_COLOR0_INFO+i*0x3c,0);
    w.context(R_028808_CB_COLOR_CONTROL,S_028808_MODE(s->write_mask?V_028808_CB_NORMAL:V_028808_CB_DISABLE)|S_028808_ROP3(s->rop)|S_028808_DISABLE_DUAL_QUAD(1));
    w.context(R_028780_CB_BLEND0_CONTROL,S_028780_ENABLE(s->blend_enable)|S_028780_COLOR_SRCBLEND(s->src_rgb)|S_028780_COLOR_DESTBLEND(s->dst_rgb)|
        S_028780_COLOR_COMB_FCN(s->rgb_func)|S_028780_SEPARATE_ALPHA_BLEND(1)|S_028780_ALPHA_SRCBLEND(s->src_alpha)|
        S_028780_ALPHA_DESTBLEND(s->dst_alpha)|S_028780_ALPHA_COMB_FCN(s->alpha_func)|S_028780_DISABLE_ROP3(float_color));
    uint32_t constants[]={s->blend_r,s->blend_g,s->blend_b,s->blend_a};w.regs(0x69,0x28000,R_028414_CB_BLEND_RED,constants,4);
    w.context(R_028000_DB_RENDER_CONTROL,0);w.context(R_02800C_DB_RENDER_OVERRIDE,S_02800C_DISABLE_VIEWPORT_CLAMP(!s->depth_clip));
    w.context(R_028010_DB_RENDER_OVERRIDE2,0);w.context(R_028008_DB_DEPTH_VIEW,0);w.context(R_028ABC_DB_HTILE_SURFACE,0);
    uint32_t htile[]={0,0,ds->width?S_02801C_X_MAX(ds->width-1)|S_02801C_Y_MAX(ds->height-1):0};w.regs(0x69,0x28000,R_028014_DB_HTILE_DATA_BASE,htile,3);
    uint32_t db[]={S_028038_FORMAT(ds->depth_format)|S_028038_SW_MODE(ds->depth_swizzle),
        S_02803C_FORMAT(ds->stencil_address?V_02803C_STENCIL_8:0)|S_02803C_SW_MODE(ds->stencil_swizzle)|S_02803C_TILE_STENCIL_DISABLE(1),
        uint32_t(ds->depth_address>>8),uint32_t(ds->depth_address>>40),uint32_t(ds->stencil_address>>8),uint32_t(ds->stencil_address>>40),
        uint32_t(ds->depth_address>>8),uint32_t(ds->depth_address>>40),uint32_t(ds->stencil_address>>8),uint32_t(ds->stencil_address>>40)};
    w.regs(0x69,0x28000,R_028038_DB_Z_INFO,db,10);uint32_t epitch[]={S_028068_EPITCH(ds->depth_epitch),S_02806C_EPITCH(ds->stencil_epitch)};
    w.regs(0x69,0x28000,R_028068_DB_Z_INFO2,epitch,2);
    w.context(R_028800_DB_DEPTH_CONTROL,S_028800_Z_ENABLE(s->depth_test)|S_028800_Z_WRITE_ENABLE(s->depth_write)|S_028800_ZFUNC(s->depth_compare)|
        S_028800_DEPTH_BOUNDS_ENABLE(s->depth_bounds)|S_028800_STENCIL_ENABLE(s->stencil_test)|S_028800_BACKFACE_ENABLE(s->stencil_test)|
        S_028800_STENCILFUNC(s->stencil_compare)|S_028800_STENCILFUNC_BF(s->back_compare));
    w.context(R_02842C_DB_STENCIL_CONTROL,S_02842C_STENCILFAIL(s->stencil_fail)|S_02842C_STENCILZPASS(s->stencil_pass)|S_02842C_STENCILZFAIL(s->stencil_depth_fail)|
        S_02842C_STENCILFAIL_BF(s->back_fail)|S_02842C_STENCILZPASS_BF(s->back_pass)|S_02842C_STENCILZFAIL_BF(s->back_depth_fail));
    uint32_t stencil[]={S_028430_STENCILTESTVAL(s->stencil_ref)|S_028430_STENCILMASK(s->stencil_read_mask)|S_028430_STENCILWRITEMASK(s->stencil_write_mask)|S_028430_STENCILOPVAL(1),
        S_028434_STENCILTESTVAL_BF(s->back_ref)|S_028434_STENCILMASK_BF(s->back_read_mask)|S_028434_STENCILWRITEMASK_BF(s->back_write_mask)|S_028434_STENCILOPVAL_BF(1)};
    w.regs(0x69,0x28000,R_028430_DB_STENCILREFMASK,stencil,2);uint32_t bounds[]={s->depth_min,s->depth_max};w.regs(0x69,0x28000,R_028020_DB_DEPTH_BOUNDS_MIN,bounds,2);
    *written=w.n;return R4AMD_STATUS_OK;
}
extern "C" int32_t r4amd_native_draw(const R4AmdDraw *d,uint32_t *out,uint32_t capacity,uint32_t *written) {
    if(capacity<80)return R4AMD_STATUS_LIMIT;
    if(d->version!=1 || d->size!=sizeof(*d) || d->reserved0 || d->reserved1 || !d->count || !d->instances || d->count>1048576 ||
       d->instances>65535 || uint64_t(d->first_instance)+d->instances>0xffffffffu ||
       !range(d->descriptors,512,16) || !range(d->push_constants,160,16) || d->index_type>2 ||
       d->scissor_x>=d->scissor_end_x || d->scissor_y>=d->scissor_end_y || d->scissor_end_x>16384 || d->scissor_end_y>16384)return R4AMD_STATUS_INVALID;
    const uint32_t values[]={d->viewport_x,d->viewport_y,d->viewport_width,d->viewport_height,d->depth_min,d->depth_max};
    for(uint32_t v : values)if(!finite(v))return R4AMD_STATUS_INVALID;
    const float x=number(d->viewport_x),y=number(d->viewport_y),width=number(d->viewport_width),height=number(d->viewport_height);
    if(x< -32768 || y< -32768 || width<=0 || height<=0 || width>32768 || height>32768 || x+width>32768 || y+height>32768 ||
       number(d->depth_min)<0 || number(d->depth_max)>1 || number(d->depth_min)>number(d->depth_max))return R4AMD_STATUS_INVALID;
    if(d->index_type) {
        uint32_t bytes=d->index_type==1?2:4;
        if(!range(d->index_address,d->index_bytes,bytes) || d->index_bytes>64*1024*1024 || d->index_bytes%bytes ||
           uint64_t(d->first_index)+d->count>d->index_bytes/bytes || d->first_vertex)return R4AMD_STATUS_INVALID;
    } else if(d->index_address || d->index_bytes || d->first_index || d->base_vertex || uint64_t(d->first_vertex)+d->count>0x7fffffffu)return R4AMD_STATUS_INVALID;
    Writer w{out};uint32_t user[]={0,0,uint32_t(d->descriptors),uint32_t(d->descriptors>>32),uint32_t(d->push_constants),uint32_t(d->push_constants>>32),
        d->index_type?uint32_t(d->base_vertex):d->first_vertex,d->first_instance,d->draw_id};
    w.sh(R_00B130_SPI_SHADER_USER_DATA_VS_0,user,9);w.sh(R_00B030_SPI_SHADER_USER_DATA_PS_0,user,6);
    uint32_t viewport[]={bits(width/2),bits(x+width/2),bits(height/2),bits(y+height/2),bits(number(d->depth_max)-number(d->depth_min)),d->depth_min};
    w.regs(0x69,0x28000,R_02843C_PA_CL_VPORT_XSCALE,viewport,6);uint32_t bounds[]={d->depth_min,d->depth_max};w.regs(0x69,0x28000,R_0282D0_PA_SC_VPORT_ZMIN_0,bounds,2);
    uint32_t scissor[]={S_028250_TL_X(d->scissor_x)|S_028250_TL_Y(d->scissor_y)|S_028250_WINDOW_OFFSET_DISABLE(1),S_028254_BR_X(d->scissor_end_x)|S_028254_BR_Y(d->scissor_end_y)};
    w.regs(0x69,0x28000,R_028250_PA_SC_VPORT_SCISSOR_0_TL,scissor,2);
    w.packet(0x2f,0);w.put(d->instances);
    if(d->index_type) {
        const uint32_t bytes=d->index_type==1?2:4;const uint64_t address=d->index_address+uint64_t(d->first_index)*bytes;
        w.packet(0x2a,0);w.put(d->index_type-1);
        w.packet(0x27,4);w.put(uint32_t(d->index_bytes/bytes-d->first_index));w.put(uint32_t(address));w.put(uint32_t(address>>32));w.put(d->count);w.put(0);
    } else {w.packet(0x2d,1);w.put(d->count);w.put(2);}
    *written=w.n;return R4AMD_STATUS_OK;
}
