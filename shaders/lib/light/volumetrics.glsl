#define MaxHeight 32.0 //[4.0 8.0 16.0 32.0 64.0 128.0 256.0 512.0]

float groundFog(vec3 worldPos) {
	worldPos.y -= MaxHeight;
	float density = 1.0;
	density *= exp(-worldPos.y / 8.0);
    density = clamp(density, 0.0, 0.04);
	return density;
}

#define STEPS 2 //[1 2 3 4 5 10 15 20 25 30 35 40 45 65 70 75] Higher steps equals more quality, but lower FPS. Lower numbers look better with a lower VolumeDistanceMultiplier.
#define VolumeDistanceMultiplier 0.75 //[0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0] The multiplier of which the Volume distance uses to multiply far by.
#define VolumeDistance far*VolumeDistanceMultiplier

//float dither=bayer16x16( ivec2(texcoord*vec2(viewWidth,viewHeight)) );

vec4 VL(vec3 viewVector) {
    vec4 endPos = gbufferProjectionInverse * (vec4(textureCoordinate.st, texture(depthtex0, textureCoordinate.st).r, 1.0) * 2.0 - 1.0);
    endPos /= endPos.w;
    endPos = shadowProjection * shadowModelView * gbufferModelViewInverse * endPos;
    vec4 startPos = shadowProjection * shadowModelView * gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 dir = normalize(endPos - startPos);

    vec4 worldEndPos = gbufferProjectionInverse * (vec4(textureCoordinate.st, texture(depthtex0, textureCoordinate.st).r, 1.0) * 2.0 - 1.0);
    worldEndPos /= worldEndPos.w;
    worldEndPos = gbufferModelViewInverse * worldEndPos;
    vec4 worldStartPos = gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0);
    vec4 worldDir = normalize(worldEndPos - worldStartPos);

    vec4 worldIncrement = worldDir * distance(worldEndPos, worldStartPos) / STEPS;
    worldIncrement /= distance(worldStartPos, worldEndPos) / clamp(distance(worldStartPos, worldEndPos), 0.0, VolumeDistance);
    worldStartPos -= worldIncrement * dither;
    vec4 worldCurPos = worldStartPos;
    
    vec4 increment = dir * distance(endPos, startPos) / STEPS;
    increment /= distance(worldStartPos, worldEndPos) / clamp(distance(worldStartPos, worldEndPos), 0.0, VolumeDistance);
    startPos -= increment * dither;
    vec4 curPos = startPos;

    mat4 matrix = shadowModelViewInverse * shadowProjectionInverse;

    float lengthOfIncrement = length(worldIncrement);

    vec3 lightColor = vec3(0.0);
   // if (rainStrength == 0.0) {
    lightColor = vec3(0.0007 * get_atmosphere_transmittance(sunVector, upVector, moonVector));
   // } else {
   // lightColor = vec3(0.0009 * skyRainShadin(upVector) * (0.35 * timeVector.x + 25.5 * timeVector.y + 0.16 * timeVector.z));
   // }

    vec4 result = vec4(0.0);
    float shadowDepthSample = 0.0;
    worldCurPos.xyz += cameraPosition;
    for (int j = 0; j < STEPS; j++) {
            worldCurPos += worldIncrement;
            curPos += increment;
            vec3 shadowPos = (curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0)) * 0.5 + 0.5;
            float shadowOpaque = float(texture(shadowtex0, shadowPos.st).r > shadowPos.p - 0.00008);
            float shadowTransparent = float(texture(shadowtex1, shadowPos.st).r > shadowPos.p - 0.00008);
            vec3 shadowColor = texture(shadowcolor0, shadowPos.st).rgb;
            vec3 shadow = mix(vec3(shadowOpaque), shadowColor, float(shadowTransparent > shadowOpaque));
            shadowDepthSample = texture(shadowtex0, shadowPos.st).r - shadowPos.z;

            result += vec4(shadow * lengthOfIncrement * groundFog(worldCurPos.xyz), 1.0) * vec4(lightColor, 1.0);
    }

	float VoL   = dot(viewVector, lightVector);
	float rayleigh = rayleighPhase(VoL);
    float mie = miePhase(VoL, 0.5);

    return 30.0 * result * vec4(mie + rayleigh);
}