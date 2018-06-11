#define SunSize 0.5 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]

vec3 calculateSun(
	in vec3 sunVector,
	in vec3 viewVector,
    in vec3 scatterCol,
    in float size
) {
    float VdotL = dot(viewVector, sunVector);
    float sunAngularSize = size;
    float sunRadius = radians(sunAngularSize) / 2.0;
    float cosSunRadius = cos(sunRadius);
    float sunLuminance = sunIlluminance * 0.05;
    vec3 sun = fstep(cosSunRadius, VdotL) * sunLuminance * sunColor;
    return sun;
}