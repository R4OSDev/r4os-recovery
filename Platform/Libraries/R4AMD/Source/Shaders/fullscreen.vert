#version 450
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// The draw viewport places this triangle; no per-frame vertex upload is needed.
void main() {
    uint i = uint(gl_VertexIndex);
    gl_Position = vec4(vec2((i << 1u) & 2u, i & 2u) * 2.0 - 1.0, 0.0, 1.0);
}
