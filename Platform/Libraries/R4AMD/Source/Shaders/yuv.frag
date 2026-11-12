#version 450
#extension GL_GOOGLE_include_directive : require
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include "coordinates.glsl"
#include "color.glsl"
layout(set=1,binding=0) uniform usampler2D luma_image;
layout(set=1,binding=1) uniform usampler2D chroma_image;
layout(set=1,binding=2) uniform usampler2D second_image;
layout(set=0,binding=1,std140) uniform YuvProgram {
    uvec4 head;
    vec4 matrix0; vec4 matrix1; vec4 matrix2;
    vec2 origin; float quantum; uint shift;
    vec4 bounds;
    vec4 extent;
    vec4 reserved0; vec4 reserved1; vec4 reserved2; vec4 reserved3;
    vec4 reserved4; vec4 reserved5; vec4 reserved6; vec4 reserved7; vec4 reserved8;
} yp;
layout(location=0) out vec4 color;
vec2 chroma(ivec2 position) {
    uvec2 pair = texelFetch(chroma_image, position, 0).rg;
    if (yp.head.x == 3u) pair.y = texelFetch(second_image, position, 0).r;
    return vec2(pair >> yp.shift) * yp.quantum;
}
vec4 decode_pixel(ivec2 position) {
    float y = float(texelFetch(luma_image, position, 0).r >> yp.shift) * yp.quantum;
    vec2 last = yp.extent.zw - 1.0;
    vec2 p = clamp((vec2(position) - yp.origin) * 0.5, vec2(0.0), last);
    vec2 low = floor(p), high = min(low + 1.0, last), fraction = p - low;
    vec2 uv = mix(mix(chroma(ivec2(low)), chroma(ivec2(high.x, low.y)), fraction.x),
                  mix(chroma(ivec2(low.x, high.y)), chroma(ivec2(high)), fraction.x), fraction.y);
    vec4 signal = vec4(y, uv, 1.0);
    return color_decode(vec4(dot(yp.matrix0, signal), dot(yp.matrix1, signal), dot(yp.matrix2, signal), 1.0));
}
void main() {
    vec2 p = clamp(coordinates() * yp.extent.xy - 0.5, yp.bounds.xy, yp.bounds.zw);
    bool bilinear = yp.head.y != 0u;
    vec2 weight = fract(p), origin = bilinear ? floor(p) : floor(p + 0.5);
    vec4 sum = vec4(0.0);
    for (uint i = 0u; i < (bilinear ? 4u : 1u); ++i) {
        uvec2 corner = uvec2(i & 1u, i >> 1u);
        vec2 gain = mix(1.0 - weight, weight, notEqual(corner, uvec2(0u)));
        vec2 selected = min(origin + vec2(corner), yp.bounds.zw);
        sum += decode_pixel(ivec2(selected)) * (bilinear ? gain.x * gain.y : 1.0);
    }
    color = color_encode(sum, draw.tint.a);
}
