#define saturate(x) clamp(x, 0.0, 1.0)

#define rcp(x) ( 1.0 / x )

vec3 screenSpaceToViewSpace(vec3 position, mat4 projectionInverse) {
	position = position * 2.0 - 1.0;
	return (vec3(projectionInverse[0].x, projectionInverse[1].y, projectionInverse[2].z) * position + projectionInverse[3].xyz) / (position.z * projectionInverse[2].w + projectionInverse[3].w);
}

vec3 viewSpaceToScreenSpace(vec3 position, mat4 projection) {
	return ((vec3(projection[0].x, projection[1].y, projection[2].z) * position + projection[3].xyz) / position.z) * -0.5 + 0.5;
}

float minof(vec2 x) { return min(x.x, x.y); }
float minof(vec3 x) { return min(min(x.x, x.y), x.z); }
float minof(vec4 x) { x.xy = min(x.xy, x.zw); return min(x.x, x.y); }