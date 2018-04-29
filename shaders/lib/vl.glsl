#define STEPS 16
#define VolumeDistanceMultiplier 9.75 //[0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0] The multiplier of which the Volume distance uses to multiply far by.
#define VolumeDistance far*VolumeDistanceMultiplier
#define VlMode 0 //[0 1] Changes the coefficients and intensity of VL.

#if VlMode == 0
const vec3 rayleighScatteringCoefficient = vec3(5.5e-6, 13.0e-6, 22.4e-6);
const vec3      mieScatteringCoefficient = vec3(2.1e-5); //Good default
float intensity = 1e0;
#elif VlMode == 1
const vec3 rayleighScatteringCoefficient = vec3(9.8e-6  , 1.35e-5 , 1.31e-5 );
const vec3      mieScatteringCoefficient = vec3(2.1e-5); //Good default
float intensity = 4.5e2;
#endif

const vec3 rayleighTransmittanceCoefficient = rayleighScatteringCoefficient;
const vec3      mieTransmittanceCoefficient =      mieScatteringCoefficient * 1.11;

float groundFog(vec3 worldPos) {
	worldPos.y -= 140.0;
	float density = 1.0;
	density *= exp(-worldPos.y / 25.0);
    density = clamp(density, 0.0, 10.2);
	return density;
}

vec3 calculateVolumetricLight(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world, in float intensity) {  
    const vec3 attenCoeff = rayleighTransmittanceCoefficient + mieTransmittanceCoefficient;

    vec4 lightColor = vec4(0.0);

    vec4 colorDirect = lightColor;

    atmosphere(colorDirect.rgb, lightVector.xyz, sunVector, moonVector, ivec2(12, 2));

    lightColor.rgb = colorDirect.rgb;
    vec3 skyLightColor = vec3(0.0);

	vec3 rayVec  = end - start;
	     rayVec /= STEPS;
	float stepSize = length(rayVec);

	float VoL   = dot(normalize(end - start), lightVector2);
    float VolVol = VoL * VoL;
	float rayleigh = 3.0 / (16.0 * pi) * (1.0 + VolVol);
    float gg = mieG * mieG;
    float mie = 3.0 / (8.0 * pi) * ((1.0 - gg) * (VolVol + 1.0)) / (pow(1.0 + gg - 2.0 * VoL * mieG, 1.5) * (2.0 + gg));
    float phase = rayleigh + mie;

    vec3 scoeff = (rayleighScatteringCoefficient * rayleigh) + (mieScatteringCoefficient * mie);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / STEPS;
    start -= increment * bayer128(gl_FragCoord.st);

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse;

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor.rgb * phase;
    vec3 skylightContribution = skyLightColor;
    for (int i = 0; i < STEPS; i++) {
        curPos.xyz += increment;

        float gf = groundFog((mat3(shadowModelViewInverse) * (mat3(shadowProjectionInverse) * curPos.xyz + shadowProjectionInverse[3].xyz) + shadowModelViewInverse[3].xyz) + cameraPosition);

        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;
        float tex0 = texture(shadowtex0, shadowPos.st).r;
        float tex1 = texture(shadowtex1, shadowPos.st).r;
        float shadowOpaque = float(tex0 > shadowPos.p - 0.00003);
        float shadowTransparent = float(tex1 > shadowPos.p - 0.00003);
        vec3 shadowColor = texture(shadowcolor0, shadowPos.st).rgb;
        vec3 shadow = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque)) * sunlightConribution;

        scattered += ((shadow + skylightContribution) * transmittance) * gf;
        transmittance *= exp(-(attenCoeff) * (stepSize));
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-(attenCoeff) * (stepSize))) / (attenCoeff);

    return color * transmittance + (scattered * intensity);
}