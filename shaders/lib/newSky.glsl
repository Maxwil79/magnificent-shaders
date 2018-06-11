#define PI 3.1415926

#include "constants.glsl"

vec3 atmosphereTransmittance(vec3 rayVector, vec3 upVector) {
    const int steps = 10;

    vec3 startPos = upVector * (cameraPosition.y + planetRadius);
    float stepSize  = dot(startPos, rayVector);
          stepSize  = sqrt((stepSize * stepSize) + atmosphereRadiusSquared - dot(startPos, startPos)) - stepSize;
          stepSize /= steps;
    vec3  increment = rayVector * stepSize;
    vec3  position  = -0.5 * increment + startPos;

    vec3 opticalDepth = vec3(0.0);
    for (int i = 0; i < steps; ++i) {
        position += increment;

        float altitude = length(position) - planetRadius;

        opticalDepth -= exp(-altitude / vec3(scaleHeightRlh, scaleHeightMie, scaleHeightOzo));
    }
    opticalDepth *= stepSize;

    vec3 result = exp(rlhCoeff * opticalDepth.x + mieCoeffSctr * opticalDepth.y + ozoCoeff * opticalDepth.z) / 12.0;
    return result;
}

float rayleighPhase(float cosTheta) {
	const vec2 mul_add = vec2(0.1, 0.28) / pi;
	return cosTheta * mul_add.x + mul_add.y; // optimized version from [Elek09], divided by 4 pi for energy conservation
}

float miePhase(float cosTheta, const float g) {
	float gg = g * g;
	float p1 = (0.375 * (1.0 - gg)) / (pi * (2.0 + gg));
	float p2 = (cosTheta * cosTheta + 1.0) * pow(-2.0 * g * cosTheta + 1.0 + gg, -1.5);
	return p1 * p2;
}

const float kOneOver4Pi = 1.0 / (4.0 * PI);

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

vec2 phaseFunction(float cosTheta, in float cosThetaSquared) 
{ 
    return vec2(rayleighPhase(cosTheta), miePhase(cosTheta, mieG));
}

/* Code below is From Zombye's Shader */

const vec3  sky_inverseScaleHeights     = 1.0 / vec3(scaleHeightRlh, scaleHeightMie, scaleHeightOzo);
const vec3  sky_scaledPlanetRadius      = planetRadius * sky_inverseScaleHeights;

const mat3x3 sky_coefficientsAttenuation = mat3x3(rlhCoeff, mieCoeff * 1.11, ozoCoeff);

vec3 sky_atmosphereThickness(vec3 position, vec3 direction, float rayLength, const float steps) {
    float stepSize  = rayLength / steps;
    vec3  increment = direction * stepSize;
    position += increment * 0.5;

    vec3 thickness = vec3(0.0);
    for (float i = 0.0; i < steps; ++i, position += increment) {
        float len= length(position);
        thickness.xy += exp(len * -sky_inverseScaleHeights.xy + sky_scaledPlanetRadius.xy);
        thickness.z  += exp((abs(len - planetRadius - 38e3) + planetRadius) * -sky_inverseScaleHeights.z + sky_scaledPlanetRadius.z);
    }

    return thickness * stepSize;
}

