#version 400

#define getLandMask(x) (x < 1.0)

/* DRAWBUFFERS:0 */

layout (location = 0) out vec4 color;

/*
const int colortex2Format = RGBA16F;
*/

in vec2 texcoord;

in vec3 sunVector;
in vec3 sunVector2;
in vec3 moonVector;
in vec3 lightVector;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform float sunAngle;
uniform float viewWidth, viewHeight;
uniform float frameTimeCounter;

vec2 screenRes = vec2(viewWidth, viewHeight);

const float pi  = 3.14159265358979;
const float tau = pi*2;

const float sunPathRotation = -40.0;
const int shadowMapResolution = 2048;
const float shadowDistance = 256.0;

mat4 newShadowModelView = mat4(
    1, 0, 0, shadowModelView[0].w,
    0, 0, 1, shadowModelView[1].w,
    0, 1, 0, shadowModelView[2].w,
    shadowModelView[3]
);

vec3 upVector = gbufferModelView[1].xyz;

#include "lib/util.glsl"

#include "lib/encoding/decode.glsl"

#include "lib/blackbody.glsl"
#include "lib/newSky.glsl"

#include "lib/distortion.glsl"

float shadow_opaque(in vec3 pos, in float distort) {
    return float(texture(shadowtex0, pos.st).r > pos.p - 0.000055 * distort);
}

float shadow_transparent(in vec3 pos, in float distort) {
    return float(texture(shadowtex1, pos.st).r > pos.p - 0.000055 * distort);
}

vec3 shadow_color(in vec3 pos) {
    return texture(shadowcolor0, pos.st).rgb;
}

vec3 shadow_map(in vec3 pos) {
    float distortionFactor = 1.0 / ShadowDistortion(pos.st);
    float shadowOpaque = shadow_opaque(pos, distortionFactor*distortionFactor);
    float shadowTransparent = shadow_transparent(pos, distortionFactor*distortionFactor);
    vec3 shadowColor = shadow_color(pos);
    return mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
}

vec3 get_shading(in vec4 color, in vec3 world) {

    mat4 shadowMVP = shadowProjection * shadowModelView;
    vec4 shadowPos  = shadowMVP * vec4(world, 1.0);

    shadowPos.xy /= ShadowDistortion(shadowPos.st);
    shadowPos.z /= 6.0;

    shadowPos = shadowPos * 0.5 + 0.5;

    vec3 normal = unpackNormal(texture(colortex1, texcoord.st).rg);

    vec2 lightmap = decode2x16(texture(colortex4, texcoord.st).r);

    vec3 shadows = vec3(0.0);
    vec3 lighting = vec3(0.0);

    float NdotL = dot(normal, lightVector);
    float diffuse = max(0.0, NdotL);

    shadows += shadow_map(shadowPos.xyz);

    vec4 colorDirect = color;
    vec4 colorSky = color;

    #if FastSky == 0
    int sampleIN = 16;
    int sampleOUT = 6;
    #elif FastSky == 1
    int sampleIN = 6;
    int sampleOUT = 2;
    #endif

    useAtmosphereDirect(colorDirect, lightVector.xyz, sampleIN, sampleOUT);
    useAtmosphereAmbient(colorSky, mat3(gbufferModelViewInverse) * upVector, sampleIN, sampleOUT);

    lighting = (colorDirect.rgb * diffuse) * shadows + lighting;
    lighting = (blackbody(2400)) * pow(lightmap.x, 3.5) + lighting;
    lighting = pow(lightmap.y, 8.5) * colorSky.rgb * (vec3(2.3409, 3.9015, 6.0227) / 3.0) + lighting;

    color.rgb = color.rgb * lighting;
    return color.rgb;
}

void main() {
    color = texture(colortex0, texcoord.st);
    vec4 transparents = texture(colortex2, texcoord.st);

    transparents.rgb = pow(transparents.rgb, vec3(2.2));

    float depth = texture(depthtex0, texcoord.st).r;

    vec4 view2 = vec4(vec3(texcoord.st, depth) * 2.0 - 1.0, 1.0);
    view2 = gbufferProjectionInverse * view2;
    view2 /= view2.w;
    vec4 world = gbufferModelViewInverse * view2;
    world /= world.w;

    color.rgb = mix(color.rgb, get_shading(transparents, world.xyz), transparents.a);
}