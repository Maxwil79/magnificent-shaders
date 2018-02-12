#version 450

//#define VolumetricFog //Enable this for VL. Highly experimental.
    #define AccumulationStrength 0.7 //[0.7 0.6 0.5 0.4 0.3 0.2 0.1 0.09 0.08 0.07 0.06 0.05 0.04 0.03 0.02 0.01 0.009 0.008 0.007 0.006 0.005 0.004 0.003 0.002 0.001] Controls the strength of the temporal accumulation. A lower number means more accumulation. 

#define SSR
    #define SsrSamples 1 //[1 2 4 8 16 32 64 128 256 512]
    #define RoughnessValue 0.1 //[0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05 0.055 0.06 0.065 0.07 0.075 0.08 0.085 0.09 0.095 0.1]

#define RefractionMode 1 //[0 1] 0 = no waterfog, only raytraced refractions. 1 = waterfog, non-raytraced refractions. 2 = unrealistic refraction, has the least amount of artifacts. Mode 2 is not added yet. Higher means more stable refraction, and faster, refraction. Lower means less stable, and slower, refraction.

#define texture2D(sampler, vec2) texture(sampler, vec2)
#define texture2DLod(sampler, vec2, float) textureLod(sampler, vec2, float)
#define varying in

#define FogSteps 8 //[1 2 4 8 16 32 64 128 256 512 1024] Higher means higher quality but less performance.

