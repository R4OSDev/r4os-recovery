// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// 160-byte native push ABI: all offsets are fixed and independently validated.
layout(push_constant) uniform Draw {
    vec4 mapping;
    vec4 bounds;
    vec4 tint;
    uvec4 flags;
    uvec4 grid_head;
    ivec4 grid_native;
    ivec4 grid_viewport;
    uvec4 grid_guest;
    ivec4 atlas;
    vec4 extent;
} draw;
vec2 coordinates() {
    vec2 uv = gl_FragCoord.xy * draw.mapping.xy + draw.mapping.zw;
    if (draw.grid_head.x != 0u) {
        ivec2 pixel = ivec2(gl_FragCoord.xy) + draw.grid_native.yz;
        ivec2 reversed = ivec2(draw.grid_head.w, draw.grid_native.x) - 1 - pixel;
        ivec2 oriented = pixel;
        if (draw.grid_head.y == 1u) oriented = ivec2(reversed.y, pixel.x);
        else if (draw.grid_head.y == 2u) oriented = reversed;
        else if (draw.grid_head.y == 3u) oriented = ivec2(pixel.y, reversed.x);
        uvec2 logical = (uvec2(oriented) * 2u + 1u) * 120u / (2u * draw.grid_head.z);
        uvec2 relative = uvec2(ivec2(logical) - draw.grid_viewport.xy);
        uvec2 selected = relative * draw.grid_guest.xy / uvec2(draw.grid_viewport.zw) - draw.grid_guest.zw;
        uv = (vec2(selected + uvec2(draw.atlas.xy)) + 0.5) / draw.extent.xy;
    }
    return clamp(uv, draw.bounds.xy, draw.bounds.zw);
}
