#version 450
#extension GL_GOOGLE_include_directive : require
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include "coordinates.glsl"
layout(location=0) out vec4 color;
void main() { color = draw.tint; }
