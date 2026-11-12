#version 450
layout(location=0) out vec4 color;
layout(push_constant) uniform Constants { vec4 rgba; } pc;
void main() { color=pc.rgba; }
