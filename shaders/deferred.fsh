#version 400

#define texture(buffer, vec2) texture2D(buffer, vec2)

#define getLandMask(x) (x < 1.0)

/* DRAWBUFFERS:0 */

layout (location = 0) out vec4 color;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB32F;
const int colortex4Format = RGB32F;
const int colortex7Format = RGB16F;
*/

in vec2 texcoord;

in vec3 sunVector;
in vec3 sunVector2;
in vec3 moonVector;
in vec3 lightVector;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
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
    return float(texture(shadowtex0, pos.st).r > pos.p - 0.00015 / distort);
}

float shadow_transparent(in vec3 pos, in float distort) {
    return float(texture(shadowtex1, pos.st).r > pos.p - 0.00015 / distort);
}

vec4 shadow_color(in vec3 pos) {
    return texture(shadowcolor0, pos.st);
}

vec4 shadow_map(in vec3 pos, in float id) {
    float distortionFactor = 1.0 / ShadowDistortion(pos.st);
    float shadowOpaque = shadow_opaque(pos, distortionFactor*distortionFactor);
    float shadowTransparent = shadow_transparent(pos, distortionFactor*distortionFactor);
    vec4 shadowColor = shadow_color(pos);
    return mix(vec4(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
}

vec4 get_shading(in vec4 color, in vec3 world, in float id) {

    mat4 shadowMVP = shadowProjection * shadowModelView;
    vec4 shadowPos  = shadowMVP * vec4(world, 1.0);

    shadowPos.xy /= ShadowDistortion(shadowPos.st);
    shadowPos.z /= 6.0;

    shadowPos = shadowPos * 0.5 + 0.5;

    vec3 normal = decodeNormal3x16(texture(colortex4, texcoord.st).g);

    vec2 lightmap = decode2x16(texture(colortex4, texcoord.st).r);

    vec4 shadows = vec4(0.0);
    vec4 lighting = vec4(0.0);

    float NdotL = dot(normal, lightVector);
    float NdotU = dot(normal, mat3(gbufferModelViewInverse) * upVector);
    float diffuse = max(0.0, NdotL);

    if(id == 18.0 || id == 31.0 || id == 37.0 || id == 38.0 || id == 161.0 || id == 175.0) diffuse = 1.0;

    shadows += shadow_map(shadowPos.xyz, id);

    vec4 colorDirect = color;
    vec4 colorSky = color;

    atmosphere(colorDirect.rgb, lightVector.xyz, sunVector, moonVector, ivec2(8, 2));
    atmosphere(colorSky.rgb, mat3(gbufferModelViewInverse) * upVector, sunVector, moonVector, ivec2(8, 2));

    lighting = (colorDirect * diffuse) * shadows + lighting;
    lighting.rgb = (blackbody(2800)) * pow(lightmap.x, 2.0) + lighting.rgb;
    lighting = pow(lightmap.y, 6.5) * (colorSky) * (vec4(0.93636, 1.5606, 2.40908, 0.0) / 3.0) + lighting;

    color = color * lighting;
    return color;
}

vec3 skyColor() {
    return vec3(0.0);
}

void main() {
    color = texture2D(colortex0, texcoord);
    float id = texture(colortex4, texcoord.st).b * 65535.0;
    float depth = texture2D(depthtex1, texcoord.st).r;

    vec4 view = vec4(vec3(texcoord.st, depth) * 2.0 - 1.0, 1.0);
    view = gbufferProjectionInverse * view;
    view /= view.w;
    view.xyz = normalize(view.xyz);

    vec4 view2 = vec4(vec3(texcoord.st, depth) * 2.0 - 1.0, 1.0);
    view2 = gbufferProjectionInverse * view2;
    view2 /= view2.w;
    vec4 world = gbufferModelViewInverse * view2;
    world /= world.w;

    color.rgb = pow(color.rgb, vec3(2.2));

    vec4 colorSky = color;

    if(getLandMask(depth)) color = get_shading(color, world.xyz, id);

    if(!getLandMask(depth)){
        atmosphere(color.rgb, world.xyz, sunVector, moonVector, ivec2(8, 2));
    }
}