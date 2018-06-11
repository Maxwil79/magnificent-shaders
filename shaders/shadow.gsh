#version 330 compatibility

layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

in float[3] isWater;
in float[3] isPortal;
in vec2[3] uvcoord;
in mat3[3] tbn;
in vec4[3] viewPosition;
in vec4[3] worldPosition;
in vec3[3] light;

out float water;
out float portal;
out vec2 texcoord;
out mat3 tbnMtrix;
out vec4 viewPos;
out vec4 worldPos;
out vec3 lightPos;

void main() {
    for (int i = 0; i < 3; ++i) {
        gl_Position = gl_in[i].gl_Position;
        water = isWater[i];
        portal = isPortal[i];
        texcoord = uvcoord[i];
        tbnMtrix = tbn[i];
        viewPos = viewPosition[i];
        worldPos = worldPosition[i];
        lightPos = light[i];
        EmitVertex();
    }
    EndPrimitive();
}