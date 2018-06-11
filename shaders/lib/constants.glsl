float sunIlluminance = 5e2;
float moonIlluminance = sunIlluminance * 8e-5; //Not really physically based.

vec3 sunColor = sunIlluminance * blackbody(5778);
vec3 moonColor = moonIlluminance * blackbody(5778);

const float planetRadius     = 6731e3;
const float atmosphereHeight = 100e3;
const float atmosphereRadius = planetRadius + atmosphereHeight;

const float planetRadiusSquared = planetRadius*planetRadius;
const float atmosphereRadiusSquared = atmosphereRadius*atmosphereRadius;

#define SkySteps 12 //[1 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64]

const int stepCountI = SkySteps;
const int stepCount = 3;

const float scaleHeightRlh = 8.0e3;
const float scaleHeightMie = 1.8e3;
const float scaleHeightOzo = 38e3;

//I need to make ozone absorption more accurate, it is fine for now though.

const vec3 rlhCoeff = vec3(5.8000e-6, 1.3500e-5, 3.3100e-5);
const vec3 mieCoeff = vec3(8.6000e-6, 8.6000e-6, 8.6000e-6);
const vec3 ozoCoeff = (vec3(8.426, 8.298, .356) * 6e-5 / 370.);

const vec3 rlhCoeffSctr = rlhCoeff;
const vec3 mieCoeffSctr = mieCoeff * 1.11;

float mieG = 0.77;
float mieG2 = 0.785;