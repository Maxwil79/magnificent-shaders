vec3 calculateMoon(
	in vec3 moonVector,
	in vec3 viewVector
) {
	const float moonRadius = 437e3;
	const float moonSmAxis = 384399e2; // Semi-major axis

	vec3 viewPosition = vec3(0.0);//vec3(0.0, 0.0, viewHeight);

	if(calculateRaySphereIntersection(moonVector * moonSmAxis, moonRadius, viewVector, viewPosition)) {
		return moonColor;
	}

	return vec3(0.0);
}