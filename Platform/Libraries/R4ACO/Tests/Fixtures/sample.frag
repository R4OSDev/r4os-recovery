#version 450
layout(set=1,binding=0) uniform sampler2D source_image;
layout(push_constant) uniform Params { vec4 mapping; float opacity; } pc;
layout(location=0) out vec4 color;
void main() {
   vec2 uv=gl_FragCoord.xy*pc.mapping.xy+pc.mapping.zw;
   color=textureLod(source_image,uv,0.0)*pc.opacity;
}
