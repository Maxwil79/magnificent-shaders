#version 400

#define texture(buffer, vec2) texture2D(buffer, vec2)

#define getLandMask(x) (x < 1.0)

#define textureRaw(sampler, coord) texelFetch(sampler, ivec2(coord * textureSize(sampler, 0)), 0)

#define Deferred

#include "lib/macros.glsl"

/* AO Settings */
#define AORaytraceQuality 16.0 //[2.0 4.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0 20.0 22.0 24.0 26.0 28.0 30.0 32.0 34.0 36.0 38.0 40 42.0 44.0 46.0 48.0 50.0]
#define SSAO_Samples 5 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70]
#define SSRTAO_Samples 16 //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70]
int stepCountAMB = 6;

/* DRAWBUFFERS:0 */

layout (location = 0) out vec4 color;

/*
const int colortex0Format = RGBA16F;
const int colortex3Format = RGBA16F;
const int colortex4Format = RGBA32F;
const int colortex5Format = RGBA32F;
const int colortex7Format = RGBA16F;
*/

const bool colortex3Clear = false;
const bool colortex7Clear = false;

in vec2 texcoord;

in vec3 sunVector;
in vec3 sunVector2;
in vec3 moonVector;
in vec3 moonVector2;
in vec3 lightVector;
in vec3 lightVector2;
in vec3 sunLight;
in vec3 skyLight;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D noisetex;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;

uniform float wetness;
uniform float sunAngle;
uniform float viewWidth, viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;

vec2 screenRes = vec2(viewWidth, viewHeight);

const float wetnessHalflife = 2.0;

const float pi  = 3.14159265358979;
const float tau = pi*2;

const float sunPathRotation = -55.0;
const int shadowMapResolution = 2048;
const float shadowDistance = 256.0;

mat4 newShadowModelView = mat4(
    1, 0, 0, shadowModelView[0].w,
    0, 0, 1, shadowModelView[1].w,
    0, 1, 0, shadowModelView[2].w,
    shadowModelView[3]
);

vec3 upVector = gbufferModelView[1].xyz;

float bayer2(vec2 a){
    a = floor(a);
    return fract( dot(a, vec2(.5, a.y * .75)) );
}
#define bayer4(a)   (bayer2( .5*(a))*.25+bayer2(a))
#define bayer8(a)   (bayer4( .5*(a))*.25+bayer2(a))
#define bayer16(a)  (bayer8( .5*(a))*.25+bayer2(a))
#define bayer32(a)  (bayer16(.5*(a))*.25+bayer2(a))
#define bayer64(a)  (bayer32(.5*(a))*.25+bayer2(a))
#define bayer128(a) (bayer64(.5*(a))*.25+bayer2(a))

#include "lib/util.glsl"

#include "lib/encoding/decode.glsl"

#include "lib/blackbody.glsl"
#include "lib/newSky.glsl"

#include "lib/distortion.glsl"

float shadow_opaque(in vec3 pos, in float distort) {
    return float(texture(shadowtex0, pos.st).r > pos.p - 0.008 / distort);
}

float shadow_transparent(in vec3 pos, in float distort) {
    return float(texture(shadowtex1, pos.st).r > pos.p - 0.008 / distort);
}

vec4 shadow_color(in vec3 pos) {
    return texture(shadowcolor0, pos.st);
}

vec4 shadow_map(in vec3 pos, in float id, in float distortionFactor) {
    float shadowOpaque = shadow_opaque(pos, distortionFactor*distortionFactor);
    float shadowTransparent = shadow_transparent(pos, distortionFactor*distortionFactor);
    vec4 shadowColor = shadow_color(pos);
    return mix(vec4(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
}

vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);

}

float ssao(vec3 position, vec3 normal) {
    float dither = bayer8(gl_FragCoord.st);
    float result = 0.0;
    for(float i = -0.0; i <= SSAO_Samples; i++){
        vec4 noise = hash42(vec2(i, dither));
        vec3 offset = normalize(noise.xyz * 2.0 - 1.0) * noise.w;
        if (dot(offset, normal) < 0.0) offset = -offset;
        vec3 samplePosition = offset * 0.5 + position;
        samplePosition = viewSpaceToScreenSpace(samplePosition, gbufferProjection);
        float depth = texture(depthtex1, samplePosition.st).r;

        if (depth > samplePosition.z) result += 1.1;
    }
    result /= SSAO_Samples;
    return result;
}

#include "lib/raytrace.glsl"

#define AO 0 //[0 1 2] Higher means lower FPS.

#include "lib/water.glsl"

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