/*DRAWBUFFERS: 03*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 volume;

const float pi  = 3.14159265358979;

in vec2 textureCoordinate;
in vec3 lightVector;
in vec3 worldLightVector;
in vec3 sunVector;
in vec3 moonVector;

varying vec4 timeVector;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;

uniform int isEyeInWater;

uniform ivec2 eyeBrightnessSmooth;

uniform float far;
uniform float viewHeight, viewWidth;
uniform float frameTimeCounter;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;
uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;
uniform mat4 gbufferProjection, gbufferModelView;

const int noiseTextureResolution = 96;

const bool colortex3Clear = false;

const bool colortex0MipmapEnabled = true;

float square (float x) { return x * x; }
vec2  square (vec2  x) { return x * x; }
vec3  square (vec3  x) { return x * x; }
vec4  square (vec4  x) { return x * x; }

#define inverseSquare(x) (1.0 / square(x))

vec3 blackbody(float t){
    // http://en.wikipedia.org/wiki/Planckian_locus

    vec4 vx = vec4( -0.2661239e9, -0.2343580e6, 0.8776956e3, 0.179910   );
    vec4 vy = vec4( -1.1063814,   -1.34811020,  2.18555832, -0.20219683 );
    //vec4 vy = vec4(-0.9549476,-1.37418593,2.09137015,-0.16748867); //>2222K
    float it = 1. / t;
    float it2= it * it;
    float x = dot( vx, vec4( it*it2, it2, it, 1. ) );
    float x2 = x * x;
    float y = dot( vy, vec4( x*x2, x2, x, 1. ) );
    
    // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
    mat3 xyzToSrgb = mat3(
         3.2404542,-1.5371385,-0.4985314,
        -0.9692660, 1.8760108, 0.0415560,
         0.0556434,-0.2040259, 1.0572252
    );

    vec3 srgb = vec3( x/y, 1., (1.-x-y)/y ) * xyzToSrgb;

    return max( srgb, 0. );
}

#include "dither.glsl"

#include "lib/decode.glsl"

#include "lib/raysphereIntersections/raysphereIntersection.glsl"
#include "lib/atmosphere/physicalAtmosphere.glsl"

#include "lib/atmosphere/physicalSun.glsl"
#include "lib/atmosphere/physicalMoon.glsl"

#define getLandMask(x) (x < 1.0)

#include "lib/util.glsl"

#include "lib/rays/rayTracers.glsl"

#include "lib/light/distortion.glsl"

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

vec3 clampNormal(vec3 n, vec3 v){
    return dot(n, v) >= 0.0 ? cross(cross(v, n), v) : n;
}

float GGX (vec3 n, vec3 v, vec3 l, float r, float F0) {
  r*=r;r*=r;
  
  vec3 h = l + v;
  float hn = inversesqrt(dot(h, h));

  float dotLH = clamp(dot(h,l)*hn,0.,1.);
  float dotNH = clamp(dot(h,n)*hn,0.,1.);
  float dotNL = clamp(dot(n,l),0.,1.);
  
  float denom = (dotNH * r - dotNH) * dotNH + 1.;
  float D = r / (pi * denom * denom);
  float F = F0 + (1. - F0) * exp2((-5.55473*dotLH-6.98316)*dotLH);
  float k2 = .25 * r;

  return dotNL * D * F / (dotLH*dotLH*(1.0-k2)+k2);
}

vec3 reflection(in vec3 view) {
    vec3 reflection = vec3(0.0);
    int i = 0;
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;
    //vec2 lightmap = texture(colortex2, textureCoordinate).rg;
    vec3 viewVec3 = vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r);
    int samples = SsrSamples;
    float shadows = texture(colortex0, textureCoordinate.st).a;
    float skyLight = decode2x16(texture(colortex4, textureCoordinate.st).r).y;
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);

    float schlick = (1.0 - 0.02) * pow(1.0 - clamp(dot(-normalize(viewPosition.xyz), waterNormal), 0.0, 1.0), 5.0) + 0.02;

    vec3 normal;

    float roughness = RoughnessValue;
    float roughnessSquared = roughness*roughness;

    //vec3 shadows = texture(colortex6, textureCoordinate.st).rgb * 0.04;

    for(i = 0; i < samples; i++) {
    normal = mix(clampNormal(waterNormal, view), normalize(hash33(view.xyz + i) * 2.0 - 1.0), roughnessSquared);

    float fresnelR = 0.0;

    fresnelR = schlick;

    vec3 direction = reflect(normalize(viewPosition.xyz), normal);
    vec4 hitPosition;
    #ifdef SSR
    if (raytraceIntersection(viewVec3, direction, hitPosition.xyz, 32.0, 4.0)) {
        reflection += textureLod(colortex0, hitPosition.xy, 0).rgb * fresnelR;
        continue;
    }
    #endif

    //vec3 sun = calculateSun(sunVector, normalize(direction.xyz)) * shadows;
    vec3 moon = (moonColor) * vec3(clamp01(GGX(waterNormal, normalize(-view.xyz), moonVector, 0.08*0.08, 0.5))) * shadows;
    vec3 specular = (atmosphereTransmittance(sunVector, upVector, moonVector) * 150.0) * vec3(clamp01(GGX(waterNormal, normalize(-view.xyz), sunVector, 0.08*0.08, 0.5))) * shadows;
    vec3 backGround = specular + moon;

    reflection += pow(skyLight, 7.0) * get_atmosphere(vec3(0.0), direction, sunVector, upVector, moonVector) * fresnelR;
    reflection += backGround;
    }
    return reflection / samples;
}

//These IOR values are from: https://pixelandpoly.com/ior.html
#define WaterIOR 1.333
#define AirIOR 1.000

#include "lib/water/waterfog.glsl"

vec3 raytraceRefractionEffect(vec4 view, float waterDepth, float depth) {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture2D(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    float refractAmount = clamp(waterDepth, 0.0, 1.0);
    float refractionTexcoord = clamp01(4.8 - abs(view.y * 2.0 - 5.0));
    //refractAmount *= refractionTexcoord;
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);

    vec3 refractionDirection = refract(normalize(view.xyz), waterNormal, isEyeInWater == 1 ? WaterIOR/AirIOR : AirIOR/WaterIOR);

    if (refractionDirection == vec3(0.0)) {
        // Total internal reflection
        vec3 direction = reflect(normalize(viewPosition.xyz), waterNormal);
        vec2 lightmap = texture2D(colortex2, textureCoordinate).rg;
        vec4 hitPosition;
        if (!raytraceIntersection(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r), direction, hitPosition.xyz, 32.0, 4.0)) {
            return waterFog(texture(colortex0, hitPosition.xy).rgb, waterDepth * 15e5);
        } 
        float depthDist = distance(screenSpaceToViewSpace(hitPosition.xyz, gbufferProjectionInverse), view.xyz);
        return waterFog(textureLod(colortex0, hitPosition.xy, 0.0).rgb, max(depthDist, 1.0));
    }

/*
    These are the proper settings for raytraced refraction
    const float maxSteps  = 32.0;
    const float maxRefs   = 6;
    const float stepSize  = 0.02;
    const float stepScale = 1.3;
    const float refScale  = 0.5;
*/

    raytraceIntersection(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r), refractionDirection, view.xyz, 32.0, 4.0);
    if(!raytraceIntersection(viewPosition, refractionDirection, view, 512.0, 8.0, 0.5, 1.0, 0.5) && isEyeInWater == 0) return waterFog(textureLod(colortex0,textureCoordinate.xy, 0.0).rgb, max(waterDepth, 1.0));

    float waterDepthRefracted = linearizeDepth(texture2D(depthtex0, textureCoordinate).r) - linearizeDepth(texture2D(depthtex1, view.xy).r);

    if (isEyeInWater == 0) return waterFog(textureLod(colortex0, view.xy, 0.0).rgb, max(waterDepthRefracted, 1.0));
    if (isEyeInWater == 1) return textureLod(colortex0, view.xy, 0.0).rgb;
}

