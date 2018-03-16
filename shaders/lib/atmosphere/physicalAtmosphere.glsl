vec3 upVector = gbufferModelView[1].xyz;

#include "constants.glsl"

float miePhase(float cosTheta, float g) {
	float gg = g * g;

	float p1 = (3.0 * (1.0 - gg)) / (2.0 * (2.0 + gg));
	return p1 * (cosTheta * cosTheta + 1.0) / pow(1.0 + gg - 2.0 * g * cosTheta, 1.5);
}

float rayleighPhase(float cosTheta) {
	return 0.375 * (cosTheta * cosTheta + 1.0);
}

float ozoneHeight = 3e4;

#define rayleighDistribution 8. // physically based 
#define mieDistribution 1.8 // physically based 

const float kPi = 3.14159265359;
const float kOneOver4Pi = 1.0 / (4.0 * kPi);

float Sqrt(float x)
{
    return sqrt(max(0.0, x));
}

float phaseR(float VoL)
{
    return kOneOver4Pi * 0.75 * (1.0 + VoL * VoL);
}

float phaseM_HG(float VoL, float G)
{
    float A = max(0.0, 1.0 + G * (G - 2.0 * VoL));
    float D = 1.0 / Sqrt(A * A * A);
    return (1.0 - G * G) * kOneOver4Pi * D;
}

float phaseM_CS(float VoL, float G)
{
    return 1.5 * (1.0 + VoL * VoL) * phaseM_HG(VoL, G) / (2.0 + G * G);
}

#define sqaured(x) x*x

#include "jodie_sky.glsl"

// Mie phase function
float phaseFunctionM(float mu) {
	return 1.5 * 1.0 / (4.0 * pi) * (1.0 - sqaured(mieG)) * pow(1.0 + (sqaured(mieG)) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + sqaured(mieG));
}

#include "newAtmosphere.glsl"

#include "atmosphereTransmittance.glsl"

vec3 get_atmosphere_transmittance(vec3 sunVector, vec3 upVector, vec3 moonVector){
	vec3 atmos = mix(moonColor, sunColor * 12e-3, float(sunAngle < 0.5)) * atmosphereTransmittance(mix(moonVector, sunVector, float(sunAngle < 0.5)), upVector);

	return atmos;
}

vec3 get_atmosphere(vec3 background, vec3 viewVector, vec3 sunVector, vec3 moonVector){
	vec3 atmos = sky_atmosphere(background, viewVector, sunVector, moonVector, sunColor * 1e-1, moonColor);

	return atmos;
}

vec3 get_atmosphere_ambient(vec3 background, vec3 viewVector, vec3 sunVector, in vec3 moonVector){
	vec3 atmos = sky_atmosphere(vec3(0.0), vec3(0.0), sunVector, moonVector, sunColor * 5e-2, moonColor) * vec3(0.5, 0.7, 0.95);

	return atmos;
}