float SSRTAO(vec3 pos, vec3 normal) {
	float occlusion = 0.0;
	for (int i = 0; i < SSRTAO_Samples; i += 1) {
		vec3 direction = normalize(hash33(frameTimeCounter + pos.xyz + i) * 2.0 - 1.0);
		if (dot(direction, normal) < 0.0) direction *= -1.0;
        vec3 hit;
		occlusion += float(raytraceIntersection(pos, direction, hit, AORaytraceQuality, 6.0));
	}
	return 1.0 - (occlusion / SSRTAO_Samples);
}

const vec2[16] poissonDisk = vec2[16]
(
	vec2(0.9553798f, 0.08792616f),
	vec2(0.7564816f, 0.6107687f),
	vec2(0.4300687f, -0.339003f),
	vec2(0.2410402f, 0.398774f),
	vec2(0.07018216f, -0.8776324f),
	vec2(-0.2103648f, -0.3532368f),
	vec2(0.8417408f, -0.5299217f),
	vec2(0.1464538f, -0.0502334f),
	vec2(0.5003511f, -0.7529236f),
	vec2(-0.132682f, 0.6056585f),
	vec2(-0.2401425f, 0.1240332f),
	vec2(0.3478812f, 0.8243276f),
	vec2(-0.8337253f, 0.1119805f),
	vec2(-0.6568771f, -0.3930125f),
	vec2(-0.6461575f, 0.7098891f),
	vec2(-0.3569236f, -0.9252638f)
);

