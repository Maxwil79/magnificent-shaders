    shadowOpaque = float(texture(shadowtex0, shadowPos.st).r > shadowPos.p - 0.00007);
    float shadowTransparent = float(texture(shadowtex1, shadowPos.st).r > shadowPos.p - 0.00007);
    vec3 shadowColor = texture(shadowcolor0, shadowPos.st).rgb;
    shadowsCast = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
    shadows += shadowsCast;