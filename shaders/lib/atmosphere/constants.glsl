const float planetRadius     = 6731e3;
const float atmosphereHeight = 100e3;

const float sunIlluminanceValue = 1e2;

#define SunTemperature 5550 //[3000 3100 3150 3200 3250 3300 3350 3400 3450 3500 3550 3600 3650 3700 3750 3800 3850 3900 3950 4000 4100 4150 4200 4250 4300 4350 4400 4450 4500 4550 4600 4650 4700 4750 4800 4850 4900 4950 5000 5100 5150 5200 5250 5300 5350 5400 5450 5500 5550 5600 5650 5700 5750 5800 5850 5900 5950 6000 6100 6150 6200 6250 6300 6350 6400 6450 6500 6550 6600 6650 6700 6750 6800 6850 6900 6950 7000 7100 7150 7200 7250 7300 7350 7400 7450 7500 7550 7600 7650 7700 7750 7800 7850 7900 7950] A lower value gives a more red result, and a higher value gives a more blue result.

#define cloudCoeffScatter    0.02
#define cloudCoeffTransmit   cloudCoeffScatter * 1.11

const vec2  sky_scaleHeights     = vec2(8.0e3, 1.2e3);
const float sky_atmosphereHeight = 100e3;

#define mieG 0.95 //[0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045 0.005 0.0055 0.006 0.0065 0.007 0.0075 0.008 0.0085 0.009 0.0095 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05 0.055 0.06 0.065 0.07 0.075 0.08 0.085 0.09 0.095 0.1 0.15 0.2 0.25 0.3 0.035 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Controls how directional the scattering is

const float sky_mieg = mieG;

// TODO: Calculate these coefficients myself so I can make sure they're consistent with what they should be. Until I do that I'll just use ones I've found that look good.
const vec3 sky_coefficientRayleigh = vec3(5.8000e-6, 1.3500e-5, 3.3100e-5);
const vec3 sky_coefficientOzone    = vec3(2.0550e-6, 4.9788e-6, 0.2136e-6);
const vec3 sky_coefficientMie      = vec3(8.6000e-6, 8.6000e-6, 8.6000e-6); // Should be >= 2e-6, depends heavily on conditions. Current value just one that looks good.

//--// Calculated from the above
const vec2  sky_inverseScaleHeights     = 1.0 / sky_scaleHeights;
const vec2  sky_scaledPlanetRadius      = planetRadius * sky_inverseScaleHeights;
const float sky_atmosphereRadius        = planetRadius + sky_atmosphereHeight;
const float sky_atmosphereRadiusSquared = sky_atmosphereRadius * sky_atmosphereRadius;

const mat2x3 sky_coefficientsScattering  = mat2x3(sky_coefficientRayleigh, sky_coefficientMie);
const mat2x3 sky_coefficientsAttenuation = mat2x3(sky_coefficientRayleigh + sky_coefficientOzone, sky_coefficientMie * 1.11); // commonly called the extinction coefficient

const vec3 sunColor  = blackbody(SunTemperature) * sunIlluminanceValue;
const vec3 moonColor = sunColor * 4e-6;

const vec3 rayleighScatteringCoefficient = vec3(4.593e-6, 1.097e-5, 2.716e-5);
const vec3      mieScatteringCoefficient = vec3(2.5e-5); //Good default
const vec3 ozoneCoeff    = vec3(3.426e-7, 8.298e-7, 0.356e-7) * 6.0;

const vec3 rayleighTransmittanceCoefficient = rayleighScatteringCoefficient + ozoneCoeff;
const vec3      mieTransmittanceCoefficient =      mieScatteringCoefficient * 1.11;

const float rayleighScaleHeight = 8.0e3;
const float      mieScaleHeight = 1.2e3;
const vec2 scaleHeights = vec2(rayleighScaleHeight, mieScaleHeight);

const float atmosphereRadius = planetRadius + atmosphereHeight;
const float atmosphereRadiusSquared = atmosphereRadius * atmosphereRadius;

#define skyQuality_I 12 //[4 8 12 16 32 64 128] Controls the quality of the atmosphere. Higher means a slower, but more realistic lookin' sky. Change the J steps after you change this. Only used by the atmosphere transmittance function right now.
#define skyQuality_J 3 //[3 6 8 12 24 48 96] Controls the quality of the atmosphere. Higher means a slower, but more realistic lookin' sky. Only change if you have changed the I steps.

const float vl_Height = 8.4e1;