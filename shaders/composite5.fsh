#version 400

/* DRAWBUFFERS:03 */

//All TAA code comes from Spectrum, made by Zombye.

layout (location = 0) out vec4 color;

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex1;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView, gbufferPreviousProjection;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;

uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;

uniform float eyeAltitude;
uniform float viewWidth, viewHeight;
uniform float frameTimeCounter;
uniform int frameCounter;

vec2 screenRes = vec2(viewWidth, viewHeight);

vec3 screenSpaceToViewSpace(vec3 position, mat4 projectionInverse) {
	position = position * 2.0 - 1.0;
	return (vec3(projectionInverse[0].x, projectionInverse[1].y, projectionInverse[2].z) * position + projectionInverse[3].xyz) / (position.z * projectionInverse[2].w + projectionInverse[3].w);
}
vec3 viewSpaceToScreenSpace(vec3 position, mat4 projection) {
	position = (vec3(projection[0].x, projection[1].y, projection[2].z) * position + projection[3].xyz) / position.z;
	position.xy += projection[2].xy;
	return position * -0.5 + 0.5;
}

vec3 viewSpaceToSceneSpace(vec3 position, mat4 modelViewInverse) {
	return mat3(modelViewInverse) * position + modelViewInverse[3].xyz;
}
vec3 sceneSpaceToViewSpace(vec3 position, mat4 modelView) {
	return mat3(modelView) * position + modelView[3].xyz;
}

float linearizeDepth(float depth, mat4 projectionInverse) {
	return -1.0 / ((depth * 2.0 - 1.0) * projectionInverse[2].w + projectionInverse[3].w);
}
float delinearizeDepth(float depth, mat4 projection) {
	return ((depth * projection[2].z + projection[3].z) / depth) * -0.5 + 0.5;
}

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

vec3 taa_getClosestFragment() {
	vec2 pixel = 1.0 / vec2(viewWidth, viewHeight);

	vec3 closestFragment = vec3(texcoord, 1.0);

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 currentCoord = vec2(x, y) * pixel + texcoord;
			vec3 currentFragment = vec3(currentCoord, texture2D(depthtex1, currentCoord).r);

			closestFragment = currentFragment.z < closestFragment.z ? currentFragment : closestFragment;
		}
	}

	return closestFragment;
}
vec3 taa_velocity(vec3 position) {
	vec3 currentPosition = position;
	position  = screenSpaceToViewSpace(position, gbufferProjectionInverse);
	position  = viewSpaceToSceneSpace(position, gbufferModelViewInverse);
	position += cameraPosition - previousCameraPosition;
	position  = sceneSpaceToViewSpace(position, gbufferPreviousModelView);
	position  = viewSpaceToScreenSpace(position, gbufferPreviousProjection);

	return position - currentPosition;
}

#define TAA_BlendWeight 0.86 //[0.1 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.3 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.4 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.5 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.6 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.7 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.8 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.9 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.0] Higher means a more blurry result and more ghosting, whereas lower means more of a flicker and a sharper result.

vec3 taa_apply() {
	vec2 resolution = vec2(viewWidth, viewHeight);
	vec2 pixel = 1.0 / resolution;
	vec3 position = vec3(texcoord, texture2D(depthtex1, texcoord).r);
	float blendWeight = TAA_BlendWeight; // Base blend weight

	// Get velocity from closest fragment in 3x3 to camera rather than current fragment, gives nicer edges in motion.
	vec3 closestFragment = taa_getClosestFragment();
	vec3 velocity = taa_velocity(closestFragment);

	// Calculate reprojected position using velocity
	vec3 reprojectedPosition = position + velocity;

	// Offscreen fragments should be ignored
	if (floor(reprojectedPosition.xy) != vec2(0.0)) blendWeight = 0.0;

	// Reduce weight when further from a texel center, reduces blurring
	blendWeight *= sqrt(dot(0.5 - abs(fract(reprojectedPosition.xy * resolution) - 0.5), vec2(1.0))) * 0.6 + 0.4;

	// Get color values in 3x3 around current fragment
	vec3 centerColor, minColor, maxColor;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec3 sampleColor = texture2D(colortex0, vec2(x, y) * pixel + texcoord).rgb;

			if (x == -1 && y == -1) { // Initialize min & max color values
				minColor = sampleColor;
				maxColor = sampleColor;
				continue;
			}

			if (x == 0 && y == 0) centerColor = sampleColor;

			minColor = min(sampleColor, minColor);
			maxColor = max(sampleColor, maxColor);
		}
	}

	// Get reprojected previous frame color, clamped with min & max around current frame fragment to prevent ghosting
	vec3 prevColor = clamp(textureSmooth(colortex3, reprojectedPosition.st).rgb, minColor, maxColor);

	// Apply a simple tonemap, blend, reverse tonemap, and return.
	centerColor /= 1.0 + centerColor;
	prevColor   /= 1.0 + prevColor;

	vec3 antiAliased = mix(centerColor, prevColor, blendWeight);

	return antiAliased / (1.0 - antiAliased);
}

void main() {
    color.rgb = taa_apply();
}