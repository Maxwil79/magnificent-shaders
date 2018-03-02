float better_fresnel(in vec3 viewVector, in vec3 normal) {
    //The code in this function was shared by stduhpf.
    float n0 = 1.333;
    vec3 ri = normalize(viewVector.xyz);
    vec3 rt = refract(ri, normal, 1./n0);
    float cti = dot(ri,normal),ctt = dot(rt,normal);
    float fresnel = (n0*cti-ctt)/(n0*cti+ctt);
    fresnel*=fresnel;
    float fresnel2 = (ctt-n0*cti)/(n0*cti+ctt);
    fresnel =.75*(fresnel+fresnel2*fresnel2);
    return fresnel;
}

vec3 reflection(in vec3 view, in vec3 viewVector) {
    vec3 reflection = vec3(0.0);
    int i = 0;
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;
    viewPosition = normalize(viewPosition);
    vec3 viewVec3 = vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r);
    int samples = SsrSamples;
    vec3 shadows = decode3x16(texture(colortex0, textureCoordinate.st).a);
    float skyLight = pow(decode2x16(texture(colortex4, textureCoordinate.st).r).y, 7.0);
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);

    vec3 normal;

    float roughness = RoughnessValue;
    float roughnessSquared = roughness*roughness;

    for(i = 0; i < samples; i++) {
    normal = mix(clampNormal(waterNormal, view), normalize(hash33(view.xyz + i) * 2.0 - 1.0), roughnessSquared);

    float fresnelR = better_fresnel(view, normal);
    float fresnelT = better_fresnel(view, normal);
    
    vec3 direction = reflect(viewPosition.xyz, normal);
    vec3 direction1 = mat3(gbufferModelViewInverse) * reflect(viewPosition.xyz, normal);
    vec4 hitPosition;
    if (raytraceIntersection(viewVec3, direction, hitPosition.xyz, 64.0, 4.0)) {
        reflection += textureLod(colortex0, hitPosition.xy, 0).rgb * fresnelR;
        continue;
    }

    reflection += skyLight * get_atmosphere(vec3(0.0), direction1, sunVector2, moonVector2) * fresnelT;
    }
    vec3 moon = (moonColor) * vec3(clamp01(GGX(waterNormal, normalize(-view.xyz), moonVector, 0.08*0.08, 0.5))) * shadows;
    vec3 specular = (get_atmosphere_transmittance(sunVector, upVector, moonVector) * sunColor) * vec3(clamp01(GGX(waterNormal, normalize(-view.xyz), sunVector, 0.08*0.08, 0.5))) * shadows;
    vec3 backGround = specular + moon;
    reflection += backGround;
    
    return reflection / samples;
}