vec3 sky_atmosphereThickness(vec3 position, vec3 direction, const float steps) {
	float rayLength = dot(position, direction);
	      rayLength = sqrt(rayLength * rayLength + atmosphereRadiusSquared - dot(position, position)) - rayLength;

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
/* Code Above Is From Zombye's Shader*/

//I need to make ozone absorption more accurate, it is fine for now though.

vec3 atmos(in vec3 viewVector, out vec3 scatterCol, in vec3 background, in int stepCount1) {
    //Raysphere intersection to figure out how far to march.
    float PtimesD = (planetRadius + cameraPosition.y) * viewVector.y;
    float atmosphereEndDist = sqrt(PtimesD*PtimesD + atmosphereRadiusSquared - planetRadiusSquared) - PtimesD;

    //Position
    vec3 position = vec3(0.0, planetRadius + cameraPosition.y, 0.0);

    //Calculate the increment and step size
    vec3 increment = viewVector * atmosphereEndDist / stepCountI;
    if(PtimesD < atmosphereEndDist - 128.0e4) increment *= pow(0.01 * min(dot(viewVector, mat3(gbufferModelViewInverse) * upVector), 0.0) + 1.0, 500.0);

    float stepSize = length(increment);

    //Needed for the loop
    vec3 transmittance = vec3(1.0);
    vec3 scatteredSun = vec3(0.0);
    vec3 scatteredMoon = vec3(0.0);

    //Mie and Rayleigh Phase.
    float cosThetaS = dot(viewVector, sunVector);
    float cosThetaSquaredS = cosThetaS*cosThetaS;

    float cosThetaM = dot(viewVector, moonVector);
    float cosThetaSquaredM = cosThetaM*cosThetaM;

    vec2 phaseSun = phaseFunction(cosThetaS, cosThetaSquaredS);
    vec2 phaseMoon = phaseFunction(cosThetaM, cosThetaSquaredM);

    //Fix some issues
    position -= increment*0.5;

    //Loop
    for(int i = 0; i < stepCount1; ++i) {
        position += increment;
        float height = length(position) - planetRadius;

        float densityRlh = exp(-max(height, 0.0) / scaleHeightRlh) * stepSize;
        float densityMie = exp(-max(height, 0.0) / scaleHeightMie) * stepSize;
        float densityOzo = exp(-max(height, 0.0) / scaleHeightOzo) * stepSize;

        vec3 opticalDepth = (densityRlh * rlhCoeff) + (densityMie * mieCoeffSctr) + (densityOzo * ozoCoeff);

        vec3 transmittanceStep = exp(-opticalDepth);
        vec3 stepTransmittedFraction = (transmittanceStep - 1.0) / -opticalDepth;

        vec3 scatteringViewStepS = (rlhCoeffSctr * densityRlh * phaseSun.x + mieCoeffSctr * densityMie * phaseSun.y) * stepTransmittedFraction * transmittance;
        vec3 scatteringViewStepM = (rlhCoeffSctr * densityRlh * phaseMoon.x + mieCoeffSctr * densityMie * phaseMoon.y) * stepTransmittedFraction * transmittance;

        scatteredSun += scatteringViewStepS * sky_atmosphereTransmittance(position, sunVector, stepCount);
        scatteredMoon += scatteringViewStepM * sky_atmosphereTransmittance(position, moonVector, stepCount);

        transmittance *= transmittanceStep;
    }
    vec3 scattered = scatteredSun * sunColor + scatteredMoon * moonColor;

    scatterCol = scattered;

    return background * transmittance + (scattered);
}

//Should probably just use the actual atmosphere function.

vec3 atmosAmbient(in vec3 viewVector) {
    //Raysphere intersection to figure out how far to march.
    float PtimesD = (planetRadius + cameraPosition.y) * viewVector.y;
    float atmosphereEndDist = sqrt(PtimesD*PtimesD + atmosphereRadiusSquared - planetRadiusSquared) - PtimesD;

    //Position
    vec3 position = vec3(0.0, planetRadius + cameraPosition.y, 0.0);

    //Calculate the increment and step size
    vec3 increment = viewVector * atmosphereEndDist / stepCountAMB;

    float stepSize = length(increment);

    //Needed for the loop
    vec3 transmittance = vec3(1.0);
    vec3 scatteredSun = vec3(0.0);
    vec3 scatteredMoon = vec3(0.0);

    //Mie and Rayleigh Phase.
    float cosThetaS = dot(viewVector, sunVector);
    float cosThetaSquaredS = cosThetaS*cosThetaS;

    float cosThetaM = dot(viewVector, moonVector);
    float cosThetaSquaredM = cosThetaM*cosThetaM;

    vec2 phaseSun = phaseFunction(cosThetaS, cosThetaSquaredS);
    vec2 phaseMoon = phaseFunction(cosThetaM, cosThetaSquaredM);

    //Fix some issues
    position -= increment*0.5;

    //Loop
    for(int i = 0; i < stepCountAMB; ++i) {
        position += increment;
        float height = length(position) - planetRadius;

        float densityRlh = exp(-max(height, 0.0) / scaleHeightRlh) * stepSize;
        float densityOzo = exp(-max(height, 0.0) / scaleHeightOzo) * stepSize;

        vec3 opticalDepth = (densityRlh * rlhCoeff) + (densityOzo * ozoCoeff);

        vec3 transmittanceStep = exp(-opticalDepth);
        vec3 stepTransmittedFraction = (transmittanceStep - 1.0) / -opticalDepth;

        vec3 scatteringViewStepS = (rlhCoeffSctr * densityRlh * phaseSun.x) * stepTransmittedFraction * transmittance;
        vec3 scatteringViewStepM = (rlhCoeffSctr * densityRlh * phaseMoon.x) * stepTransmittedFraction * transmittance;

        scatteredSun += scatteringViewStepS * sky_atmosphereTransmittance(position, sunVector, 4);
        scatteredMoon += scatteringViewStepM * sky_atmosphereTransmittance(position, moonVector, 4);

        transmittance *= transmittanceStep;
    }
    vec3 scattered = scatteredSun * sunColor + scatteredMoon * moonColor;

    return scattered;
}

vec3 get_sunlightColor() {
    return mix(moonIlluminance * blackbody(5778), sunIlluminance * blackbody(5778), float(sunAngle < 0.5)) * atmosphereTransmittance(mix(moonVector, sunVector, float(sunAngle < 0.5)), mat3(gbufferModelViewInverse) * upVector);
}
