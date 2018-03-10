#define MaxHeight 64.0 //[4.0 8.0 16.0 32.0 64.0 128.0 256.0 512.0]

float groundFog(vec3 worldPos) {
	worldPos.y -= MaxHeight;
	float density = 1.0;
	density *= exp(-worldPos.y / 2.0);
    density = clamp(density, 0.0, 2.4);
	return density;
}

#define STEPS 5 //[1 2 3 4 5 10 15 20 25 30 35 40 45 65 70 75] Higher steps equals more quality, but lower FPS. Lower numbers look better with a lower VolumeDistanceMultiplier.
#define VolumeDistanceMultiplier 0.75 //[0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0] The multiplier of which the Volume distance uses to multiply far by.
#define VolumeDistance far*VolumeDistanceMultiplier
#define intensityMult 1e0 //[1e0 2e0 3e0 4e0 5e0 6e0 7e0 8e0 9e0 1e1] The intensity multiplier of the VL.

//float dither=bayer16x16( ivec2(texcoord*vec2(viewWidth,viewHeight)) );

vec3 VL(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world, in float intensity) {  
    const vec3 attenCoeff = rayleighTransmittanceCoefficient + mieTransmittanceCoefficient;
    const vec3 waterAbsorb = attenCoeff + vec3(0.6, 0.5, 0.7); //Not physically based, and kinda here for testing purposes.

    lightmap = pow(lightmap, vec2(Attenuation, 5.0));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec3 lightColor = vec3(0.0);
    lightColor = get_atmosphere_transmittance(sunVector, upVector, moonVector);
    vec3 skyLightColor = vec3(0.0);

	vec3 rayVec  = end - start;
	     rayVec /= STEPS;
	float stepSize = length(rayVec);

	float VoL   = dot(normalize(end - start), lightVector);
	float rayleigh = phaseR(VoL);
    float mie = phaseM_CS(VoL, mieG);
    float isotropicPhase = 0.25 / pi;
    float phase = rayleigh + mie;

    vec3 scoeff = (rayleighScatteringCoefficient * rayleigh) + (mieScatteringCoefficient * mie);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / STEPS;
    increment /= distance(start, end) / clamp(distance(start, end), 0.0, VolumeDistance);
    start -= increment * dither;

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse;

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor;
    vec3 skylightContribution = skyLightColor;
    for (int i = 0; i < STEPS; i++) {
        curPos.xyz += increment;
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

        scattered += (shadow + skylightContribution) * transmittance;
        transmittance *= exp(-(attenCoeff) * (stepSize));
    } scattered *= scoeff;
    //scattered *= waterAbsorb;
    scattered *= (1.0 - exp(-(attenCoeff) * (stepSize))) / (attenCoeff);

    return color * transmittance + (scattered * intensity);
}