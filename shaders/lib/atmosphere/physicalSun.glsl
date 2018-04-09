#define SunSize 0.5 //[0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95] Controls the radius of the sun. 0.5 is the same radius the sun is when viewed from the earth.

vec3 calculateSun(
	in vec3 sunVector,
	in vec3 viewVector
) {
	float radius = radians(SunSize);
	float sunAngularSize = degrees(radius);
	return step(pi - radius, acos(-dot(sunVector, viewVector))) * sunColor;
}