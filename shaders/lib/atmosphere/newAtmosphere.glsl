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
	const int iSteps = 32;
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