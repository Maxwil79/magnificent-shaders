vec4 hash42(vec2 p)
{
	vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);

}

float bayer2(vec2 a){
    a = floor(a);
    return fract( dot(a, vec2(.5, a.y * .75)) );
}
#define bayer4(a)   (bayer2( .5*(a))*.25+bayer2(a))
#define bayer8(a)   (bayer4( .5*(a))*.25+bayer2(a))
#define bayer16(a)  (bayer8( .5*(a))*.25+bayer2(a))
#define bayer32(a)  (bayer16(.5*(a))*.25+bayer2(a))
#define bayer64(a)  (bayer32(.5*(a))*.25+bayer2(a))

float ssao (vec3 position, vec3 normal) {
    float dither = bayer64(gl_FragCoord.st);
    float result = 0.0;
    for(float i = -0.0; i <= 15.0; i++){
        vec4 noise = hash42(vec2(i, dither));
        vec3 offset = normalize(noise.xyz * 2.0 - 1.0) * noise.w;
        if (dot(offset, normal) < 0.0) offset = -offset;
        vec3 samplePosition = offset * 1.5 + position;
        samplePosition = viewSpaceToScreenSpace(samplePosition, gbufferProjection);
        float depth = texture(depthtex1, samplePosition.st).r;

        if (depth > samplePosition.z) result += 1.1;
    }
    result /= 15.0;
    return result;
}