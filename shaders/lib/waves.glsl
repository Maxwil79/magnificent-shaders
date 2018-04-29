const int noiseTextureResolution = 512;

vec2 rotateNoMat(vec2 coord, float a, float b) {
    float ns = b * coord.y + a * coord.x;
    float nc = a * coord.y - b * coord.x;
    return vec2(ns, nc);
}

float waterNoise(vec2 coord) {
		vec2 floored = floor(coord);
		vec4 samples = textureGather(noisetex, (floored + 0.5) / noiseTextureResolution);
		vec4 weights = (coord - floored).xxyy * vec4(1,-1,1,-1) + vec4(0,1,0,1);
		weights *= weights * (-2.0 * weights + 3.0);
		return dot(samples, weights.yxxy * weights.zzww);
}

float waterHeight(vec3 position) {
	float waves = 0.0;

    vec2 pos = rotateNoMat(position.xz, 1.0, 4.0);

    waves += waterNoise(pos*vec2(14.0, 1.0)/14.0 + frameTimeCounter*vec2(0.0073, 0.0072) * noiseTextureResolution);
    waves += waterNoise(pos*vec2(1.0, 14.0)/12.0 + frameTimeCounter*vec2(0.0073, 0.0072) * noiseTextureResolution);
    waves += waterNoise(pos*vec2(5.0, 14.0)/11.0 + frameTimeCounter*vec2(0.0073, 0.0072) * noiseTextureResolution);
    
    return waves / 55.0;
}