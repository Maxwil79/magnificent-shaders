#define VolumeDistanceMultiplier 9.75 //[0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0] The multiplier of which the Volume distance uses to multiply far by.
#define VolumeDistance far*VolumeDistanceMultiplier
#define VlMode 0 //[0 1] Changes the coefficients and intensity of VL.

const vec3 rayleighScatteringCoefficient = vec3(4.593e-6, 1.097e-5, 2.716e-5) * 1e2;
const vec3      mieScatteringCoefficient = vec3(3e-4); //Good default

const vec3 rayleighTransmittanceCoefficient = rayleighScatteringCoefficient;
const vec3      mieTransmittanceCoefficient =      mieScatteringCoefficient * 1.11;

vec3 calculateVolumetricLight(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world, in float intensity) {  
    const vec3 attenCoeff = (rayleighTransmittanceCoefficient + mieTransmittanceCoefficient);

    vec3 scatterCol = vec3(0.0);

    vec3 colorDirect = sunLight;
    vec3 colorSky = skyLight;

    lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec3 lightColor = vec3(0.0);
    lightColor = colorDirect.rgb;
    vec3 skyLightColor = colorSky.rgb * (vec3(0.93636, 1.1606, 1.40908)) * lightmap.y;

	vec3 rayVec  = end - start;
	     rayVec /= VolumetricSteps;
	float stepSize = length(rayVec);

    float vlG = 0.99;

	float VoL   = dot(normalize(end - start), lightVector2);
    float VolVol = VoL * VoL;
	float rayleigh = rayleighPhase(VoL);
    float gg = vlG * vlG;
    float mie = miePhase(VoL, vlG);
    vec2 phase = vec2(rayleigh, mie);

    vec3 scoeff = (rayleighScatteringCoefficient * rayleigh) + (mieScatteringCoefficient * mie);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / VolumetricSteps;
    start -= increment * dither2;

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse;

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor.rgb;
    vec3 skylightContribution = vec3(0.0);
    for (int i = 0; i < VolumetricSteps; ++i) {
        curPos.xyz += increment;
        float gf = groundFog((mat3(shadowModelViewInverse) * (mat3(shadowProjectionInverse) * curPos.xyz + shadowProjectionInverse[3].xyz) + shadowModelViewInverse[3].xyz) + cameraPosition, 76.0, 10.0);
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 4.0) * 0.5 + 0.5;
        vec3 shadowColor = texture(shadowcolor0, shadowPos.st).rgb;
    	float shadowOpaque      = float(textureLod(shadowtex0,   shadowPos.st,    0).r > shadowPos.p - 0.000003);
	    float shadowTransparent = float(textureLod(shadowtex1,   shadowPos.st, 0).r > shadowPos.p - 0.000003);

	    vec3 shadow = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
	    shadow *= sunlightConribution;
        shadow *= clamp(gf, 0.0, 0.1);

        scattered += ((shadow + skylightContribution) * transmittance);
        transmittance *= exp(-(attenCoeff) * (stepSize));
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-(attenCoeff) * (stepSize))) / (attenCoeff);
    scattered *= 2e2;

    return color * transmittance + scattered;
}