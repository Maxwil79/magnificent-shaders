#version 400

//#define Refraction //Lowers FPS a bit.

//#define VL

#define getLandMask(x) (x < 1.0)

/* DRAWBUFFERS:0 */

layout (location = 0) out vec4 color;

in vec2 texcoord;

in vec3 sunVector;
in vec3 sunVector2;
in vec3 moonVector;
in vec3 lightVector;
in vec3 lightVector2;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D noisetex;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;

uniform float sunAngle;
uniform float far;
uniform float viewWidth, viewHeight;
uniform float frameTimeCounter;

vec2 screenRes = vec2(viewWidth, viewHeight);

const float pi  = 3.14159265358979;
const float tau = pi*2;

const float sunPathRotation = -40.0;
const int shadowMapResolution = 2048;
const float shadowDistance = 256.0;

const float eyeBrightnessHalflife = 0.75;

mat4 newShadowModelView = mat4(
    1, 0, 0, shadowModelView[0].w,
    0, 0, 1, shadowModelView[1].w,
    0, 1, 0, shadowModelView[2].w,
    shadowModelView[3]
);

vec3 upVector = gbufferModelView[1].xyz;

float hash12(vec2 p){
    p  = fract(p * .1031);
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

float dither2=hash12(texcoord*vec2(viewWidth,viewHeight));

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

#ifdef VL
#include "lib/vl.glsl"
#endif

float linearizeDepth(float depth) {
    return -1.0 / ((depth * 2.0 - 1.0) * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

#include "lib/waterfog.glsl"

#include "lib/reflections.glsl"

#define WaterIOR 1.333
#define AirIOR 1.000

#include "lib/waves.glsl"

vec3 getRefraction(vec3 clr, vec3 fragpos, in float depth, in float dither) {
	vec4 worldPos = gbufferModelViewInverse * vec4(fragpos, 1.0);

	vec2 waterTexcoord = texcoord.st;

		float deltaPos = 0.75;
		float h0 = waterHeight(worldPos.xyz + cameraPosition.xyz);
		float h1 = waterHeight(worldPos.xyz + cameraPosition.xyz - vec3(deltaPos, 0.0, 0.0));
		float h2 = waterHeight(worldPos.xyz + cameraPosition.xyz - vec3(0.0, 0.0, deltaPos));

		float dX = (h0 - h1) / deltaPos;
		float dY = (h0 - h2) / deltaPos;

		vec3 waterRefract = normalize(vec3(dX, dY, 1.0)) / fragpos.z;

		waterTexcoord = texcoord.st + waterRefract.xy;

        vec4 view = vec4(vec3(waterTexcoord.st, depth) * 2.0 - 1.0, 1.0);
        view = gbufferProjectionInverse * view;
        view /= view.w;

        vec4 world = gbufferModelViewInverse * view;
        world /= world.w;
        world = gbufferPreviousProjection  * (gbufferPreviousModelView * world);
        vec4 end = gbufferProjectionInverse * vec4(waterTexcoord.xy * 2.0 - 1.0, texture2D(depthtex1, waterTexcoord.xy).r * 2.0 - 1.0, 1.0);
        end /= end.w;

		vec3 watercolor = vec3(0.0);

        vec4 color = texture(colortex0, waterTexcoord.st);
        if(isEyeInWater == 0) {
        watercolor = waterFogVolumetric(color, view.xyz, end.xyz, decode2x16(texture(colortex4, texcoord.st).r), world.xyz);
        } else {
        watercolor = color.rgb;
        }

		clr = watercolor;
    
	return clr;
}

void main() {
    color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord.st).r;
    float id = texture(colortex4, texcoord.st).b * 65535.0;
    float waterDepth = linearizeDepth(texture(depthtex0, texcoord).r) - linearizeDepth(texture(depthtex1, texcoord).r);

    vec4 view = vec4(vec3(texcoord.st, depth) * 2.0 - 1.0, 1.0);
    view = gbufferProjectionInverse * view;
    view /= view.w;

    vec4 world = gbufferModelViewInverse * view;
    world /= world.w;
    world = gbufferPreviousProjection  * (gbufferPreviousModelView * world);

    vec4 end = gbufferProjectionInverse * vec4(texcoord.xy * 2.0 - 1.0, texture(depthtex1,texcoord.xy).r * 2.0 - 1.0, 1.0);
    end /= end.w;

    #ifndef Refraction
    if(id == 8.0 || id == 9.0 && isEyeInWater == 0) color.rgb = waterFogVolumetric(color, view.xyz, end.xyz, decode2x16(texture(colortex4, texcoord.st).r).xy, world.xyz);
    #else
    if(id == 8.0 || id == 9.0) color.rgb = getRefraction(vec3(0.0), view.xyz, depth, bayer32(gl_FragCoord.st));
    #endif
    if(isEyeInWater == 1) color.rgb = waterFogVolumetric(color, vec3(0.0), view.xyz, decode2x16(texture(colortex4, texcoord.st).r).xy, world.xyz);

    if(id == 8.0 || id == 9.0 && isEyeInWater == 0) color.rgb += reflection(normalize(view.xyz), vec3(0.0), world.xyz, color);

    #ifdef VL
    if(isEyeInWater == 0) color.rgb = calculateVolumetricLight(color.rgb, vec3(0.0), view.xyz, vec2(0.0), world.xyz, intensity);
    #endif
}