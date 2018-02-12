const float planetRadius     = 6731e3;
const float atmosphereHeight = 200e3;

const float sunIlluminanceValue = 1.14e4;

const vec3 sunColor  = blackbody(5778.0) * sunIlluminanceValue;
const vec3 moonColor = sunColor * 15e-11;

const vec3 rayleighScatteringCoefficient = vec3(5.8e-6  , 1.35e-5 , 3.31e-5 );
const vec3      mieScatteringCoefficient = vec3(2.1e-5); //Good default
const vec3 ozoneCoeff    = (vec3(6.426, 8.298, .356) * 6e-5 / 100.);
const float ozoneMult = 1.;

const vec3 rayleighTransmittanceCoefficient = rayleighScatteringCoefficient + ozoneCoeff * ozoneMult;
const vec3      mieTransmittanceCoefficient =      mieScatteringCoefficient * 1.11;

const float rayleighScaleHeight = 3.2e3; //Not accurate, done to fix sunrise and sunset.
const float      mieScaleHeight = 1.8e3;
const vec2 scaleHeights = vec2(rayleighScaleHeight, mieScaleHeight);

const float atmosphereRadius = planetRadius + atmosphereHeight;
const float atmosphereRadiusSquared = atmosphereRadius * atmosphereRadius;

#define skyQuality_I 8 //[4 8 16 32 64 128] Controls the quality of the atmosphere. Higher means a slower, but more realistic lookin' sky. Change the J steps after you change this.
#define skyQuality_J 3 //[3 6 12 24 48 96] Controls the quality of the atmosphere. Higher means a slower, but more realistic lookin' sky. Only change if you have changed the I steps.