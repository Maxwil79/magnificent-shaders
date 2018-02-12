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

#define mieG 0.95 //[0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045 0.005 0.0055 0.006 0.0065 0.007 0.0075 0.008 0.0085 0.009 0.0095 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05 0.055 0.06 0.065 0.07 0.075 0.08 0.085 0.09 0.095 0.1 0.15 0.2 0.25 0.3 0.035 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define sqaured(x) x*x

#include "jodie_sky.glsl"

// Mie phase function
float phaseFunctionM(float mu) {
	return 1.5 * 1.0 / (4.0 * pi) * (1.0 - sqaured(mieG)) * pow(1.0 + (sqaured(mieG)) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + sqaured(mieG));
}

vec3 physicalAtmosphere(vec3 background, vec3 viewVector, vec3 sunVector, vec3 upVector, in int stepAmountI, in int stepAmountJ, in vec3 moonVector) {
	int iSteps = stepAmountI; // Steps for the primary ray (view point to atmosphere end)
	int jSteps = stepAmountJ;  // Steps for the secondary ray (each primary ray step to atmosphere end)
	int iStepsTimes4 = stepAmountI*4; //Makes sunset/sunrise look incorrect.
	int jStepsTimes4 = stepAmountI*4; //Makes sunset/sunrise look incorrect.

	vec3 sunIlluminance = sunColor; //Physically based.
	vec3 moonIlluminance = moonColor / 25.0; //Looks nice.

	//--//

	vec3 viewPosition = upVector * (cameraPosition.y + planetRadius);

    vec2 atmosphereEndDistance;
    bool atmosphereIntersected = calculateRaySphereIntersection(atmosphereRadius, viewVector, viewPosition, atmosphereEndDistance);
    if (!atmosphereIntersected) return background;
    float planetDistance;
    bool planetIntersected = calculateRaySphereIntersection(planetRadius-700.0, viewVector, viewPosition, planetDistance);

    float iStepSize  = (planetIntersected ? planetDistance : atmosphereEndDistance.x) / iSteps;
    vec3  iIncrement = viewVector * iStepSize;
	iIncrement *= dither2;
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
		scatteringStep *= sunIlluminance * 6e-5; //Not physically based, but keeps the atmosphere from being insanely bright.

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

	return (planetIntersected ? (vec3(9.5, 11.5, 12.5)*scattering)*1.0097 : background * transmittance) + scattering;
}

vec3 atmosphere(vec3 sunVector, vec3 viewVector) {
	vec3 transmittance = vec3(0.0);
	vec3 scattering = vec3(0.0);

	vec3 totalCoeff = rayleighTransmittanceCoefficient + rayleighScatteringCoefficient;

	transmittance = exp(-totalCoeff - viewVector);

	return transmittance + scattering;
}

#define AtmosphereMode 0 //[0 1] 0 = more correct but stops at the planet. 1 = less correct but does not stop at the planet. You can leave the atmosphere if the setting is at 0. This setting affects anything that uses the atmosphere. This includes sunlight, ambient light and reflections.

#include "atmosphereTransmittance.glsl"

vec3 get_atmosphere_transmittance(vec3 sunVector, vec3 upVector, in vec3 moonVector){
	#if AtmosphereMode == 0
	vec3 atmos = atmosphereTransmittance(sunVector, upVector, moonVector);
	#elif AtmosphereMode == 1
	vec3 atmos = js_sunColor();
	#endif

	return atmos;
}

vec3 get_atmosphere(vec3 background, vec3 viewVector, vec3 sunVector, vec3 upVector, in vec3 moonVector){
	#if AtmosphereMode == 0
	vec3 atmos = physicalAtmosphere(background, viewVector, sunVector, upVector, skyQuality_I, skyQuality_J, moonVector);
	#elif AtmosphereMode == 1
	vec3 atmos = js_sunScatter(viewVector);
	#endif

	return atmos;
}

vec3 get_atmosphere_ambient(vec3 background, vec3 viewVector, vec3 sunVector, vec3 upVector, in vec3 moonVector){
	#if AtmosphereMode == 0
	vec3 atmos = physicalAtmosphere(vec3(0.0), vec3(0.0), sunVector, upVector, skyQuality_I, skyQuality_J, moonVector) * 0.075;
	#elif AtmosphereMode == 1
	vec3 atmos = js_sunAmbient(upVector);
	#endif

	return atmos;
}