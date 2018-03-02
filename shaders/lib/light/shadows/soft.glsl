    for(int i = 0; i < 5; i++) {
        for(int j = 0; j < 5; j++) {
		    vec2 sampleOffset = vec2(i, j);
		    vec2 circle = (sampleOffset - 2) * max(abs(normalize(sampleOffset - 2).x), abs(normalize(sampleOffset - 2).y));
	        vec3 sampleCoord = vec3(shadowPos.st + (rot * circle * 0.0004), shadowPos.p);
            float shadowOpaque = float(texture(shadowtex0, sampleCoord.st).r > shadowPos.p - 0.00009);
            float shadowTransparent = float(texture(shadowtex1, sampleCoord.st).r > shadowPos.p - 0.00009);
            vec3 shadowColor = texture(shadowcolor0, sampleCoord.st).rgb;
            shadowsCast = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
            shadows += shadowsCast;
        }
    }
    shadows /= 5*5;