float linearizeDepth(float depth) {
    return -1.0 / ((depth * 2.0 - 1.0) * gbufferProjectionInverse[2].w + gbufferProjectionInverse[3].w);
}

#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

vec4 screenSpaceToViewSpace(in vec4 screenSpace) {
	vec4 viewSpace = gbufferProjectionInverse * signed(screenSpace);
	return viewSpace / viewSpace.w;
}

vec4 screenSpaceToViewSpace(in vec2 coord, in float depth) {
	vec4 viewSpace = gbufferProjectionInverse * signed(vec4(coord, depth, 1.0));
	return viewSpace / viewSpace.w;
}

vec4 screenSpaceToViewSpace(in float depth) {
	vec4 viewSpace = gbufferProjectionInverse * signed(vec4(textureCoordinate.st, depth, 1.0));
	return viewSpace / viewSpace.w;
}

vec3 screenSpaceToViewSpace(vec3 position, mat4 projectionInverse) {
	position = position * 2.0 - 1.0;
	return (vec3(projectionInverse[0].x, projectionInverse[1].y, projectionInverse[2].z) * position + projectionInverse[3].xyz) / (position.z * projectionInverse[2].w + projectionInverse[3].w);
}

vec4 viewSpaceToScreenSpace(in vec4 viewSpace) {
	viewSpace = gbufferProjection * viewSpace;
	viewSpace /= viewSpace.w;
	return unsigned(viewSpace);
}

vec4 viewSpaceToScreenSpace(in float depth) {
	vec4 viewSpace = gbufferProjection * vec4(textureCoordinate.st, depth, 1.0);
	viewSpace /= viewSpace.w;
	return unsigned(viewSpace);
}

vec3 viewSpaceToScreenSpace(vec3 position, mat4 projection) {
	return ((vec3(projection[0].x, projection[1].y, projection[2].z) * position + projection[3].xyz) / position.z) * -0.5 + 0.5;
}

float minof(vec2 x) { return min(x.x, x.y); }
float minof(vec3 x) { return min(min(x.x, x.y), x.z); }
float minof(vec4 x) { x.xy = min(x.xy, x.zw); return min(x.x, x.y); }

#define saturate(x) clamp(x, 0.0, 1.0)