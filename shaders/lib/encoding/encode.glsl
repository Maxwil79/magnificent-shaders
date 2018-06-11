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

#define color_bits vec4(6)
#define color_values exp2(color_bits)
#define color_rvalues (1.0 / color_values)
#define color_maxValues (color_values - 1.0)
#define color_rmaxValues (1.0 / color_maxValues)
#define color_positions vec4(1.0, color_values.x, color_values.x * color_values.y, color_values.x * color_values.y * color_values.z)
#define color_rpositions (16777215.0 / color_positions)

float encode4x16(vec4 a) {
    return dot(floor(clamp01(a) * color_maxValues + 0.5), color_positions / 16777215.0);
}