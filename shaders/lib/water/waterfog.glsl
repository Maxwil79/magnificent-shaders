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

#define dither2(p)   (bayer2(  p)-.375      )
#define dither4(p)   (bayer4(  p)-.46875    )
#define dither8(p)   (bayer8(  p)-.4921875  )
#define dither16(p)  (bayer16( p)-.498046875)
#define dither32(p)  (bayer32( p)-.499511719)
#define dither64(p)  (bayer64( p)-.49987793 )
#define dither128(p) (bayer128(p)-.499969482)

// Volumetric Water Fog
float pow2(in float n)  { return n * n; }

float water_fournierForandPhase(float theta, float mu, float n) {
    float v     = (3.0 - mu) * 0.5;
    float u     = 2.0 * clamp01(sin(theta / 2.0));
    float delta = pow2(u) / (3.0 * pow2(n - 1.0));

    float deltapv = pow(delta + 1e-9, v);

    float
    result  = (v * (1.0 - delta) - (1.0 - deltapv)) + (4.0 / (pow2(u) + 1e-9)) * (delta * (1.0 - deltapv) - v * (1.0 - delta));
    result /= 4.0 * pi * pow2(1.0 - delta) * deltapv + 5e-6;

    return result;
}

#define WaterQuality 1 //[0 1 2 3 4 5 6]

vec3 waterFogVolumetric(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world, in float dither) {  
    #if WaterQuality == 0
    int steps = 1;
    #elif WaterQuality == 1
    int steps = 4;
    #elif WaterQuality == 2
    int steps = 8; 
    #elif WaterQuality == 3
    int steps = 32;
    #elif WaterQuality == 4
    int steps = 64;
    #elif WaterQuality == 5
    int steps = 128;
    #elif WaterQuality == 6
    int steps = 1024;
    #endif

    lightmap = pow(lightmap, vec2(Attenuation, 5.0));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec3 lightColor = vec3(0.0);
    lightColor = get_atmosphere_transmittance(sunVector, upVector, moonVector);
    vec3 skyLightColor = get_atmosphere_ambient(vec3(0.0), vec3(0.0), sunVector2, moonVector2, 16) * 4.0 * lightmap.y;

	vec3 rayVec  = end - start;
	     rayVec /= steps;
	float stepSize = length(rayVec);

    const vec3 attenCoeff = acoeff + scoeff;

	float VoL   = dot(normalize(end - start), lightVector);
	float rayleigh = rayleighPhase(VoL);
    float mie = miePhase(VoL, 0.5);
    float isotropicPhase = 0.25 / pi;
    float waterPhase = isotropicPhase * 0.7 + water_fournierForandPhase(acos(dot(normalize(end - start), lightVector)), 4.25, 1.01) * 0.3;

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / steps;
    start -= increment * dither;

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse; //Thank you to BuilderB0y for showin me this. 

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor;
    vec3 skylightContribution = skyLightColor;
    float depth = stepSize;
    for (int i = 0; i < steps; i++) {
        curPos.xyz += increment;
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;
        float tex0 = texture(shadowtex0, shadowPos.st).r;
        float tex1 = texture(shadowtex1, shadowPos.st).r;
        float shadowOpaque = float(tex0 > shadowPos.p - 0.000003);
        float shadowTransparent = float(tex1 > shadowPos.p - 0.000003);
        vec3 shadow = mix(vec3(shadowOpaque), vec3(1.0), float(shadowTransparent > shadowOpaque)) * sunlightConribution;

        //float shadowDepthSample = texture(shadowtex0, shadowPos.st).r - shadowPos.z;
        //vec3 waterShadow = waterFogShadow((shadowDepthSample * 2.0) * shadowProjectionInverse[2].z);
        //float waterShadowCast = float(texture(shadowcolor1, shadowPos.st).r > shadowPos.z - 0.0009);

        //if(waterShadowCast == 1.0) shadow *= waterShadow;

        scattered += (shadow + skylightContribution) * transmittance;
        transmittance *= exp(-(attenCoeff * 1.5) * depth);
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-(attenCoeff * 1.5) * depth)) / ((attenCoeff * 1.5));

    return color * transmittance + scattered;
}

#include "iceFog.glsl"