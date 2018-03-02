#version 420

#define varying out

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
out vec3 sunVector2;
out vec3 moonVector2;

varying vec4 timeVector;

float pow2(in float n)  { return n * n; }
#define max0(n) max(0.0, n)
#define min1(n) min(1.0, n)

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

#define clamp01(n) clamp(n, 0.0, 1.0)

void main() {
    gl_Position = vec4(signed(inPosition), 0.0, 1.0);

    sunVector = normalize(sunPosition); 
    moonVector = normalize(moonPosition); 
    lightVector = normalize(shadowLightPosition);

    sunVector2 = mat3(gbufferModelViewInverse) * sunPosition        * 0.01; 
    moonVector2 = mat3(gbufferModelViewInverse) * moonPosition        * 0.01;

    lightVector = (sunAngle > 0.5) ? moonVector : sunVector;
    worldLightVector = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);

    textureCoordinate = inTexCoord;

    vec2 noonNight   = vec2(0.0);
     noonNight.x = (0.25 - clamp(sunAngle, 0.0, 0.5));
     noonNight.y = (0.75 - clamp(sunAngle, 0.5, 1.0));

    // NOON
    timeVector.x = 1.0 - clamp01(pow2(abs(noonNight.x) * 4.0));
    // NIGHT
    timeVector.y = 1.0 - clamp01(pow(abs(noonNight.y) * 4.0, 128.0));
    // SUNRISE/SUNSET
    timeVector.z = 1.0 - (timeVector.x + timeVector.y);
    // MORNING
    timeVector.w = 1.0 - ((1.0 - clamp01(pow2(max0(noonNight.x) * 4.0))) + (1.0 - clamp01(pow(max0(noonNight.y) * 4.0, 128.0))));
}