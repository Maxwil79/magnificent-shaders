#version 330 compatibility
#extension GL_ARB_texture_gather : enable

#define SHADOW

//#define Caustics //Lowers FPS a decent amount.

varying mat3 tbnMtrix;
varying vec4 viewPos;
varying vec4 worldPos;
varying vec3 lightPos;
varying vec2 texcoord;
varying float water;
varying float portal;

uniform sampler2D tex;
uniform sampler2D noisetex;
uniform sampler2D colortex0;

uniform float frameTimeCounter;

const float pi  = 3.14159265358979;
const float tau = pi*2.0;

#include "lib/water.glsl"

#define rcp(x) ( 1.0 / x )
#define fDivide(a, b) a * rcp(b)

const float gammaCurveScreen    = 2.2;
const float gammaCurveScreenRCP = rcp(gammaCurveScreen);

#define powR(x) fDivide(x*x*x*x*x*x, 1.0)

vec3 caustics(in vec4 position) {
    vec3 refractedPosition = refract(normalize(position.xyz), normalize(tbnMtrix * waterNormals(position.xyz, viewPos.xyz*tbnMtrix, 0.04)), 1.000/1.333) * 18.0 + position.xyz;

        float oldArea = length(dFdx(position)) * length(dFdy(position));
        float newArea = length(dFdx(refractedPosition)) * length(dFdy(refractedPosition));

    vec3 causticSample = pow(vec3(abs(oldArea / newArea)), vec3(gammaCurveScreenRCP));

    return causticSample;
}

void main() {
    gl_FragData[0] = texture2D(tex, texcoord);

    if(portal == 1.0) gl_FragData[0] = vec4(0.7, 0.01, 1.0, 0.5);

    if(water == 1.0) {
        #ifdef Caustics
        gl_FragData[0].r = caustics(worldPos + 0.05).r;
        gl_FragData[0].g = caustics(worldPos + 0.04).g;
        gl_FragData[0].b = caustics(worldPos + 0.03).b;
        #else
        gl_FragData[0] = vec4(1.0);
        #endif
    }

    gl_FragData[1] = vec4(water, 1.0, 1.0, 1.0);
}