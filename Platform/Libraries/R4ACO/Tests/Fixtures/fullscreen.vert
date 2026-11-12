#version 450
void main() {
   uint i=uint(gl_VertexIndex);
   gl_Position=vec4(vec2((i<<1u)&2u,i&2u)*2.0-1.0,0.0,1.0);
}
