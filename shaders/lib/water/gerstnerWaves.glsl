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
    const float g = 9.81;

    float k = tau / waveLength;
    float w = sqrt(g * k);

    float x = w * time - k * dot(waveDirection, coord);
    float wave = sin(x) * 0.5 + 0.5;

    float h = waveAmplitude * pow(wave, waveSteepness);

    return h;
}

#define Speed 0.6 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] Changes the speed of the waves.

float calculateWaveHeight(vec2 coord) {
    const int octaves   = Octaves;

    float movement      = frameTimeCounter * Speed;

    float waveSteepness = WaveSteepness;
    float waveAmplitude = WaveAmplitude;
    float waveLength    = WaveLength;
    vec2  waveDirection = vec2(WaveDirectionX, WaveDirectionY);

    float waves = 0.0;

    const float f = tau / (2.618);
    float a = cos(f);
    float b = sin(f);

    for (int i = 0; i < octaves; i++) {
        vec2 noise     = noiseSmooth(coord.xy * 0.15 + i / octaves).xy;
        waves         += -gernsterWaves(coord + 0.3 * (noise * 2.0 - 1.0) * sqrt(waveLength), movement, waveSteepness, waveAmplitude, waveLength, waveDirection);
        waveSteepness *= 0.8;
        waveAmplitude *= 0.6;
        waveLength    *= 0.7;
        waveDirection  = rotateNoMat(waveDirection, a, b);
        //coord  = rotateNoMat(coord + waveDirection, a, b);
        a      += pi - 3.23333;
    }

    return waves;
}