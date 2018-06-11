#define clamp01(x) clamp(x, 0.0, 1.0)

vec2 decode2x16(float a){
    int bf = int(a*65535.);
    return vec2(bf%256, bf>>8) / 255.;
}

vec3 decodeNormal3x16(float encoded){
    vec2 a = decode2x16(encoded);

    a = a * 2.0 - 1.0;
    vec2 b = abs(a);
    float z = 1.0 - b.x - b.y;
    vec2 sa = vec2(greaterThanEqual(a, vec2(0.0))) * 2.0 - 1.0;

    vec3 decoded = normalize(vec3(
        z < 0.0 ? (1.0 - b.yx) * sa : a.xy,
        z
    ));

    return decoded;
}

vec3 decode3x16(float a){
    int bf = int(a*65535.);
    return vec3(bf%32, (bf>>5)%64, bf>>11) / vec3(31,63,31);
}
/*
vec3 unpackNormal(vec2 pack) {
	vec4 normal = vec4(pack * 2.0 - 1.0, 1.0, -1.0);
	normal.z    = dot(normal.xyz, -normal.xyw);
	normal.xy  *= sqrt(normal.z);
	return normal.xyz * 2.0 + vec3(0.0, 0.0, -1.0);
}
*/
vec3 unpackNormal(vec2 encodedNormal) {
	encodedNormal = encodedNormal * 4.0 - 2.0;
	float f = dot(encodedNormal, encodedNormal);
	return vec3(encodedNormal * sqrt(clamp(f * -0.25 + 1.0, 0.0, 1.0)), f * -0.5 + 1.0); // clamped because float inaccuracy sometimes causes negative values to be passed into the sqrt, resulting in non-numerical values.
}

#define color_bits vec4(6)
#define color_values exp2(color_bits)
#define color_rvalues (1.0 / color_values)
#define color_maxValues (color_values - 1.0)
#define color_rmaxValues (1.0 / color_maxValues)
#define color_positions vec4(1.0, color_values.x, color_values.x * color_values.y, color_values.x * color_values.y * color_values.z)
#define color_rpositions (16777215.0 / color_positions)

vec4 decode4x16(float a){
    return mod(a * color_rpositions, color_values) * color_rmaxValues;
}