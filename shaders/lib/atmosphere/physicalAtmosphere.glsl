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

#define mieG 0.95 //[0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045 0.005 0.0055 0.006 0.0065 0.007 0.0075 0.008 0.0085 0.009 0.0095 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05 0.055 0.06 0.065 0.07 0.075 0.08 0.085 0.09 0.095 0.1 0.15 0.2 0.25 0.3 0.035 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0] Controls how directional the scattering is

#define sqaured(x) x*x

#include "jodie_sky.glsl"

// Mie phase function
float phaseFunctionM(float mu) {
	return 1.5 * 1.0 / (4.0 * pi) * (1.0 - sqaured(mieG)) * pow(1.0 + (sqaured(mieG)) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + sqaured(mieG));
}
/*
vec3 physicalAtmosphere(vec3 background, vec3 viewVector, vec3 sunVector, vec3 upVector, in int stepAmountI, in int stepAmountJ, in vec3 moonVector) {
	int iSteps = stepAmountI; // Steps for the primary ray (view point to atmosphere end)
	int jSteps = stepAmountJ;  // Steps for the secondary ray (each primary ray step to atmosphere end)
	int iStepsTimes4 = stepAmountI*4; //Makes sunset/sunrise look incorrect.
	int jStepsTimes4 = stepAmountI*4; //Makes sunset/sunrise look incorrect.

	vec3 sunIlluminance = sunColor; //A thing.
	vec3 moonIlluminance = moonColor / 12.0; //Looks nice.

	//--//

	vec3 viewPosition = upVector * (cameraPosition.y + planetRadius);

    vec2 atmosphereEndDistance;
    bool atmosphereIntersected = calculateRaySphereIntersection(atmosphereRadius, viewVector, viewPosition, atmosphereEndDistance);
    if (!atmosphereIntersected) return background;
    float planetDistance;
    bool planetIntersected = calculateRaySphereIntersection(planetRadius, viewVector, viewPosition, planetDistance);

    float iStepSize  = (planetIntersected ? planetDistance : atmosphereEndDistance.x) / iSteps;
    vec3  iIncrement = viewVector * iStepSize;
	//iIncrement *= dither2;
    vec3  iPosition  = -0.5 * iIncrement + viewPosition;

	float sunVoL   = dot(viewVector, sunVector);
	vec2  sunPhase = vec2(rayleighPhase(sunVoL), phaseM_CS(sunVoL, mieG));

	float moonVoL   = dot(viewVector, moonVector);
	vec2  moonPhase = vec2(rayleighPhase(moonVoL), phaseM_CS(moonVoL, mieG));

	vec3 scattering    = vec3(0.0);
	vec3 transmittance = vec3(1.0);
	for (int i = 0; i < iSteps; i++) {
		iPosition += iIncrement;

		float altitude = length(iPosition) - planetRadius;

		vec2 iOpticalDepthStep = exp(-max(altitude, 0.0) / scaleHeights) * iStepSize;

		{
		float jStepSize  = dot(iPosition, sunVector);
		      jStepSize  = sqrt((jStepSize * jStepSize) + atmosphereRadiusSquared - dot(iPosition, iPosition)) - jStepSize;
		      jStepSize /= jSteps;
		vec3  jIncrement = sunVector * jStepSize;
		vec3  jPosition  = -0.5 * jIncrement + iPosition;

		vec2 jOpticalDepth = vec2(0.0);
		for (int j = 0; j < jSteps; j++) {
			jPosition += jIncrement;

			altitude = length(jPosition) - planetRadius;

			jOpticalDepth += exp(-max(altitude, 0.0) / scaleHeights) * jStepSize;
			if(altitude < 1.0) jOpticalDepth += exp(altitude / scaleHeights) * jStepSize;
		}

		// base scattering of step
		vec3 scatteringStep = (rayleighScatteringCoefficient * iOpticalDepthStep.x * sunPhase.x)
		                    + (     mieScatteringCoefficient * iOpticalDepthStep.y * sunPhase.y);
		// apply atmosphere self-shadowing
		scatteringStep *= exp(-((rayleighTransmittanceCoefficient * jOpticalDepth.x)
		               +        (     mieTransmittanceCoefficient * jOpticalDepth.y)));
		// apply visibility
		scatteringStep *= transmittance;

		// multiply by light source luminance
		scatteringStep *= sunIlluminance * 9e-5; //Not physically based, but keeps the atmosphere from being insanely bright.

		// add to total scattering
		scattering += scatteringStep * transmittance;
		}

		{
		float jStepSize  = dot(iPosition, moonVector);
		      jStepSize  = sqrt((jStepSize * jStepSize) + atmosphereRadiusSquared - dot(iPosition, iPosition)) - jStepSize;
		      jStepSize /= jSteps;
		vec3  jIncrement = moonVector * jStepSize;
		vec3  jPosition  = -0.5 * jIncrement + iPosition;

		vec2 jOpticalDepth = vec2(0.0);
		for (int j = 0; j < jSteps; j++) {
			jPosition += jIncrement;

			altitude = length(jPosition) - planetRadius;

			jOpticalDepth += exp(-max(altitude, 0.0) / scaleHeights) * jStepSize;
		}

		// base scattering of step
		vec3 scatteringStep = (rayleighScatteringCoefficient * iOpticalDepthStep.x * moonPhase.x)
		                    + (     mieScatteringCoefficient * iOpticalDepthStep.y * moonPhase.y);
		// apply atmosphere self-shadowing
		scatteringStep *= exp(-((rayleighTransmittanceCoefficient * jOpticalDepth.x)
		               +        (     mieTransmittanceCoefficient * jOpticalDepth.y)));
		// apply visibility
		scatteringStep *= transmittance;

		// multiply by light source luminance
		scatteringStep *= moonIlluminance;

		// add to total scattering
		scattering += scatteringStep * transmittance;
		}

		transmittance *= exp(-((rayleighTransmittanceCoefficient * iOpticalDepthStep.x)
		              +        (     mieTransmittanceCoefficient * iOpticalDepthStep.y)));
	}

	return (planetIntersected ? vec3(0.0) : background) * transmittance + scattering;
}
*/

