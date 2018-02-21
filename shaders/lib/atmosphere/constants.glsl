const float planetRadius     = 6731e3;
const float atmosphereHeight = 200e3;

const float sunIlluminanceValue = 1.14e4;

#define SunTemperature 5550 //[3000 3100 3150 3200 3250 3300 3350 3400 3450 3500 3550 3600 3650 3700 3750 3800 3850 3900 3950 4000 4100 4150 4200 4250 4300 4350 4400 4450 4500 4550 4600 4650 4700 4750 4800 4850 4900 4950 5000 5100 5150 5200 5250 5300 5350 5400 5450 5500 5550 5600 5650 5700 5750 5800 5850 5900 5950 6000 6100 6150 6200 6250 6300 6350 6400 6450 6500 6550 6600 6650 6700 6750 6800 6850 6900 6950 7000 7100 7150 7200 7250 7300 7350 7400 7450 7500 7550 7600 7650 7700 7750 7800 7850 7900 7950] A lower value gives a more red result, and a higher value gives a more blue result.

const vec3 sunColor  = blackbody(SunTemperature) * sunIlluminanceValue;
const vec3 moonColor = sunColor * 45e-8;

const vec3 rayleighScatteringCoefficient = vec3(3.8e-6  , 1.35e-5 , 3.31e-5 );
const vec3      mieScatteringCoefficient = vec3(2.1e-5); //Good default
const vec3 ozoneCoeff    = (vec3(8.426, 8.298, .356) * 6e-5 / 100.);
const float ozoneMult = 1.;

const vec3 rayleighTransmittanceCoefficient = rayleighScatteringCoefficient + ozoneCoeff * ozoneMult;
const vec3      mieTransmittanceCoefficient =      mieScatteringCoefficient * 1.11;

const float rayleighScaleHeight = 6.0e3; //Not accurate, done to fix sunrise and sunset.
const float      mieScaleHeight = 1.8e3;
const vec2 scaleHeights = vec2(rayleighScaleHeight, mieScaleHeight);

const float atmosphereRadius = planetRadius + atmosphereHeight;
const float atmosphereRadiusSquared = atmosphereRadius * atmosphereRadius;

#define skyQuality_I 8 //[4 8 16 32 64 128] Controls the quality of the atmosphere. Higher means a slower, but more realistic lookin' sky. Change the J steps after you change this.
#define skyQuality_J 3 //[3 6 12 24 48 96] Controls the quality of the atmosphere. Higher means a slower, but more realistic lookin' sky. Only change if you have changed the I steps.