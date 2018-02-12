#define clamp01(x) clamp(x, 0.0, 1.0)

float encode2x16(vec2 a){
    ivec2 bf = ivec2(a*255.);
    return float( bf.x|(bf.y<<8) ) / 65535.;
}

float encodeNormal3x16(vec3 a){
    vec3 b = abs(a);
    vec2 p = a.xy / (b.x + b.y + b.z);
    vec2 sp = vec2(greaterThanEqual(p,vec2(0))) * 2.0 - 1.0;

    vec2 encoded = a.z <= 0.0 ? (1.0 - abs(p.yx)) * sp : p;

    encoded = encoded * 0.5 + 0.5;

    return encode2x16(encoded);
}

vec2 packNormal(vec3 normal) {
	return normal.xy * inversesqrt(normal.z * 8.0 + 8.0) + 0.5;
}

float encode3x16(vec3 a){
    vec3 m = vec3(31,63,31);
    a = clamp01(a);
    ivec3 b = ivec3(a*m);
    return float( b.r|(b.g<<5)|(b.b<<11) ) / 65535.;
}