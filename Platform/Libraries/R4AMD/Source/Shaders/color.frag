#version 450
#extension GL_GOOGLE_include_directive : require
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include "coordinates.glsl"
#include "color.glsl"
layout(set=1,binding=0) uniform sampler2D source_image;
layout(location=0) out vec4 color;
void main() { color = color_encode(color_decode(textureLod(source_image, coordinates(), 0.0)), draw.tint.a); }
