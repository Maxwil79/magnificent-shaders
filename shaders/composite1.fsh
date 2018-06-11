#version 400

int stepCountAMB = 4;

#define Refraction 0 //[0 1 2]Lowers FPS a bit. The Fake Refraction is recommended.

//#define VL

//#define Fog

//#define VolumetricLightPCSS //Insanely slow. Not added to the water volume.

//#define Caustics

#define VolumetricSteps 8 //[1 2 3 4 5 6 7 8 9 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 75 80 85 90 95 100 128 256 512 1024]

#define getLandMask(x) (x < 1.0)

#define texture2D(sampler, vec2) texture(sampler, vec2)

/* DRAWBUFFERS:0 */

layout (location = 0) out vec4 color;

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
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D noisetex;

uniform mat4 shadowProjection, shadowModelView;
uniform mat4 shadowProjectionInverse, shadowModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;
uniform int frameCounter;

uniform float eyeAltitude;
uniform float rainStrength;
uniform float sunAngle;
uniform float far;
uniform float viewWidth, viewHeight;
uniform float frameTimeCounter;

vec2 screenRes = vec2(viewWidth, viewHeight);

const bool colortex0MipmapEnabled = true;

const float pi  = 3.14159265358979;
const float tau = pi*2;

const int shadowMapResolution = 2048;

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

float dither2=fract((bayer128(gl_FragCoord.st) * 128 + frameCounter * 7) / 128);

#include "lib/util.glsl"

#include "lib/encoding/decode.glsl"

#include "lib/blackbody.glsl"
#include "lib/newSky.glsl"

#include "lib/distortion.glsl"

float noise = fract(sin(dot(texcoord.xy, vec2(18.9898f, 28.633f))) * 4378.5453f) * 4.0 / 5.0;
mat2 noiseM = mat2(cos(noise), -sin(noise),
						   sin(noise), cos(noise));

