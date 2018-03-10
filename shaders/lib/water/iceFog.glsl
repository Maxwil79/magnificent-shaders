//This will eventually be merged with the water fog function.

vec3 waterFogVolumetricIce(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world) {  
    const vec3 attenCoeff = acoeff2 + scoeff2;
    float density = 1.0;


    lightmap = pow(lightmap, vec2(Attenuation, 5.0));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec3 lightColor = vec3(0.0);
    lightColor = get_atmosphere_transmittance(sunVector, upVector, moonVector);
    vec3 skyLightColor = vec3(0.0);

	vec3 rayVec  = end - start;
	     rayVec /= FogSteps;
	float stepSize = length(rayVec);

	float VoL   = dot(normalize(end - start), lightVector);
	float rayleigh = rayleighPhase(VoL);
    float mie = miePhase(VoL, 0.5);
    float isotropicPhase = 0.25 / pi;
    float waterPhase = isotropicPhase * 0.7 + water_fournierForandPhase(acos(dot(normalize(end - start), lightVector)), 4.25, 1.01) * 0.3;

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / FogSteps;
    start -= increment * dither;

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse; //Thank you to BuilderB0y for showin me this. 

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor;
    vec3 skylightContribution = skyLightColor;
    for (int i = 0; i < FogSteps; i++) {
        curPos.xyz += increment;
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;
        float tex0 = texture(shadowtex0, shadowPos.st).r;
        float tex1 = texture(shadowtex1, shadowPos.st).r;
        float shadowOpaque = float(tex0 > shadowPos.p - 0.000003);
        float shadowTransparent = float(tex1 > shadowPos.p - 0.000003);
        vec3 shadow = mix(vec3(shadowOpaque), vec3(1.0), float(shadowTransparent > shadowOpaque)) * sunlightConribution;

        #ifdef WaterShadowEnable
        float shadowDepthSample = tex0 - shadowPos.z;
        vec3 waterShadow = waterFogShadow((shadowDepthSample * 2.0) * shadowProjectionInverse[2].z);
        float waterShadowCast = float(texture(shadowcolor1, shadowPos.st).r > shadowPos.z - 0.0009);

        if(waterShadowCast == 1.0) shadow *= waterShadow;
        #endif

        scattered += (shadow + skylightContribution) * transmittance;
        transmittance *= exp(-(attenCoeff * density) * (stepSize));
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-(attenCoeff * density) * (stepSize))) / (attenCoeff * density);

    return color * transmittance + scattered;
}