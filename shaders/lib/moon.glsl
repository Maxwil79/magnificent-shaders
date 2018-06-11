vec3 calculateMoon(
	in vec3 moonVector,
	in vec3 viewVector
) {
    float VdotL = dot(viewVector, moonVector);
    float moonAngularSize = 0.545;
    float moonRadius = radians(moonAngularSize) / 2.0;
    float cosMoonRadius = cos(moonRadius);
    vec3 moonLuminance = moonColor*4.0;
    vec3 moon = fstep(cosMoonRadius, VdotL) * moonLuminance;
    return moon;
}