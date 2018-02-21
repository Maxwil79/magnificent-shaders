#version 420

#define Torch_Temperature 3450 //[1000 1100 1150 1200 1250 1300 1350 1400 1450 1500 1550 1600 1650 1700 1750 1800 1850 1900 1950 2000 2100 2150 2200 2250 2300 2350 2400 2450 2500 2550 2600 2650 2700 2750 2800 2850 2900 2950 3000 3100 3150 3200 3250 3300 3350 3400 3450 3500 3550 3600 3650 3700 3750 3800 3850 3900 3950] A lower value gives a more red result, and can make Endermen eyes look strange.
#define Attenuation 3.5 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5] A higher value will make the torch lightmaps smaller.

#define ShadowType 1 //[0 1]

/*DRAWBUFFERS: 0*/
layout (location = 0) out vec4 color;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex4Format = RGBA32F;
const int colortex7Format = RGB16F;
*/

const float pi  = 3.14159265358979;

in vec2 textureCoordinate;
in vec3 lightVector;
in vec3 worldLightVector;
in vec3 sunVector;
in vec3 moonVector;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform vec3 shadowLightPosition;

uniform float far;
uniform float viewHeight, viewWidth;
uniform float frameTimeCounter;
uniform float sunAngle;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;
uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferModelView;

float square (float x) { return x * x; }
vec2  square (vec2  x) { return x * x; }
vec3  square (vec3  x) { return x * x; }
vec4  square (vec4  x) { return x * x; }

#define inverseSquare(x) (1.0 / square(x))

vec3 blackbody(float t){
    // http://en.wikipedia.org/wiki/Planckian_locus

    vec4 vx = vec4(-0.2661239e9,-0.2343580e6,0.8776956e3,0.179910);
    vec4 vy = vec4(-1.1063814,-1.34811020,2.18555832,-0.20219683);
    float it = 1./t;
    float it2= it*it;
    float x = dot(vx,vec4(it*it2,it2,it,1.));
    float x2 = x*x;
    float y = dot(vy,vec4(x*x2,x2,x,1.));
    float z = 1. - x - y;
    
    // http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
    mat3 xyzToSrgb = mat3(
         3.2404542,-1.5371385,-0.4985314,
        -0.9692660, 1.8760108, 0.0415560,
         0.0556434,-0.2040259, 1.0572252
    );

    vec3 srgb = vec3(x/y,1.,z/y) * xyzToSrgb;
    return max(srgb,0.);
}

#include "dither.glsl"

#include "lib/decode.glsl"

#include "lib/water/waterShadow.glsl"

#include "lib/raysphereIntersections/raysphereIntersection.glsl"
#include "lib/atmosphere/physicalAtmosphere.glsl"

#include "lib/atmosphere/physicalSun.glsl"
#include "lib/atmosphere/physicalMoon.glsl"

#include "lib/util.glsl"

#include "lib/rays/rayTracers.glsl"

const vec2[36] offset = vec2[36](
        vec2(-0.90167680,  0.34867350),
        vec2(-0.98685560, -0.03261871),
        vec2(-0.67581730,  0.60829530),
        vec2(-0.47958790,  0.23570540),
        vec2(-0.45314310,  0.48728980),
        vec2(-0.30706600, -0.15843290),
        vec2(-0.09606075, -0.01807100),
        vec2(-0.60807480,  0.01524314),
        vec2(-0.02638345,  0.27449020),
        vec2(-0.17485240,  0.49767420),
        vec2( 0.08868586, -0.19452260),
        vec2( 0.18764890,  0.45603400),
        vec2( 0.39509670,  0.07532994),
        vec2(-0.14323580,  0.75790890),
        vec2(-0.52281310, -0.28745570),
        vec2(-0.78102060, -0.44097930),
        vec2(-0.40987180, -0.51410110),
        vec2(-0.12428560, -0.78665660),
        vec2(-0.52554520, -0.80657600),
        vec2(-0.01482044, -0.48689910),
        vec2(-0.45758520,  0.83156060),
        vec2( 0.18829080,  0.71168610),
        vec2( 0.23589650, -0.95054530),
        vec2( 0.26197550, -0.61955050),
        vec2( 0.47952230,  0.32172530),
        vec2( 0.52478220,  0.61679990),
        vec2( 0.85708400,  0.47555550),
        vec2( 0.75702890,  0.08125463),
        vec2( 0.48267020,  0.86368290),
        vec2( 0.33045960, -0.31044460),
        vec2( 0.59658700, -0.35501270),
        vec2( 0.69684450, -0.61393110),
        vec2( 0.88014110, -0.41306840),
        vec2( 0.07468465,  0.99449370),
        vec2( 0.92697510, -0.10826900),
        vec2( 0.45471010, -0.78973980)
);

float lerp(float v0, float v1, float t) {
  return (1 - t) * v0 + t * v1;
}

#include "lib/light/shading.glsl"

#define getLandMask(x) (x < 1.0)

void main() {
    color = texture(colortex0, textureCoordinate.st);
    float depth = texture(depthtex1, textureCoordinate.st).r;
    float id = texture(colortex4, textureCoordinate.st).b * 65535.0;

    color.rgb = pow(color.rgb, vec3(2.2));

    vec4 view = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view = gbufferProjectionInverse * view;
    view /= view.w;
    view.xyz = normalize(view.xyz);

    vec4 view2 = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view2 = gbufferProjectionInverse * view2;
    view2 /= view2.w;
    vec4 world = gbufferModelViewInverse * view2;
    world /= world.w;

    vec3 sun = calculateSun(sunVector, normalize(view.xyz));
    vec3 moon = calculateMoon(moonVector, normalize(view.xyz));
    vec3 background = sun + moon; 

    float shadows;

    color = vec4(getShading(color.rgb, world.xyz, id, shadows, normalize(view2.xyz)), 1.0);
    if(!getLandMask(depth)) color.rgb = get_atmosphere(background, normalize(view.xyz), sunVector, upVector, moonVector);

    //if(id == 8.0 || id == 9.0) color = vec4(decodeNormal3x16(texture(colortex1, textureCoordinate.st).r) * mat3(gbufferModelView), 1.0);

    //color = vec4(dot(normal, upVector) * 0.5 + 0.5);
}