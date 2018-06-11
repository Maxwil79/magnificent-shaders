const vec3 scoeff = 0.005 * vec3(0.35,0.6,0.83);
const vec3 acoeff = 4 * vec3(.4510, .0867, .0476);

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = vec3(1.0);

    return exp(-attenCoeff * clamp(dist, 0.0, 4e12));
}

vec3 waterFog(vec4 color, float dist) {
    vec3 transmittance = exp(-acoeff * dist);
    vec3 scattered = (1.0 - acoeff) * scoeff;

    vec3 colorDirect = get_sunlightColor();
    vec3 colorSky = atmosAmbient(mat3(gbufferModelViewInverse) * upVector);

    vec3 scatterCol = vec3(0.0);

    vec2 lightmap = decode2x16(texture(colortex4, texcoord.st).r).xy;
    lightmap = pow(lightmap, vec2(2.5, 5.0));
    lightmap *= lightmap;
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;
    vec3 lighting = lightmap.y * colorSky;
    lighting *= colorDirect * lightmap.y;

    return color.rgb * transmittance + scattered * lighting;
}

#define square(x) x*x

float water_fournierForandPhase(float theta, float mu, float n) {
    float v     = (3.0 - mu) * 0.5;
    float u     = 2.0 * clamp01(sin(theta / 2.0));
    float delta = square(u) / (3.0 * square(n - 1.0));

    float deltapv = pow(delta + 1e-9, v);

    float
    result  = (v * (1.0 - delta) - (1.0 - deltapv)) + (4.0 / (square(u) + 1e-9)) * (delta * (1.0 - deltapv) - v * (1.0 - delta));
    result /= 4.0 * pi * square(1.0 - delta) * deltapv + 5e-6;

    return result;
}

//#define Caustics

vec3 water_volume(vec4 color, vec3 start, vec3 end, vec2 lightmap, vec3 world, in float dither) {  
    const vec3 attenCoeff = acoeff + scoeff;

    int steps = VolumetricSteps;

    lightmap = pow(lightmap, vec2(2.5, 5.0));
    lightmap *= lightmap;
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec3 scatterCol = vec3(0.0);

    vec3 colorDirect = sunLight;

    vec3 lightColor = vec3(0.0);
    lightColor = colorDirect.rgb;

	vec3 rayVec  = end - start;
	     rayVec /= steps;
	float stepSize = length(rayVec);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0);

    vec3 increment = (end - start) / steps;
    start -= increment * dither;

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse; //Thank you to BuilderB0y for showin me this. 

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    vec3 sunlightConribution = lightColor;
    float depth = stepSize;
    for (int i = 0; i < steps; ++i) {
        curPos.xyz += increment;
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 4.0) * 0.5 + 0.5;
	    float shadowTransparent = float(textureLod(shadowtex1,   shadowPos.st, 0).r > shadowPos.p - 0.000003);

	    vec3 shadow = vec3(shadowTransparent);
	    shadow *= sunlightConribution;

        scattered += (shadow + vec3(0.0)) * transmittance;
        transmittance *= exp(-attenCoeff * depth);
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-attenCoeff * depth)) / (attenCoeff);

    return color.rgb * transmittance + scattered;
}