float length2(vec2 x){return dot(x,x);}

vec4 textureBicubic(sampler2D sampler, vec2 coord) {
	vec2 res = textureSize(sampler, 0);

	coord = coord * res - 0.5;

	vec2 f = fract(coord);
	coord -= f;

	vec2 ff = f * f;
	vec4 w0;
	vec4 w1;
	w0.xz = 1.0 - f; w0.xz *= w0.xz * w0.xz;
	w1.yw = ff * f;
	w1.xz = 3.0 * w1.yw + 4.0 - 6.0 * ff;
	w0.yw = 6.0 - w1.xz - w1.yw - w0.xz;

	vec4 s = w0 + w1;
	vec4 c = coord.xxyy + vec2(-0.5, 1.5).xyxy + w1 / s;
	c /= res.xxyy;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(
		mix(texture(sampler, c.yw), texture(sampler, c.xw), m.x),
		mix(texture(sampler, c.yz), texture(sampler, c.xz), m.x),
		m.y);
}

vec4 textureBicubicLod(sampler2D sampler, vec2 coord, int lod) {
	vec2 res = textureSize(sampler, lod);

	coord = coord * res - 0.5;

	vec2 f = fract(coord);
	coord -= f;

	vec2 ff = f * f;
	vec4 w0;
	vec4 w1;
	w0.xz = 1.0 - f; w0.xz *= w0.xz * w0.xz;
	w1.yw = ff * f;
	w1.xz = 3.0 * w1.yw + 4.0 - 6.0 * ff;
	w0.yw = 6.0 - w1.xz - w1.yw - w0.xz;

	vec4 s = w0 + w1;
	vec4 c = coord.xxyy + vec2(-0.5, 1.5).xyxy + w1 / s;
	c /= res.xxyy;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(
		mix(textureLod(sampler, c.yw, lod), textureLod(sampler, c.xw, lod), m.x),
		mix(textureLod(sampler, c.yz, lod), textureLod(sampler, c.xz, lod), m.x),
		m.y);
}