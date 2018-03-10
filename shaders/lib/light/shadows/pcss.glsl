    for(int i = 0; i < 7; i++) {
        for(int j = 0; j < 7; j++) {
		    vec2 sampleOffset = vec2(i, j) - 3;
			vec2 tmp = abs(normalize(sampleOffset));
			vec2 circle = sampleOffset * max(tmp.x, tmp.y);
	        vec3 sampleCoord = vec3(shadowPos.st + (rot * circle * 0.075 * penumbraSize), shadowPos.p);
            float shadowOpaque = float(texture(shadowtex0, sampleCoord.st).r > shadowPos.p - 0.009 / (distortionFactor * distortionFactor));
            float shadowTransparent = float(texture(shadowtex1, sampleCoord.st).r > shadowPos.p - 0.009 / (distortionFactor * distortionFactor));
            vec3 shadowColor = texture(shadowcolor0, sampleCoord.st).rgb;
            shadowsCast = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
            shadows += shadowsCast;
        }
    }
    shadows /= 7*7;