#version 450
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Vertex/index draws use the same descriptor ABI. Vertices are clip-space vec4.
layout(set=0,binding=2,std430) readonly buffer Vertices { vec4 positions[]; } vertex;
void main() { gl_Position = vertex.positions[gl_VertexIndex]; }
