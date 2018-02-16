vec2 rotateNoMat(vec2 coord, float a, float b) {
    float ns = b * coord.y + a * coord.x;
    float nc = a * coord.y - b * coord.x;
    return vec2(ns, nc);
}

vec4 noiseSmooth(vec2 coord) {
    coord = coord * noiseTextureResolution;

	vec2 whole = floor(coord);
	vec2 part  = cubicSmooth(fract(coord));

	coord = (whole + part - 0.5) * noiseResInverse;

	return texture2D(noisetex, coord);
}

float gernsterWaves(vec2 coord, float time, float waveSteepness, float waveAmplitude, float waveLength, vec2 waveDirection){
	const float g = 19.6;
    
	float k = tau / waveLength;
	float w = sqrt(g * k);

	float x = w * time - k * dot(waveDirection, coord);
	float wave = sin(x) * 0.5 + 0.5;

	float h = waveAmplitude * pow(wave, waveSteepness);

	return h;
}

float calculateWaveHeight(vec2 coord) {
    const int octaves   = Octaves;

    float movement      = frameTimeCounter * 0.3;

    float waveSteepness = WaveSteepness;
    float waveAmplitude = WaveAmplitude;
    float waveLength    = WaveLength;
    vec2  waveDirection = vec2(WaveDirectionX, WaveDirectionY);

    float waves = 0.0;

    const float f = tau * 0.9;
    const float a = cos(f);
    const float b = sin(f);

    for (int i = 0; i < octaves; i++) {
        vec2 noise     = noiseSmooth(coord * 0.005 / sqrt(waveLength)).xy;
        waves         += -gernsterWaves(coord + (noise * 2.0 - 1.0) * sqrt(waveLength), movement, waveSteepness, waveAmplitude * noise.x, waveLength, waveDirection) - noise.y * waveAmplitude;
        waveSteepness *= 1.1;
        waveAmplitude *= 0.6;
        waveLength    *= 0.8;
        waveDirection  = rotateNoMat(waveDirection, a, b);
    }

    return waves;
}