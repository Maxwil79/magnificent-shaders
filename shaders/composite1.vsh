#version 400

layout (location = 0) in vec2 inPosition;
layout (location = 8) in vec2 inTexCoord;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;

uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;

uniform float sunAngle;

out vec2 texcoord;
out vec3 lightVector;
out vec3 lightVector2;
out vec3 sunVector;
out vec3 sunVector2;
out vec3 moonVector;
out vec3 moonVector2;

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

void main() {
    gl_Position = vec4(inPosition.xy * 2.0 - 1.0, 0.0, 1.0);

    sunVector = mat3(gbufferModelViewInverse) * normalize(sunPosition);
    sunVector2 = normalize(sunPosition);
    moonVector = mat3(gbufferModelViewInverse) * normalize(moonPosition);
    moonVector2 = normalize(moonPosition);
    lightVector = normalize(shadowLightPosition);

    lightVector = (sunAngle > 0.5) ? moonVector : sunVector;
    lightVector2 = (sunAngle > 0.5) ? moonVector2 : sunVector2;

    texcoord = inPosition.xy;
}