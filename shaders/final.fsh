#version 400

/* DRAWBUFFERS:0 */

#define getLandMask(x) (x < 1.0)

#define Info //Features: Water volume, volumetric light, water waves, refraction, bloom, average exposure

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

#include "lib/util.glsl"

//This belongs to Jodie
vec3 linearToSRGB(vec3 linear){
    return mix(
        linear * 12.92,
        pow(linear, vec3(1./2.4) ) * 1.055 - .055,
        step( .0031308, linear )
    );
}

void ditherScreen(inout vec3 color) {
    vec3 lestynRGB = vec3(dot(vec2(171.0, 231.0), gl_FragCoord.xy));
         lestynRGB = fract(lestynRGB.rgb / vec3(103.0, 71.0, 97.0));

    color += lestynRGB.rgb / 255.0;
}

#include "lib/finalSettings.glsl"

#include "lib/tonemaps.glsl"

#include "lib/postProcessPasses.glsl"

#ifdef Info
#endif

void main() {
    vec4 color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    color.rgb = BotWToneMap(color.rgb);

    color.rgb = FilmPass(color.rgb);

    color.rgb = linearToSRGB(color.rgb);

    ditherScreen(color.rgb);

    gl_FragData[0] = color;
}