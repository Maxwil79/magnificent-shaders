#version 400

#define VERTEX

#include "lib/macros.glsl"

int stepCountAMB = 6;

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
out vec3 worldLightVector;
out vec3 sunVector;
out vec3 sunVector2;
out vec3 moonVector;
out vec3 moonVector2;
out vec3 sunLight;
out vec3 skyLight;

uniform mat4 gbufferModelView;
vec3 upVector = gbufferModelView[1].xyz;

uniform vec3 cameraPosition;
uniform float rainStrength;
const float pi  = 3.14159265358979;

#include "lib/blackbody.glsl"

#include "lib/newSky.glsl"

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

void main() {
    gl_Position = vec4(inPosition.xy * 2.0 - 1.0, 0.0, 1.0);

    sunVector = mat3(gbufferModelViewInverse) * normalize(sunPosition * 0.01);
    sunVector2 = normalize(sunPosition * 0.01);
    moonVector = mat3(gbufferModelViewInverse) * normalize(moonPosition * 0.01);
    moonVector2 = normalize(moonPosition * 0.01);
    lightVector = normalize(shadowLightPosition);
    lightVector2 = normalize(shadowLightPosition);

    lightVector = (sunAngle > 0.5) ? moonVector : sunVector;
    //lightVector2 = (sunAngle > 0.5) ? moonVector2 : sunVector2;
    worldLightVector = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

    texcoord = inPosition.xy;

    sunLight = get_sunlightColor();
    skyLight = atmosAmbient(mat3(gbufferModelViewInverse) * upVector);
}