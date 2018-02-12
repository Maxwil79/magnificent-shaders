//From Wisdom
#define SeaHeight 0.065 // [0.065 0.1 0.21 0.32 0.43 0.54 0.65] Hieght of the waves.
#define SeaFreq 0.15 //How frequent the waves are. [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SeaSpeed 1.2 //Speed of the waves. [1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SeaChoppy 0.05 //How choppy the water is. [0.025 0.05 0.075 0.25 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

//#define NaturalWaveGenerator //Increases the quality of the ocean waves at the cost of performance.

#ifdef NaturalWaveGenerator
const int ITER_GEOMETRY = 4;
const int ITER_GEOMETRY2 = 4;
#else
const int ITER_GEOMETRY = 2;
const int ITER_GEOMETRY2 = 3;
#endif
const float SEA_CHOPPY = SeaChoppy;
const float SEA_SPEED = SeaSpeed;
const float SEA_FREQ = SeaFreq;
const mat2 octave_m = mat2(1.4,1.1,-2.2,1.4);

float sea_octave_micro(vec2 uv, float choppy) {
    uv += noise4(uv);
    vec2 wv = 1.0-abs(sin(uv));
    vec2 swv = abs(cos(uv));
    wv = mix(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.75),choppy);
}

const float height_mul[5] = float[5] (
    0.52, 0.34, 0.20, 0.22, 0.16
);
const float total_height =
  height_mul[0] + height_mul[1] + height_mul[2] + height_mul[3] + height_mul[4];
const float rcp_total_height = 1.0 / total_height;

float getwave(vec2 p) {
    float freq = SEA_FREQ;
    float amp = SeaHeight;
    float choppy = SEA_CHOPPY;
    vec2 uv = p; uv.x *= 0.75;

    float wave_speed = frameTimeCounter * SEA_SPEED;

    float d, h = 0.0;
    for(int i = 0; i < ITER_GEOMETRY; i++) {
        d = sea_octave_micro((uv+wave_speed)*freq,choppy);
        h += d * amp;
        uv *= octave_m; freq *= 1.9; amp *= height_mul[i]; wave_speed *= -1.3;
        choppy = mix(choppy,1.0,0.2);
    }

    return (h * rcp_total_height - SeaHeight);
}

float getwave2(vec2 p) {
    float freq = SEA_FREQ;
    float amp = SeaHeight;
    float choppy = SEA_CHOPPY;
    vec2 uv = p ; uv.x *= 0.75;

    float wave_speed = frameTimeCounter * SEA_SPEED;

    float d, h = 0.0;
    for(int i = 0; i < ITER_GEOMETRY2; i++) {
        d = sea_octave_micro((uv+wave_speed)*freq,choppy);
        h += d * amp;
        uv *= octave_m; freq *= 1.9; amp *= height_mul[i]; wave_speed *= -1.3;
        choppy = mix(choppy,1.0,0.2);
    }

    return (h * rcp_total_height - SeaHeight);
}