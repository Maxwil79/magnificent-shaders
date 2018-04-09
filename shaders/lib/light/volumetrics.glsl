float groundFog(vec3 worldPos) {
	worldPos.y -= vl_Height_Rayleigh;
	float density = 1.0;
	density *= exp(-worldPos.y / 3.0);
    density = clamp(density, 0.0005, 6.2);
	return density;
}

#define VolumeDistanceMultiplier 3.0 //[0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0] The multiplier of which the Volume distance uses to multiply far by.
#define VolumeDistance far*VolumeDistanceMultiplier
#define VolumetricLightQuality 1 //[0 1 2 3 4 5 6]

//float dither=bayer16x16( ivec2(texcoord*vec2(viewWidth,viewHeight)) );

vec3 VL(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world, in float intensity) {  
    const vec3 attenCoeff = rayleighTransmittanceCoefficient + mieTransmittanceCoefficient;
    const vec3 waterAbsorb = attenCoeff + vec3(0.6, 0.5, 0.7); //Not physically based, and kinda here for testing purposes.

    lightmap = pow(lightmap, vec2(Attenuation, 5.0));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    #if VolumetricLightQuality == 0
    int steps = 1;
    #elif VolumetricLightQuality == 1
    int steps = 4;
    #elif VolumetricLightQuality == 2
    int steps = 8;
    #elif VolumetricLightQuality == 3
    int steps = 32;
    #elif VolumetricLightQuality == 4
    int steps = 64;
    #elif VolumetricLightQuality == 5
    int steps = 128;
    #elif VolumetricLightQuality == 6
    int steps = 2048;
    #endif

    vec3 lightColor = vec3(0.0);
    lightColor = get_atmosphere_transmittance(sunVector, upVector, moonVector);
    vec3 skyLightColor = vec3(0.0);

	vec3 rayVec  = end - start;
	     rayVec /= steps;
	float stepSize = length(rayVec);

	float VoL   = dot(normalize(end - start), lightVector);
	float rayleigh = phaseR(VoL);
    float mie = phaseM_CS(VoL, mieG);
    float isotropicPhase = 0.25 / pi;
    float phase = rayleigh + mie;

    vec3 scoeff = (rayleighScatteringCoefficient * rayleigh) + (mieScatteringCoefficient * mie);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / steps;
    increment /= distance(start, end) / clamp(distance(start, end), 0.0, VolumeDistance);
    start -= increment * dither2;

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse;

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor;
    vec3 skylightContribution = skyLightColor;
    for (int i = 0; i < steps; i++) {
        curPos.xyz += increment;

        float gf = groundFog((mat3(shadowModelViewInverse) * (mat3(shadowProjectionInverse) * curPos.xyz + shadowProjectionInverse[3].xyz) + shadowModelViewInverse[3].xyz) + cameraPosition);

        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;
        float tex0 = texture(shadowtex0, shadowPos.st).r;
        float tex1 = texture(shadowtex1, shadowPos.st).r;
        float shadowOpaque = float(tex0 > shadowPos.p - 0.00003);
        float shadowTransparent = float(tex1 > shadowPos.p - 0.00003);
        vec3 shadowColor = texture(shadowcolor0, shadowPos.st).rgb;
        vec3 shadow = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque)) * sunlightConribution;

        #ifdef WaterShadowEnable
        float shadowDepthSample = texture(shadowtex0, shadowPos.st).r - shadowPos.z;
        vec3 waterShadow = waterFogShadow((shadowDepthSample * 2.0) * shadowProjectionInverse[2].z);
        float waterShadowCast = float(texture(shadowcolor1, shadowPos.st).r > shadowPos.z - 0.0009);

        if(waterShadowCast == 1.0) shadow *= waterShadow;
        #endif

        scattered += ((shadow + skylightContribution) * transmittance) * gf;
        transmittance *= exp(-(attenCoeff) * (stepSize));
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-(attenCoeff) * (stepSize))) / (attenCoeff);

    return color * transmittance + (scattered * intensity);
}