const vec2[16] diskOffset = vec2[16](
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

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float groundFog(vec3 worldPos, in float height, in float divide) {
	worldPos.y -= height;
	float density = 1.0;
	density *= exp(-worldPos.y / divide);
	return density;
}

#include "lib/waves.glsl"

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

#include "lib/sun.glsl"

#include "lib/waterfog.glsl"

#include "lib/reflections.glsl"

#define WaterIOR 1.333
#define AirIOR 1.000

vec3 getRefraction(vec3 clr, vec3 fragpos, in float depth, in float dither, in float refractAmount) {
	vec4 worldPos = gbufferModelViewInverse * vec4(fragpos, 1.0);

	vec2 waterTexcoord = texcoord.st;

		float deltaPos = 0.08;
		float h0 = water_calculateWaves(worldPos.xyz + cameraPosition.xyz);
		float h1 = water_calculateWaves(worldPos.xyz + cameraPosition.xyz - vec3(deltaPos, 0.0, 0.0));
		float h2 = water_calculateWaves(worldPos.xyz + cameraPosition.xyz - vec3(0.0, 0.0, deltaPos));

		float dX = (h0 - h1) / deltaPos;
		float dY = (h0 - h2) / deltaPos;

		vec3 waterRefract = normalize(vec3(dX, dY, 1.0)) / fragpos.z;

        //waterRefract = mix(waterRefract, normalize(hash33(fragpos.xyz) * 2.0 - 1.0), 0.08*0.08);

		waterTexcoord = texcoord.st + waterRefract.xy * (refractAmount * 0.025);

        vec4 view = vec4(vec3(waterTexcoord.st, depth) * 2.0 - 1.0, 1.0);
        view = gbufferProjectionInverse * view;
        view /= view.w;

        vec4 world = gbufferModelViewInverse * view;
        world /= world.w;
        vec4 end = gbufferProjectionInverse * vec4(waterTexcoord.xy * 2.0 - 1.0, texture2D(depthtex1, waterTexcoord.xy).r * 2.0 - 1.0, 1.0);
        end /= end.w;

		vec3 watercolor = vec3(0.0);

        vec4 color = texture(colortex0, waterTexcoord.st);
        if(isEyeInWater == 0) {
        watercolor = water_volume(color, view.xyz, end.xyz, decode2x16(texture(colortex4, texcoord.st).r), world.xyz, dither2);
        } else {
        watercolor = color.rgb;
        }

		clr = watercolor;
    
	return clr;
}

bool raytraceRefractionIntersection(in vec4 position, in vec3 direction, out vec4 screenSpace) {
    const float maxSteps  = 64.0;
    const float maxRefs   = 6;
    const float stepSize  = 0.02;
    const float stepScale = 1.3;
    const float refScale  = 0.5;

    vec3 increment = direction * stepSize;
    increment *= abs(position.z);

    vec4 viewSpace = position;

    int refinements = 0;
    for (int i = 0; i < maxSteps; i++) {
        viewSpace.xyz += increment;
        screenSpace    = gbufferProjection * viewSpace;
        screenSpace   /= screenSpace.w;
        screenSpace    = screenSpace * 0.5 + 0.5;

        if (any(greaterThan(abs(screenSpace.xyz - 0.5), vec3(0.5)))) return false;

        float screenZ = texture2D(depthtex2, screenSpace.xy).r;
        float diff    = viewSpace.z - linearizeDepth(screenZ);

        if (diff <= 0.0) {
            if (refinements < maxRefs) {
                viewSpace.xyz -= increment;
                increment *= refScale;
                refinements++;

                continue;
            }

            if (any(greaterThan(abs(screenSpace.xyz - 0.5), vec3(0.5))) || length(increment) * 10 < -diff || screenZ == 1.0) return false;

            return true;
        }

        increment *= stepScale;
    }

    return false;
}

vec3 raytraceRefractionEffect(vec4 view, float waterDepth, vec2 lightmap, float depth, in vec3 normal) {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(texcoord, texture2D(depthtex0, texcoord).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    //viewPosition.xyz = viewSpaceToScreenSpace(viewPosition.xyz, gbufferProjection);

    vec3 start = view.xyz;

    vec3 refractionDirection = refract(normalize(view.xyz), normal, AirIOR/WaterIOR);

    raytraceRefractionIntersection(viewPosition, refractionDirection, view);
    if(!raytraceRefractionIntersection(viewPosition, refractionDirection, view) && isEyeInWater == 0) return waterFog(texture(colortex0, texcoord.st), waterDepth);

    vec4 world = gbufferModelViewInverse * view;
    world /= world.w;

    vec4 end = gbufferProjectionInverse * vec4(view.xy * 2.0 - 1.0, texture2D(depthtex1, view.xy).r * 2.0 - 1.0, 1.0);
    end /= end.w;

    if (isEyeInWater == 0) return water_volume(texture2D(colortex0, view.xy), start, end.xyz, lightmap, world.xyz, dither2);
    if (isEyeInWater == 1) return texture2D(colortex0, view.xy).rgb;
}

vec3 fog(vec3 color, float dist, in vec3 view, in vec3 world) {
    const vec3 attenCoeff = rlhCoeff + mieCoeff;
    vec3 transmittance = exp(-attenCoeff * dist);

    float vlG = mieG;

	float VoL   = dot(normalize(view.xyz), lightVector2);
    float VolVol = VoL * VoL;
	float rayleigh = rayleighPhase(VoL);
    float gg = vlG * vlG;
    float mie = miePhase(VoL, vlG);
    vec2 phase = vec2(rayleigh, mie);

    vec3 scoeff = (rlhCoeffSctr * rayleigh) + (mieCoeffSctr * mie);

    vec3 scattered = scoeff * (1.0 - exp(-attenCoeff * dist)) / attenCoeff;

    vec3 scatterCol = vec3(0.0);

    vec2 lightmap = vec2(eyeBrightnessSmooth) / 240.0;
    lightmap.y = pow(lightmap.y, 10.0);
    lightmap *= lightmap;
    vec3 lighting = lightmap.y * ((sunLight * phase.y) + (skyLight * phase.x));

    return color * transmittance + scattered;
}

void main() {
    color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord.st).r;
    float depth1 = texture(depthtex1, texcoord.st).r;
    float id = texture(colortex4, texcoord.st).b * 65535.0;
    float waterDepth = linearizeDepth(texture(depthtex0, texcoord).r) - linearizeDepth(texture(depthtex1, texcoord).r);
    float isTransparent = texture(colortex4, texcoord.st).a;

    vec4 view = vec4(vec3(texcoord.st, depth) * 2.0 - 1.0, 1.0);
    view = gbufferProjectionInverse * view;
    view /= view.w;

    vec4 view1 = vec4(vec3(texcoord.st, depth1) * 2.0 - 1.0, 1.0);
    view1 = gbufferProjectionInverse * view1;
    view1 /= view1.w;

    vec4 world2 = gbufferModelViewInverse * view;
    world2 /= world2.w;

    vec4 end = gbufferProjectionInverse * vec4(texcoord.xy * 2.0 - 1.0, texture(depthtex1,texcoord.xy).r * 2.0 - 1.0, 1.0);
    end /= end.w;

    #if Refraction == 0
    if(id == 8.0 || id == 9.0 && isEyeInWater == 0) color.rgb = water_volume(color, view.xyz, end.xyz, decode2x16(texture(colortex4, texcoord.st).r).xy, world2.xyz, dither2);
    #elif Refraction == 1
    if(id == 8.0 || id == 9.0) color.rgb = getRefraction(vec3(0.0), view.xyz, depth, bayer32(gl_FragCoord.st), 10.0);
    #elif Refraction == 2
    if(id == 8.0 || id == 9.0 || id == 79.0) color.rgb = raytraceRefractionEffect(view, waterDepth, decode2x16(texture(colortex4, texcoord.st).r).xy, depth, unpackNormal(texture(colortex5, texcoord.st).gb));
    #endif
/*
    #ifdef VL
    if(isEyeInWater == 1) {
        if(id == 8.0 || id == 9.0) color.rgb += calculateVolumetricLight(vec3(0.0), vec3(0.0), view1.xyz, vec2(0.0), world1.xyz, 1.0);
    }
    #endif
*/
    if(isEyeInWater == 1) color.rgb = water_volume(color, vec3(0.0), view.xyz, decode2x16(texture(colortex4, texcoord.st).r).xy, world2.xyz, dither2);

    if(getLandMask(depth) && isEyeInWater == 0) color.rgb += max(reflection(normalize(view.xyz), vec3(0.0), world2.xyz), 0.0);

    #ifdef VL
    if(isEyeInWater == 0) color.rgb += calculateVolumetricLight(vec3(0.0), vec3(0.0), view.xyz, vec2(0.0), world2.xyz, 1.0);
    #endif

    #ifdef Fog
    color.rgb = fog(color.rgb, -linearizeDepth(texture(depthtex1, texcoord).r), normalize(view.xyz), world2.xyz);
    #endif
}