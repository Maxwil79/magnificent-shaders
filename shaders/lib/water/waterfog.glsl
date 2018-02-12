vec3 waterFog(vec3 color, float dist) {
    vec3 acoeff = vec3(.4510, .0567, .0476 ) / log(1.5);
    vec3 scoeff = vec3(6.9, 7.5, 7.1) * 0.0005 / log(1.5);

    float shadows = texture(colortex0, textureCoordinate.st).a;
    if(isEyeInWater == 1) shadows = 1.0;

    vec3 lightColor = vec3(0.0);
    lightColor = vec3(get_atmosphere(vec3(0.0), vec3(0.0), sunVector, upVector, moonVector)) / pi;
    vec2 lightmap = decode2x16(texture(colortex4, textureCoordinate.st).r);

    vec3 depthColors = vec3(1.0);

    vec3 attenCoeff = scoeff + acoeff;

    vec3 waterColors = attenCoeff+1.1;

    vec3 transmittance = exp(-attenCoeff * dist);
	vec3 scattered  = scoeff * (1.0 - transmittance) / acoeff;

    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;
    vec3 lighting = pow(lightmap.y, 4.0) * lightColor;

    return color * transmittance + lighting * scattered;
}

// Volumetric Water Fog
float pow2(in float n)  { return n * n; }

vec3 waterFogAmbient(float dist, vec3 lightColor, vec3 attenCoeff) {
    //vec3 acoeff = vec3(1.35, 0.05, 0.03) * 40.5;
    //vec3 scoeff = vec3(0.0000, 0.01, 0.01) * 4.5;

    //vec3 attenCoeff = scoeff + acoeff;

    vec2 lightmap = texture(colortex2, textureCoordinate.st).rg;
    vec3 transmittance = exp(-attenCoeff * clamp(dist, 0.0, 4e12));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    return ((transmittance * 45e-2) * pow(lightmap.y, 5.0)) * lightColor;
}

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

vec3 waterFogVolumetric(vec3 color, vec3 start, vec3 end, vec2 lightmap, vec3 world) {  
    const vec3 attenCoeff = acoeff + scoeff;

    vec3 lightColor = vec3(0.0);
    lightColor = vec3(atmosphereTransmittance(sunVector, upVector, moonVector)) / 4.0;
    vec3 skylightColor = physicalAtmosphere(vec3(0.0), vec3(0.0), sunVector, upVector, skyQuality_I, skyQuality_J, moonVector) / (FogSteps);

	vec3 rayVec  = end - start;
	     rayVec /= FogSteps;
	float stepSize = length(rayVec);

    // mu=4.25 n=1.01
    // mu=3.52 n=1.08
    // mu=3.23 n=1.24

	float VoL   = dot(normalize(start), lightVector);
	float rayleigh = rayleighPhase(VoL);
    float mie = miePhase(VoL, 0.5);
    float isotropicPhase = 0.25 / pi;
    float waterPhase = isotropicPhase * 0.7 + water_fournierForandPhase(acos(dot(normalize(start), lightVector)), 3.23, 1.24) * 0.3;

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
    vec3 skylightContribution = vec3(0.0);
    for (int i = 0; i < FogSteps; i++) {
        curPos.xyz += increment;
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;
        float tex0 = texture(shadowtex0, shadowPos.st).r;
        float tex1 = texture(shadowtex1, shadowPos.st).r;
        float shadowOpaque = float(tex0 > shadowPos.p - 0.00003);
        float shadowTransparent = float(tex1 > shadowPos.p - 0.00003);
        vec3 shadow = mix(vec3(shadowOpaque), vec3(1.0), float(shadowTransparent > shadowOpaque)) * sunlightConribution;

        #ifdef WaterShadowEnable
        float shadowDepthSample = texture(shadowtex0, shadowPos.st).r - shadowPos.z;
        vec3 waterShadow = waterFogShadow((shadowDepthSample * 2.0) * shadowProjectionInverse[2].z);
        float waterShadowCast = float(texture(shadowcolor1, shadowPos.st).r > shadowPos.z - 0.0009);

        if(waterShadowCast == 1.0) shadow *= waterShadow;
        #endif

        scattered += (shadow + skylightContribution) * transmittance;
        transmittance *= exp(-attenCoeff * (stepSize));
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-attenCoeff * (stepSize))) / attenCoeff;

    return color * transmittance + scattered;
}