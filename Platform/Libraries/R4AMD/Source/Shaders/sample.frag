#version 450
#extension GL_GOOGLE_include_directive : require
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include "coordinates.glsl"
layout(set=1,binding=0) uniform sampler2D source_image;
layout(location=0) out vec4 color;
vec4 srgb(vec4 sample_color, bool encode) {
    float a = sample_color.a;
    vec3 x = clamp(sample_color.rgb / (a > 0.0 ? a : 1.0), 0.0, 1.0);
    vec3 low = encode ? x * 12.92 : x / 12.92;
    vec3 high = encode ? pow(x, vec3(1.0/2.4)) * 1.055 - 0.055 : pow((x + 0.055) / 1.055, vec3(2.4));
    return vec4(mix(high, low, lessThanEqual(x, vec3(encode ? 0.0031308 : 0.04045))) * a, a);
}
void main() {
    vec4 sample_color = textureLod(source_image, coordinates(), 0.0);
    if (draw.flags.x == 1u) sample_color = srgb(sample_color, false);
    color = sample_color * draw.tint;
    if (draw.flags.x == 2u) color = srgb(color, true);
}
