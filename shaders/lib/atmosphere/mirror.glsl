vec3 mirrorAtmosphere(vec3 background, vec3 viewVector, vec3 sunVector, vec3 upVector, in int stepAmountI, in int stepAmountJ, in vec3 moonVector) {
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
    bool planetIntersected = calculateRaySphereIntersection(planetRadius, viewVector, viewPosition, planetDistance);

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
		//iOpticalDepthStep += exp(-max(altitude, 0.0) / ozoneHeight) * iStepSize;

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
			//jOpticalDepth += exp(-max(altitude, 0.0) / ozoneHeight) * jStepSize;
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
			//jOpticalDepth += exp(-max(altitude, 0.0) / ozoneHeight) * jStepSize;
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

	return (planetIntersected ? scattering: background * transmittance) + scattering;
}