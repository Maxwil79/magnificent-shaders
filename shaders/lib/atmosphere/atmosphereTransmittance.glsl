vec3 atmosphereTransmittance(vec3 rayVector, vec3 upVector) {
    const int steps = skyQuality_I;

    vec3 startPos = upVector * (cameraPosition.y + planetRadius);
    float stepSize  = dot(startPos, sunVector);
          stepSize  = sqrt((stepSize * stepSize) + atmosphereRadiusSquared - dot(startPos, startPos)) - stepSize;
          stepSize /= steps;
    vec3  increment = sunVector * stepSize;
    vec3  position  = -0.5 * increment + startPos;

    vec2 opticalDepth = vec2(0.0);
    for (int i = 0; i < steps; i++) {
        position += increment;

        float altitude = length(position) - planetRadius;

        opticalDepth -= exp(-altitude / scaleHeights);
    }
    opticalDepth *= stepSize;
    return exp(rayleighTransmittanceCoefficient * opticalDepth.x + mieTransmittanceCoefficient * opticalDepth.y);
}