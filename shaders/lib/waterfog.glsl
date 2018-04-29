const vec3 scoeff = vec3(3.20e-3, 7.70e-3, 8.00e-3);
const vec3 acoeff = vec3(3.00e-1, 1.20e-1, 0.90e-1);

vec3 waterFog(vec4 color, float dist) {

    vec3 transmittance = exp(-acoeff * dist);
    vec3 scattered = scoeff * (1.0 - exp(-acoeff * dist)) / acoeff;

    vec4 colorDirect = color;

    atmosphere(colorDirect.rgb, lightVector.xyz, sunVector, moonVector, ivec2(16, 4));

    vec2 lightmap = decode2x16(texture(colortex4, texcoord.st).r).xy;
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;
    vec3 lighting = lightmap.y * colorDirect.rgb;

    return color.rgb * transmittance + lighting * scattered;
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

float miePhase(float cosTheta, float g) {
	float gg = g * g;

	float p1 = (3.0 * (1.0 - gg)) / (2.0 * (2.0 + gg));
	return p1 * (cosTheta * cosTheta + 1.0) / pow(1.0 + gg - 2.0 * g * cosTheta, 1.5);
}

vec3 waterFogVolumetric(vec4 color, vec3 start, vec3 end, vec2 lightmap, vec3 world) {  
    const vec3 attenCoeff = acoeff + scoeff;

    int steps = 8;

    lightmap = pow(lightmap, vec2(2.0, 5.0));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec4 colorDirect = color;
    vec4 colorSky = color;

    atmosphere(colorDirect.rgb, lightVector.xyz, sunVector, moonVector, ivec2(12, 2));
    atmosphere(colorSky.rgb, mat3(gbufferModelViewInverse) * upVector, sunVector, moonVector, ivec2(12, 1));

    vec3 lightColor = vec3(0.0);
    lightColor = colorDirect.rgb;
    vec3 skyLightColor = colorSky.rgb * (vec3(0.93636, 1.5606, 2.40908) / 2.0) * lightmap.y;

	vec3 rayVec  = end - start;
	     rayVec /= steps;
	float stepSize = length(rayVec);


	float VoL   = dot(normalize(end - start), lightVector2);
    float isotropicPhase = 0.25 / pi;
    float waterPhase = isotropicPhase + water_fournierForandPhase(acos(dot(normalize(end - start), lightVector2)), 3.23, 1.24);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / steps;
    start -= increment * bayer128(gl_FragCoord.st);

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse; //Thank you to BuilderB0y for showin me this. 

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor * waterPhase;
    vec3 skylightContribution = skyLightColor;
    float depth = stepSize;
    for (int i = 0; i < steps; i++) {
        curPos.xyz += increment;
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;
        float tex0 = float(texture(shadowtex0, shadowPos.xy).r > shadowPos.p - 0.000003);
        float tex1 = float(texture(shadowtex1, shadowPos.xy).r > shadowPos.p - 0.000003);
        vec3 shadow = mix(vec3(tex0), vec3(1.0), float(tex1 > tex0)) * sunlightConribution;

        scattered += (shadow + skyLightColor) * transmittance;
        transmittance *= exp(-attenCoeff * depth);
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-attenCoeff * depth)) / (attenCoeff);

    return color.rgb * transmittance + scattered;
}