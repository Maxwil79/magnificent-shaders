vec3 atmosphereTransmittance(vec3 sunVector, vec3 upVector, vec3 moonVector) {
	const int steps = skyQuality_I;

	vec3 startPos = upVector * (cameraPosition.y + planetRadius);
	float stepSize  = dot(startPos, sunVector);
	      stepSize  = sqrt((stepSize * stepSize) + atmosphereRadiusSquared - dot(startPos, startPos)) - stepSize;
	      stepSize /= steps;
	vec3  increment = sunVector * stepSize;
	vec3  position  = -0.5 * increment + startPos;

	float stepSize2  = dot(startPos, moonVector);
	      stepSize2  = sqrt((stepSize2 * stepSize2) + atmosphereRadiusSquared - dot(startPos, startPos)) - stepSize2;
	      stepSize2 /= steps;
	vec3  increment2 = moonVector * stepSize2;
	vec3  position2  = -0.5 * increment2 + startPos;

	vec2 opticalDepth = vec2(0.0);
	vec2 opticalDepth2 = vec2(0.0);
	for (int i = 0; i < steps; i++) {
	    position += increment;

	    float altitude = length(position) - planetRadius;

	    opticalDepth -= exp(-altitude / scaleHeights);

	    position2 += increment2;

	    float altitude2 = length(position2) - planetRadius;

	    opticalDepth2 -= exp(-altitude2 / scaleHeights);
	}
	opticalDepth *= stepSize;
	vec3 transmittance = exp(rayleighTransmittanceCoefficient * opticalDepth.x + mieTransmittanceCoefficient * opticalDepth.y) * sunColor * 6e-5;
	vec3 transmittance2 = exp(rayleighTransmittanceCoefficient * opticalDepth2.x + mieTransmittanceCoefficient * opticalDepth2.y) * moonColor / 15.0;
	return transmittance + transmittance2;
}