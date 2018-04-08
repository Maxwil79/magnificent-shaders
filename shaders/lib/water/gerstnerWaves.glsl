vec4 noiseSmooth(vec2 coord) {
    coord = coord * noiseTextureResolution;

	vec2 whole = floor(coord);
	vec2 part  = cubicSmooth(fract(coord));

	coord = (whole + part - 0.5) * noiseResInverse;

	return texture2D(noisetex, coord);
}

float gernsterWaves(vec2 coord, float time, float waveSteepness, float waveAmplitude, float waveLength, vec2 waveDirection){
    const float g = 9.81;

    float k = tau / waveLength;
    float w = sqrt(g * k);

    float x = w * time - k * dot(waveDirection, coord);
    float wave = sin(x) * 0.5 + 0.5;

    float h = waveAmplitude * pow(wave, waveSteepness);

    return h;
}

#define Speed 0.6 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] Changes the speed of the waves.

float calculateWaveHeight(vec2 coord, in float y, in float x, in float size, in float amp, in float steepness, int octaveCount) {
    const int octaves   = octaveCount;

    float movement      = frameTimeCounter * Speed;

    float waveSteepness = steepness;
    float waveAmplitude = amp;
    float waveLength    = size;
    vec2  waveDirection = vec2(rand(vec2(x, y)));

    float waves = 0.0;

    const float f = tau / (4.618);
    float a = cos(f);
    float b = sin(f);

    for (int i = 0; i < octaves; i++) {
        vec2 noise     = vec2(waterNoise(coord.xy * 0.15 + i / octaves));
        waves         += -gernsterWaves(coord + 0.3 * (noise * 2.0 - 1.0) * sqrt(waveLength), movement, waveSteepness, waveAmplitude, waveLength, waveDirection);
        waveSteepness *= 1.2;
        waveAmplitude *= 0.55;
        waveDirection *= 1.5;
        waveLength    *= 0.75;
        waveDirection  = rotateNoMat(vec2((waveDirection)), a, b);
    }

    return waves;
}