float linearizeDepth(float depth) {
    return -1.0 / ((depth * 2.0 - 1.0) * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}


#define HSSRS_RAY_STEPS  16   // [16 24 32 48 64]
#define HSSRS_RAY_LENGTH 0.25 // [0.25 0.50]

float calculateHSSRS(vec3 viewSpace, vec3 lightVector) {
	vec3 increment = lightVector * HSSRS_RAY_LENGTH / HSSRS_RAY_STEPS;

	for (uint i = 0; i < HSSRS_RAY_STEPS; i++) {
		viewSpace += increment;

		vec3 screenSpace = viewSpaceToScreenSpace(viewSpace, gbufferProjection);
		if (any(greaterThan(abs(screenSpace - 0.5), vec3(0.5)))) return 1.0;

		float diff = viewSpace.z - linearizeDepth(texture(depthtex1, screenSpace.xy).r);
		if (diff < 0.005 * viewSpace.z && diff > 0.05 * viewSpace.z) return i / HSSRS_RAY_STEPS;
	}

	return 1.0;
}

#define LightingOnly 0 //[0 1]
#define AoOnly 0 //[0 1]

#define BlocklightColor 0 //[0 1 2 3 4]

float hash12(vec2 p){
    p  = fract(p * .1031);
    p += dot(p, p.yx + 19.19);
    return fract(p.x * (p.x + p.y));
}

float dither2=hash12(texcoord*vec2(viewWidth,viewHeight));

float Burley(vec3 V, vec3 L, vec3 N, float r) {
    r *= r;
    
    vec3 H = normalize(V + L);
    
    float NdotL = clamp(dot(N, L),0.,1.);
    float LdotH = clamp(dot(L, H),0.,1.);
    float NdotV = clamp(dot(N, V),0.,1.);

    float energyFactor = -r * .337748344 + 1.;
    float f90 = 2. * r * (LdotH*LdotH + .25) - 1.;

    float lightScatter =  f90 * pow(1.-NdotL,5.) + 1.;
    float viewScatter  =  f90 * pow(1.-NdotV,5.) + 1.;
    
    return NdotL * energyFactor * lightScatter * viewScatter;

}

vec4 get_shading(in vec4 color, in vec3 world, in float id, in vec3 view) {

    mat4 shadowMVP = shadowProjection * shadowModelView;
    vec4 shadowPos  = shadowMVP * vec4(world, 1.0);

    float distortionFactor = 1.0 / ShadowDistortion(shadowPos.st);

    shadowPos.xy /= ShadowDistortion(shadowPos.st);
    shadowPos.z /= 4.0;

    shadowPos = shadowPos * 0.5 + 0.5;

    vec2 sky_coord = texcoord * 2.0 - vec2(1, 0);

    vec3 normal = unpackNormal(texture(colortex5, texcoord.st).gb);

    vec2 lightmap = decode2x16(texture(colortex4, texcoord.st).r);
    lightmap *= lightmap;

    vec4 shadows = vec4(0.0);
    vec4 lighting = vec4(0.0);

    float NdotL = dot(normal, lightVector2);
    float NdotU = dot(normal, upVector);
    float diffuse = max(0.0, NdotL);

    if(id == 18.0 || id == 31.0 || id == 37.0 || id == 38.0 || id == 161.0 || id == 175.0 || id == 59.0) diffuse = 1.0;

    float noise = fract(sin(dot(texcoord.xy, vec2(18.9898f, 28.633f))) * 4378.5453f) * 4.0 / 5.0;
    mat2 noiseM = mat2(cos(noise), -sin(noise),
						   sin(noise), cos(noise));

	mat2 rot = noiseM;

    for(int i = 0; i < poissonDisk.length(); ++i) {
        vec2 offset = 0.002 * poissonDisk[i] * texture(noisetex, (gl_FragCoord.st / 2)).r;
        vec3 sampleOffset = vec3(offset + shadowPos.xy, shadowPos.z);
        shadows += shadow_map(sampleOffset, id, distortionFactor);
    }
    shadows /= poissonDisk.length();

    float waterShadowCast = float(texture(shadowcolor1, shadowPos.st).r);

    vec3 scatterCol = vec3(0.0);

    vec4 colorDirect = vec4(sunLight, 1.0);
    vec4 colorSky = vec4(skyLight, 1.0);

    float spiderEyes = texture(colortex4, texcoord.st).g;

    #ifdef HSSRS
    float screenSpaceShadows = calculateHSSRS(view.xyz, lightVector2);
    #else
    float screenSpaceShadows = 1.0;
    #endif

    lighting = (colorDirect * diffuse) * shadows * screenSpaceShadows + lighting;

    #if AO == 1
    float ao = pow(ssao(view, unpackNormal(texture(colortex5, texcoord.st).gb)), 3.0);

    ao /= 3;
    #elif AO == 2
    float ao = SSRTAO(vec3(texcoord, texture(depthtex1, texcoord.st).r), unpackNormal(texture(colortex5, texcoord.st).gb));
    #elif AO == 0
    float ao = 1.0;
    #endif

    #if BlocklightColor == 0
    vec3 torchColor = blackbody(2600);
    #elif BlocklightColor == 1
    vec3 torchColor = vec3(1.0);
    #elif BlocklightColor == 2
    vec3 torchColor = vec3(0.1, 0.5, 0.65);
    #elif BlocklightColor == 3
    vec3 torchColor = vec3(0.7, 0.05, 1.0);
    #elif BlocklightColor == 4
    vec3 torchColor = vec3(1.0, 0.1, 0.05);
    #endif

    if(spiderEyes == 1.0) {
        lighting.rgb = vec3(0.15) * pow(lightmap.x, 2.5) + lighting.rgb;
    } else {
        lighting.rgb = torchColor * pow(lightmap.x, 1.5) * ao + lighting.rgb;
    }

    lighting = pow(lightmap.y, 4.0) * (colorSky) * ao + lighting;

    vec3 emission = color.rgb;

    if (id == 10.0 || id == 11.0 || id == 51.0 || id == 89.0) {
        emission *= sqrt(dot(color.rgb, color.rgb)) * 0.05;
    } else if (id == 50.0) {
        emission *= pow(max(dot(color.rgb, color.rgb) * 1.3 - 0.3, 0.0), 0.0005) / 1.0;
    } else if (id == 62.0 || id == 94.0 || id == 149.0) {
         emission *= max(color.r * 5.6 - 0.6, 0.0) * abs(dot(color.rgb, vec3(1.0 / 3.0)) - color.r);
    } else if (id == 76.0 || id == 213.0) {
         emission *= max(color.r * 1.6 - 0.6, 0.0);
    } else if (id == 169.0) {
        emission *= pow(max(dot(color.rgb, color.rgb) * 1.3 - 0.3, 0.0), 2.0);
    } else if (id == 124.0) {
        emission *= sqrt(max(dot(color.rgb, color.rgb) * 1.01 - 0.01, 0.0));
    } else {
        emission *= 0.0;
    }

    #if AoOnly == 1 && LightingOnly == 1
    lighting = colorSky * ao;
    #endif

    #if LightingOnly == 0
    color = color * lighting + vec4(emission, 1.0);
    #elif LightingOnly == 1
    color = lighting;
    #endif
    return color;
}

#undef LightingOnly

#include "lib/sun.glsl"
#include "lib/moon.glsl"

#undef AO
#undef AoOnly
#undef SSRTAO
#undef SSRTAO_Samples

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

    if(getLandMask(depth)) color = get_shading(color, world.xyz, id, view2.xyz);

    vec3 scatterCol = vec3(0.0);

    if(!getLandMask(depth)){
        vec3 background = (calculateSun(sunVector2, normalize(view.xyz), vec3(1.0), SunSize) + calculateMoon(moonVector2, normalize(view.xyz)));
        color.rgb = atmos(normalize(world.xyz), scatterCol, background, SkySteps);
    }
}