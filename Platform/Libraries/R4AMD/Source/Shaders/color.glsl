// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// The common R4GFX color program, serialized without any NVIDIA dependency.
// Identical mathematical policy to R4GFX's CPU and R4NV's shader consumers.
layout(set=0,binding=0,std140) uniform ColorProgram {
    uvec4 head;
    uvec4 tail;
    vec4 source0; vec4 source1; vec4 source2;
    vec4 target0; vec4 target1; vec4 target2;
    vec4 source_light; vec4 target_light;
    vec4 ranges;
    vec4 tone;
    vec4 target;
    vec4 reserved0; vec4 reserved1; vec4 reserved2;
} cp;
float luminance(vec3 x) { return dot(x, vec3(0.26270021, 0.67799807, 0.05930172)); }
vec3 srgb_transfer(vec3 value, bool encode) {
    vec3 x = abs(value);
    vec3 low = encode ? x * 12.92 : x / 12.92;
    vec3 high = encode ? pow(x, vec3(1.0/2.4)) * 1.055 - 0.055 : pow((x + 0.055) / 1.055, vec3(2.4));
    return sign(value) * mix(high, low, lessThanEqual(x, vec3(encode ? 0.0031308 : 0.04045)));
}
vec3 pq_transfer(vec3 value, bool encode) {
    const float m1 = 2610.0/16384.0, m2 = 2523.0/32.0;
    const float c1 = 3424.0/4096.0, c2 = 2413.0/128.0, c3 = 2392.0/128.0;
    if (encode) {
        vec3 p = pow(clamp(value * 0.0001, 0.0, 1.0), vec3(m1));
        return pow((c1 + c2 * p) / (1.0 + c3 * p), vec3(m2));
    }
    vec3 p = pow(clamp(value, 0.0, 1.0), vec3(1.0/m2));
    return 10000.0 * pow(max(p - c1, 0.0) / (c2 - c3 * p), vec3(1.0/m1));
}
vec3 hlg_transfer(vec3 rgb, vec4 params, bool encode) {
    float peak = params.y, gamma = params.z, beta = params.w;
    if (!encode) {
        vec3 x = (1.0 - beta) * clamp(rgb, 0.0, 1.0) + beta;
        vec3 scene = mix((exp((x - 0.55991073) / 0.17883277) + 0.28466892) / 12.0,
                        x * x / 3.0, lessThanEqual(x, vec3(0.5)));
        float y = luminance(scene);
        return y > 0.0 ? scene * peak * pow(max(y, 1e-20), gamma - 1.0) : vec3(0.0);
    }
    float y = max(luminance(rgb) / peak, 0.0);
    vec3 x = clamp(y > 0.0 ? rgb * pow(max(y, 1e-20), (1.0 - gamma) / gamma) / peak : vec3(0.0), 0.0, 1.0);
    vec3 signal = mix(0.17883277 * log(max(12.0 * x - 0.28466892, 1e-20)) + 0.55991073,
                      sqrt(3.0 * x), lessThanEqual(x, vec3(1.0/12.0)));
    return clamp((signal - beta) / (1.0 - beta), 0.0, 1.0);
}
vec3 transfer(vec3 rgb, uint tag, vec4 params, bool encode) {
    if (tag == 1u) return encode ? srgb_transfer(rgb / params.x, true) : srgb_transfer(rgb, false) * params.x;
    if (tag == 2u) return encode ? rgb / params.x : rgb * params.x;
    if (tag == 3u) return pq_transfer(rgb, encode);
    if (tag == 6u) {
        if (encode) return (pow(max(rgb / params.x, 0.0), vec3(1.0/2.4)) - params.w) / (1.0 - params.w);
        return pow(max(rgb * (1.0 - params.w) + params.w, 0.0), vec3(2.4)) * params.x;
    }
    return hlg_transfer(rgb, params, encode);
}
vec4 color_decode(vec4 rgba) {
    float a = cp.head.w == 1u ? 1.0 : clamp(rgba.a, 0.0, 1.0);
    vec3 rgb = rgba.rgb * cp.ranges.x + cp.ranges.y;
    if (cp.head.w == 3u) rgb /= a > 0.0 ? a : 1.0;
    rgb = transfer(rgb, cp.head.y, cp.source_light, false);
    if (cp.head.w != 4u) rgb *= a;
    rgb = a > 0.0 ? vec3(dot(cp.source0.xyz, rgb), dot(cp.source1.xyz, rgb), dot(cp.source2.xyz, rgb)) : vec3(0.0);
    return vec4(rgb, a);
}
vec3 gamut(vec3 rgb, float y, float peak) {
    float gray = clamp(y, 0.0, peak), saturation = 1.0;
    for (int i = 0; i < 3; ++i) {
        float delta = rgb[i] - gray;
        if (delta != 0.0) saturation = min(saturation, delta > 0.0 ? (peak - gray) / delta : -gray / delta);
    }
    return gray + (rgb - gray) * saturation;
}
float ordered_dither() {
    uvec2 p = uvec2(gl_FragCoord.xy); uint index = 0u;
    for (uint bit = 0u; bit < 3u; ++bit) {
        uvec2 digit = (p >> bit) & 1u;
        index |= (((digit.x ^ digit.y) << 1u) | digit.y) << (2u * (2u - bit));
    }
    return (float(index) - 31.5) / 64.0;
}
vec4 color_encode(vec4 rgba, float opacity) {
    vec3 rgb = rgba.rgb * cp.tone.x * opacity; float a = rgba.a * opacity;
    bool output_mapping = (cp.head.x & 1u) != 0u;
    if (output_mapping) {
        float y = luminance(rgb) / (a > 0.0 ? a : 1.0);
        float mapped = min(y, cp.tone.y), excess = max(mapped - cp.tone.z, 0.0);
        if (excess > 0.0) mapped = cp.tone.z + excess / (1.0 + cp.tone.w * excess);
        if (y > 0.0) rgb *= min(mapped, cp.target.x) / y;
    }
    float target_a = cp.tail.x == 1u ? 1.0 : a, safe_a = target_a > 0.0 ? target_a : 1.0;
    vec3 result = vec3(dot(cp.target0.xyz, rgb), dot(cp.target1.xyz, rgb), dot(cp.target2.xyz, rgb));
    if (output_mapping) result = gamut(result / safe_a, luminance(rgb) / safe_a, cp.target.x) * target_a;
    if (cp.tail.x != 4u) result /= safe_a;
    result = transfer(result, cp.head.z, cp.target_light, true);
    if (cp.tail.x == 3u) result *= target_a;
    if (target_a <= 0.0) result = vec3(0.0);
    result = result * cp.ranges.z + cp.ranges.w;
    if ((cp.head.x & 2u) != 0u) result += ordered_dither() * cp.target.y;
    return vec4(result, target_a);
}
