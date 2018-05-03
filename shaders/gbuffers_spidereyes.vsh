#version 400 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;
layout (location = 12) in vec4 inTangent;

out vec4 color;
out vec2 uvcoord;
out vec2 lmcoord;
out vec3 normal;
out vec4 metadata;

uniform mat4 gbufferProjection;

void main(){
    gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);

    color = inColor;
    uvcoord = inTexCoord.xy;
    lmcoord = inLightmapCoord.st / 240.0;
    normal = normalize(gl_NormalMatrix * inNormal.xyz);
}