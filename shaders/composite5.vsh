#version 400

layout (location = 0) in vec2 inPosition;
layout (location = 8) in vec2 inTexCoord;

out vec2 texcoord;

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

mat4 projectionInverse = mat4(0.0);
mat4 projection = mat4(0.0);

uniform float viewWidth, viewHeight;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform int frameCounter;

vec4 textureSmooth(sampler2D sampler, vec2 coord) {
	vec2 resolution = textureSize(sampler, 0);
	coord = coord * resolution + 0.5;
	vec2 floored = floor(coord);
	coord -= floored;
	coord *= coord * (-2.0 * coord + 3.0);
	coord += floored - 0.5;
	coord /= resolution;
	return texture2D(sampler, coord);
}

vec2 haltonSequence(vec2 i, vec2 b) {
	vec2 f = vec2(1.0), r = vec2(0.0);
	while (i.x > 0.0 || i.y > 0.0) {
		f /= b;
		r += f * mod(i, b);
		i  = floor(i / b);
	} return r;
}

vec2 taa_offset() {
	vec2 scale = 2.0 / vec2(viewWidth, viewHeight);

	return haltonSequence(vec2(frameCounter % 16), vec2(2.0, 3.0)) * scale + (-0.5 * scale);
}

void calculateGbufferMatrices() {
	projection = gbufferProjection;
	projectionInverse = gbufferProjectionInverse;

	// Add per-frame offset for TAA
	vec2 offset = taa_offset();
	projection[2].xy += offset;
	projectionInverse[3].xy += offset * vec2(projectionInverse[0].x, projectionInverse[1].y);
}

void main() {
    calculateGbufferMatrices();

    gl_Position = vec4(inPosition.xy * 2.0 - 1.0, 0.0, 1.0);

    texcoord = inTexCoord.xy;
}