vec3 refractionEffect(vec4 view, float waterDepth, vec2 lightmap, float depth, in vec3 normal) {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture2D(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    vec3 start = view.xyz;

    float refractAmount = clamp(waterDepth, 0.0, 1.0);
    float refractionTexcoord = clamp01(4.9 - abs(textureCoordinate.y * 2.0 - 5.0));
    if(isEyeInWater == 0) refractAmount *= refractionTexcoord;

    vec3 refractionDirection = refract(normalize(view.xyz), normal, AirIOR/WaterIOR);

    view.xyz += refractionDirection * refractAmount;

    view = gbufferProjection * view;
    view /= view.w;

    if(isEyeInWater == 1) view.xy = view.xy * 0.5 + 0.5;

    vec4 world = gbufferModelViewInverse * view;
    world /= world.w;

    vec4 end = gbufferProjectionInverse * vec4(view.xy, texture2D(depthtex1, view.xy * 0.5 + 0.5).r * 2.0 - 1.0, 1.0);
    end /= end.w;

    float waterDepthRefracted = linearizeDepth(texture2D(depthtex0, textureCoordinate).r) - linearizeDepth(texture2D(depthtex1, view.xy).r);

    //if(!hit) return waterFog(texture2DLod(colortex0, textureCoordinate.xy, 0).rgb, max(waterDepth, 0.0), lightmap) * phase;

    if (isEyeInWater == 0) return waterFogVolumetric(texture2DLod(colortex0, view.xy * 0.5 + 0.5, 0.0).rgb, start, end.xyz, lightmap, world.xyz);
    if (isEyeInWater == 1) return texture2DLod(colortex0, view.xy, 0.0).rgb;
}

#ifdef VolumetricFog
#include "lib/light/volumetrics.glsl"
#endif

vec4 Fog(vec3 viewVector) {
    vec4 result = vec4(0.0);
    float shadowDepthSample = 0.0;
    for (int j = 0; j < 4; j++) {
            result += vec4(physicalAtmosphere(vec3(0.0), viewVector, sunVector, upVector, skyQuality_I, skyQuality_J, moonVector), 1.0);
    }

    return result;
}

float noonLight = 1.0;
float horizonLight = 35.5;
float nightLight = 27.1;

float vlIntensity = (noonLight * timeVector.x + noonLight * nightLight * timeVector.y + horizonLight * timeVector.z);

void main() {
    color = texture(colortex0, textureCoordinate.st, 0);
    float depth = texture(depthtex0, textureCoordinate.st).r;
    float id = texture(colortex4, textureCoordinate.st).b * 65535.0;
    float waterDepth = linearizeDepth(texture(depthtex0, textureCoordinate).r) - linearizeDepth(texture(depthtex1, textureCoordinate).r);
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);
    vec2 lightmap = decode2x16(texture(colortex4, textureCoordinate.st).r).xy;

    vec4 view = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view = gbufferProjectionInverse * view;
    view /= view.w;
    //view.xyz = normalize(view.xyz);

    vec4 view2 = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view2 = gbufferProjectionInverse * view2;
    view2 /= view2.w;
    vec4 world = gbufferModelViewInverse * view2;
    world /= world.w;
    world = gbufferPreviousProjection  * (gbufferPreviousModelView * world);

    #if RefractionMode == 1
    if(id == 8.0 || id == 9.0) color = vec4(refractionEffect(view, waterDepth, lightmap, depth, waterNormal), 1.0);
    #elif RefractionMode == 0
    if(id == 8.0 || id == 9.0) color = vec4(raytraceRefractionEffect(view, waterDepth, depth), 1.0);
    //#elif RefractionMode == 3
    #endif
    if(isEyeInWater == 1) color = vec4(waterFogVolumetric(color.rgb, vec3(0.0), view.xyz, lightmap, world.xyz), 1.0);
    if(id == 8.0 || id == 9.0 && isEyeInWater == 0) color += vec4(reflection(normalize(view.xyz)), 1.0);
//    if(id == 8.0 || id == 9.0 && isEyeInWater == 0) raytrace = mix(texture(colortex2, world.xy / world.w * 0.5 + 0.5), clamp01(vec4(reflection(normalize(view.xyz)), 1.0)) * 30.0, 0.005);

//mix(texture(colortex3, world.xy / world.w * 0.5 + 0.5), VL(view.xyz) * 3.0, 0.005)

    //color += Fog(normalize(view.xyz));

    #ifdef VolumetricFog
    if(isEyeInWater == 0) volume = mix(texture(colortex3, world.xy / world.w * 0.5 + 0.5), VL(normalize(view.xyz)) * vlIntensity, AccumulationStrength);
    #else
    volume = vec4(1.0);
    #endif

    //color = vec4(dot(normal, upVector) * 0.5 + 0.5);
}