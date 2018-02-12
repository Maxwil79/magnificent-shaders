#version 450

//#define VolumetricFog //Enable this for VL

/*DRAWBUFFERS: 03*/
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 vl;

const float pi  = 3.14159265358979;

in vec2 textureCoordinate;
in vec3 lightVector;
in vec3 worldLightVector;
in vec3 sunVector;
in vec3 moonVector;

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

const bool colortex3MipmapEnabled = true;

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

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

vec3 clampNormal(vec3 n, vec3 v){
    return dot(n, v) >= 0.0 ? cross(cross(v, n), v) : n;
}

vec3 filterVL(vec2 coord) {
	const float range = 2.0;
	float refDepth = linearizeDepth(texture(depthtex2, coord).r)*100.0;
	float refDepth2 = linearizeDepth(texture(depthtex2, coord).r)*0.5;

	vec3 result = vec3(0.0);
	float totalWeight = 0.0;
	for (float i = -range; i <= range; i++) {
		for (float j = -range; j <= range; j++) {
			vec2 sampleOffset = vec2(i, j) / vec2(viewWidth, viewHeight);

            float weight = max(1.0 - float(sampleOffset / range), 0.0);

			result += texture(colortex3, coord + sampleOffset * 0.75).rgb * weight;
			totalWeight += weight;
		}
	}
	return result / totalWeight;
}

void main() {
    color = texture(colortex0, textureCoordinate.st);
    float depth = texture(depthtex1, textureCoordinate.st).r;
    float id = texture(colortex4, textureCoordinate.st).b * 65535.0;
    float waterDepth = linearizeDepth(texture(depthtex0, textureCoordinate).r) - linearizeDepth(texture(depthtex1, textureCoordinate).r);
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);

    vec4 view = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view = gbufferProjectionInverse * view;
    view /= view.w;
    view.xyz = normalize(view.xyz);

    vec4 view2 = vec4(vec3(textureCoordinate.st, depth) * 2.0 - 1.0, 1.0);
    view2 = gbufferProjectionInverse * view2;
    view2 /= view2.w;
    vec4 world = gbufferModelViewInverse * view2;
    world /= world.w;
    world = gbufferPreviousProjection  * (gbufferPreviousModelView * world);

    //raytracer = texture(colortex3, textureCoordinate);

    #ifdef VolumetricFog
    if(isEyeInWater == 0) vl = texture(colortex3, textureCoordinate);
    #else
    vl = vec4(1.0);
    #endif

    #ifdef VolumetricFog
    color += vl;
    #endif

    //color = vec4(dot(normal, upVector) * 0.5 + 0.5);
}