#version 420

layout (location = 0) in vec2 inPosition;
layout (location = 8) in vec2 inTexCoord;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

uniform float sunAngle;

out vec2 textureCoordinate;
out vec3 lightVector;
out vec3 worldLightVector;
out vec3 sunVector;
out vec3 moonVector;

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

void main() {
    gl_Position = vec4(inPosition.xy * 2.0 - 1.0, 0.0, 1.0);

    sunVector = normalize(sunPosition); 
    moonVector = normalize(moonPosition); 
    lightVector = normalize(shadowLightPosition);

    lightVector = (sunAngle > 0.5) ? moonVector : sunVector;
    worldLightVector = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

    textureCoordinate = inPosition.xy;
}