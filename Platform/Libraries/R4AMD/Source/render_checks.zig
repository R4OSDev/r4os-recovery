// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std=@import("std");const t=std.testing;const c=@import("r4l_contract");
const image=@import("images.zig");const render=@import("render_impl.zig").Provider(c);const pm4=@import("pm4.zig");
const regs=@cImport({@cInclude("amdgfx9regs.h");});
fn register(words: []const u32, address: u32) ?u32 {
    var at: usize=0;
    while(at<words.len){
        const op=(words[at]>>8)&255;const count=((words[at]>>16)&0x3fff)+2;
        const base: u32=switch(op){0x69=>0x28000,0x76=>0xb000,0x79=>0x30000,else=>{at+=count;continue;}};
        const start=base+(words[at+1]&0xffff)*4;
        if(address>=start and (address-start)/4<count-2)return words[at+2+(address-start)/4];
        at+=count;
    }
    return null;
}
pub fn run() !void {
    var scratch:[65536]u8 align(16)=undefined;var surface:c.R4AmdImageLayout=undefined;var mips:[15]c.R4AmdMip=undefined;
    const request:c.R4AmdImageRequest=.{.version=1,.size=@sizeOf(c.R4AmdImageRequest),.gb_addr_config=0x24000042,.chip_revision=0x41,.device_id=0x15d8,.gc_version=c.gc_9_1_0,
        .resource_type=1,.format=875713089,.width=256,.height=128,.depth=1,.mip_count=1,.samples=1,.usage=3,.swizzle=0,.pipe_xor=0,.pitch=0,.reserved=0,.modifier=0};
    try t.expectEqual(c.status_ok,image.calculate(&request,&scratch,scratch.len,&surface,&mips,15));
    var view=std.mem.zeroes(c.R4AmdImageView);view.version=1;view.size=@sizeOf(c.R4AmdImageView);view.address=0x123400000000;view.byte_length=surface.byte_length;
    var target:c.R4AmdImageDescriptors=undefined;try t.expectEqual(c.status_ok,image.descriptors(&request,&view,&scratch,scratch.len,&target));
    var vs=render.program(0,0x8080000000);var ps=render.program(3,0x8080000000);var state=render.defaults(request.gb_addr_config,true);
    var depth=std.mem.zeroes(c.R4AmdDepth);depth.version=1;depth.size=@sizeOf(c.R4AmdDepth);
    var words:[386]u32=@splat(0xdeadc0de);var written:u32=0;
    try t.expectEqual(c.status_ok,render.pipeline(&vs,&ps,&state,&target,&depth,words[1..].ptr,384,&written));
    try t.expect(written<=384);try t.expectEqual(@as(u32,0xdeadc0de),words[0]);try t.expectEqual(@as(u32,0xdeadc0de),words[385]);
    const commands=words[1..][0..written];try pm4.packetBoundaries(commands);
    try t.expectEqual(@as(u32,@truncate(vs.code_address>>8)),register(commands,regs.R_00B120_SPI_SHADER_PGM_LO_VS).?);
    try t.expectEqual(@as(u32,@truncate(ps.code_address>>8)),register(commands,regs.R_00B020_SPI_SHADER_PGM_LO_PS).?);
    try t.expectEqual(target.color0,register(commands,regs.R_028C60_CB_COLOR0_BASE).?);
    try t.expectEqual(target.color1,register(commands,regs.R_028C64_CB_COLOR0_BASE_EXT).?);
    try t.expectEqual(@as(u32,15),register(commands,regs.R_028238_CB_TARGET_MASK).?);
    try t.expectEqual(@as(u32,1),regs.G_028A48_VPORT_SCISSOR_ENABLE(register(commands,regs.R_028A48_PA_SC_MODE_CNTL_0).?));
    try t.expectEqual(@as(u32,1),regs.G_028780_ENABLE(register(commands,regs.R_028780_CB_BLEND0_CONTROL).?));
    try t.expectEqual(@as(u32,5),regs.G_028780_COLOR_DESTBLEND(register(commands,regs.R_028780_CB_BLEND0_CONTROL).?));
    const before=words;const count=written;state.line_width=0x7fc00000;
    try t.expectEqual(c.status_invalid,render.pipeline(&vs,&ps,&state,&target,&depth,words[1..].ptr,384,&written));
    try t.expectEqualSlices(u32,&before,&words);try t.expectEqual(count,written);state=render.defaults(request.gb_addr_config,false);
    state.depth_test=1;state.depth_write=1;state.depth_compare=1;state.stencil_test=1;state.stencil_pass=2;state.stencil_ref=39;
    var depth_request=request;depth_request.format=0x01000001;depth_request.usage=16;depth_request.swizzle=24;depth_request.modifier=std.math.maxInt(u64);
    try t.expectEqual(c.status_ok,image.calculate(&depth_request,&scratch,scratch.len,&surface,&mips,15));
    depth.depth_address=0x333300000000;depth.depth_bytes=surface.byte_length;depth.width=request.width;depth.height=request.height;
    depth.depth_format=3;depth.depth_swizzle=24;depth.depth_epitch=surface.epitch;
    // The independent stencil plane has its own genuine AddrLib geometry.
    depth_request.format=0x01000003;
    try t.expectEqual(c.status_ok,image.calculate(&depth_request,&scratch,scratch.len,&surface,&mips,15));
    depth.stencil_address=0x333400000000;depth.stencil_bytes=surface.byte_length;depth.stencil_swizzle=24;depth.stencil_epitch=surface.epitch;
    try t.expectEqual(c.status_ok,render.pipeline(&vs,&ps,&state,&target,&depth,words[1..].ptr,384,&written));
    try t.expectEqual(@as(u32,1),regs.G_028800_Z_ENABLE(register(words[1..][0..written],regs.R_028800_DB_DEPTH_CONTROL).?));
    try t.expectEqual(@as(u32,1),regs.G_028800_STENCIL_ENABLE(register(words[1..][0..written],regs.R_028800_DB_DEPTH_CONTROL).?));
    try t.expectEqual(@as(u32,0x33),register(words[1..][0..written],regs.R_028044_DB_Z_READ_BASE_HI).?);
    var draw=std.mem.zeroes(c.R4AmdDraw);draw.version=1;draw.size=@sizeOf(c.R4AmdDraw);draw.descriptors=0x8080010000;draw.push_constants=0x8080010200;
    draw.count=3;draw.instances=2;draw.first_instance=7;draw.first_vertex=4;draw.viewport_x=@bitCast(@as(f32,-10));draw.viewport_y=@bitCast(@as(f32,2));
    draw.viewport_width=@bitCast(@as(f32,64));draw.viewport_height=@bitCast(@as(f32,32));draw.depth_max=@bitCast(@as(f32,1));draw.scissor_end_x=54;draw.scissor_y=2;draw.scissor_end_y=34;
    try t.expectEqual(c.status_ok,render.draw(&draw,&words,80,&written));try pm4.packetBoundaries(words[0..written]);
    try t.expectEqual(@as(u32,4),register(words[0..written],regs.R_00B130_SPI_SHADER_USER_DATA_VS_0+6*4).?);
    try t.expectEqual(@as(u32,0xc0012d00),words[written-3]);try t.expectEqual(@as(u32,3),words[written-2]);
    draw.first_vertex=0;draw.index_type=2;draw.index_address=0x444400000000;draw.index_bytes=64;draw.first_index=2;draw.base_vertex=-3;
    try t.expectEqual(c.status_ok,render.draw(&draw,&words,80,&written));try pm4.packetBoundaries(words[0..written]);
    try t.expectEqual(@as(u32,0xc0042700),words[written-6]);try t.expectEqual(@as(u32,14),words[written-5]);
    try t.expectEqual(@as(u32,8),words[written-4]);try t.expectEqual(@as(u32,0x4444),words[written-3]);
    draw.count=15;const saved=words;try t.expectEqual(c.status_invalid,render.draw(&draw,&words,80,&written));try t.expectEqualSlices(u32,&saved,&words);
    draw.count=3;try t.expectEqual(c.status_invalid,render.draw(&draw,&words,80,&words[0]));
    var code:[8192]u8=undefined;var metadata:c.R4AmdShader=undefined;
    for(0..render.programs.len)|i|{
        try t.expectEqual(c.status_ok,render.shader(@intCast(i),&code,code.len,&metadata));
        try t.expectEqual(@as(u32,0xbf810000),std.mem.readInt(u32,code[metadata.exec_bytes-4..][0..4],.little));
        try t.expect(metadata.code_address==0 and metadata.resource_abi==(if(i%6<3)@as(u32,1) else 2));
    }
}