float sky_rayleighPhase(float cosTheta) {
	const vec2 mul_add = vec2(0.1, 0.28) / pi;
	return cosTheta * mul_add.x + mul_add.y; // optimized version from [Elek09], divided by 4 pi for energy conservation
}
float sky_miePhase(float cosTheta, const float g) {
	float gg = g * g;
	float p1 = (0.375 * (1.0 - gg)) / (pi * (2.0 + gg));
	float p2 = (cosTheta * cosTheta + 1.0) * pow(-2.0 * g * cosTheta + 1.0 + gg, -1.5);
	return p1 * p2;
}
vec2 sky_phase(float cosTheta, const float g) {
	return vec2(sky_rayleighPhase(cosTheta), sky_miePhase(cosTheta, g));
}

vec2 sky_atmosphereThickness(vec3 position, vec3 direction, float rayLength, const float steps) {
	float stepSize  = rayLength / steps;
	vec3  increment = direction * stepSize;
	position += increment * 0.5;

	vec2 thickness = vec2(0.0);
	for (float i = 0.0; i < steps; i++, position += increment) {
		thickness += exp(length(position) * -sky_inverseScaleHeights + sky_scaledPlanetRadius);
	}

	return thickness * stepSize;
}
vec2 sky_atmosphereThickness(vec3 position, vec3 direction, const float steps) {
	float rayLength = dot(position, direction);
	      rayLength = sqrt(rayLength * rayLength + sky_atmosphereRadiusSquared - dot(position, position)) - rayLength;

	return sky_atmosphereThickness(position, direction, rayLength, steps);
}

vec3 sky_atmosphereOpticalDepth(vec3 position, vec3 direction, float rayLength, const float steps) {
	return sky_coefficientsAttenuation * sky_atmosphereThickness(position, direction, rayLength, steps);
}
vec3 sky_atmosphereOpticalDepth(vec3 position, vec3 direction, const float steps) {
	return sky_coefficientsAttenuation * sky_atmosphereThickness(position, direction, steps);
}

vec3 sky_atmosphereTransmittance(vec3 position, vec3 direction, const float steps) {
	return exp(-sky_atmosphereOpticalDepth(position, direction, steps));
}

vec3 sky_atmosphere(vec3 background, vec3 viewVector, vec3 sunVector, vec3 moonVector, vec3 sunIlluminance, vec3 moonIlluminance) {
	const int iSteps = 16;
	const int jSteps = 3;

	vec3 viewPosition = vec3(0.0, planetRadius + cameraPosition.y, 0.0);

	float iStepSize  = dot(viewPosition, viewVector);
	      iStepSize  = sqrt((iStepSize * iStepSize) + sky_atmosphereRadiusSquared - dot(viewPosition, viewPosition)) - iStepSize;
	      iStepSize /= iSteps;
	      iStepSize *= pow(0.01 * min(dot(viewVector, vec3(0.0, 1.0, 0.0)), 0.0) + 1.0, 900.0); // stop before getting to regions that would have little to no impact on the result
	vec3  iIncrement = viewVector * iStepSize;
	vec3  iPosition  = iIncrement * 0.5 + viewPosition;

	vec2 phase = sky_phase(dot(viewVector, sunVector), sky_mieg);

	vec3 scatteringSun  = vec3(0.0);
	vec3 scatteringMoon = vec3(0.0);
	vec3 transmittance  = vec3(1.0);

	for (int i = 0; i < iSteps; ++i, iPosition += iIncrement) {
		vec2 density = exp(length(iPosition) * -sky_inverseScaleHeights + sky_scaledPlanetRadius);
		if (density.y > 1e35) break;
		vec2 stepAirmass = density * iStepSize;
		vec3 stepOpticalDepth = sky_coefficientsAttenuation * stepAirmass;

		vec3 stepTransmittance = exp(-stepOpticalDepth);
		vec3 stepTransmittedFraction = (stepTransmittance - 1.0) / -stepOpticalDepth;
		vec3 stepTransmittedScattering = (sky_coefficientsScattering * (stepAirmass * phase)) * transmittance * stepTransmittedFraction;

		scatteringSun  += stepTransmittedScattering * sky_atmosphereTransmittance(iPosition, sunVector, jSteps);
		scatteringMoon += stepTransmittedScattering * sky_atmosphereTransmittance(iPosition, moonVector, jSteps);
		transmittance  *= stepTransmittance;
	}

	vec3 scattering = scatteringSun * sunIlluminance + scatteringMoon * moonIlluminance;

	return background * transmittance + scattering;
}

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
	vec3 atmos = sky_atmosphere(vec3(0.0), vec3(0.0), sunVector, moonVector, sunColor * 5e-2, moonColor);

	return atmos;
}