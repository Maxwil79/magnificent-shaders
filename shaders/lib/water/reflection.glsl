float Fresnel(in vec3 viewVector, in vec3 normal) {
    float n0 = 1.333;
    vec3 ri = normalize(viewVector.xyz);
    vec3 rt = refract(ri, normal, 1./n0);
    float cti = dot(ri,normal),ctt = dot(rt,normal);
    float fresnel = (n0*cti-ctt)/(n0*cti+ctt);
    fresnel*=fresnel;
    float fresnel2 = (ctt-n0*cti)/(n0*cti+ctt);
    fresnel =.5*(fresnel+fresnel2*fresnel2);
    return fresnel;
}

vec3 reflection(in vec3 view) {
    vec3 reflection = vec3(0.0);
    int i = 0;
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;
    //vec2 lightmap = texture(colortex2, textureCoordinate).rg;
    vec3 viewVec3 = vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r);
    int samples = SsrSamples;
    float shadows = texture(colortex0, textureCoordinate.st).a;
    float skyLight = decode2x16(texture(colortex4, textureCoordinate.st).r).y;
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);

    float schlick = (1.0 - 0.02) * pow(1.0 - clamp(dot(-normalize(viewPosition.xyz), waterNormal), 0.0, 1.0), 5.0) + 0.02;

    vec3 normal;

    float roughness = RoughnessValue;
    float roughnessSquared = roughness*roughness;

    //vec3 shadows = texture(colortex6, textureCoordinate.st).rgb * 0.04;

    for(i = 0; i < samples; i++) {
    normal = mix(clampNormal(waterNormal, view), normalize(hash33(view.xyz + i) * 2.0 - 1.0), roughnessSquared);

    float fresnelR = 0.0;

    fresnelR = Fresnel(view.xyz, normal);

    vec3 direction = reflect(normalize(viewPosition.xyz), normal);
    vec4 hitPosition;
    #ifdef SSR
    if (raytraceIntersection(viewVec3, direction, hitPosition.xyz, 32.0, 4.0)) {
        reflection += textureLod(colortex0, hitPosition.xy, 0).rgb * fresnelR;
        continue;
    }
    #endif

    //vec3 sun = calculateSun(sunVector, normalize(direction.xyz)) * shadows;
    vec3 moon = (moonColor) * vec3(clamp01(GGX(waterNormal, normalize(-view.xyz), moonVector, 0.08*0.08, 0.5))) * shadows;
    vec3 specular = (atmosphereTransmittance(sunVector, upVector, moonVector) * 150.0) * vec3(clamp01(GGX(waterNormal, normalize(-view.xyz), sunVector, 0.08*0.08, 0.5))) * shadows;
    vec3 backGround = specular + moon;

    reflection += pow(skyLight, 7.0) * get_atmosphere(vec3(0.0), direction, sunVector, upVector, moonVector) * fresnelR;
    reflection += backGround;
    }
    return reflection / samples;
}