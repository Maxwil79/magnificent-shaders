    for(int i = 0; i < diskOffset.length(); i++) {
	    vec3 sampleCoord = vec3((rot * diskOffset[i] * 0.0005) + shadowPos.st, shadowPos.p);
        shadowOpaque = float(texture(shadowtex0, sampleCoord.st).r > shadowPos.p - 0.00007);
        float shadowTransparent = float(texture(shadowtex1, sampleCoord.st).r > shadowPos.p - 0.00007);
        vec3 shadowColor = texture(shadowcolor0, sampleCoord.st).rgb;
        vec3 shadow = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
        shadows += shadow;
    }
    shadows /= diskOffset.length();