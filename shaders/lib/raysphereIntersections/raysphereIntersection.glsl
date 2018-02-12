// Only check for intersection
bool calculateRaySphereIntersection(
	in float sphereRadius, // Radius of the sphere
	in vec3  rayVector, // Vector of the ray (where it is pointed)
	in vec3  rayOrigin  // Origin of the ray (starting point)
) {
	float rDot  = dot(rayVector, rayOrigin);
	float roLen = length(rayOrigin);

	// Prevent intersecting a second sphere in the opposite direction
	if(rDot > 0.0 && roLen > sphereRadius) return false;

	float delta = square(rDot) - square(roLen) + square(sphereRadius);

	if(delta < 0.0) return false;

	return true;
}
bool calculateRaySphereIntersection(
	in vec3  sphereOrigin, // Center of the sphere
	in float sphereRadius, // Radius of the sphere
	in vec3  rayVector, // Vector of the ray (where it is pointed)
	in vec3  rayOrigin // Origin of the ray (starting point)
) {
	rayOrigin -= sphereOrigin; // Coordinates relative to sphere

	return calculateRaySphereIntersection(
		sphereRadius,
		rayVector,
		rayOrigin
	);
}

// Distance from first intersection only
bool calculateRaySphereIntersection(
	in float sphereRadius, // Radius of the sphere
	in vec3  rayVector, // Vector of the ray (where it is pointed)
	in vec3  rayOrigin, // Origin of the ray (starting point)

	out float iDistance
) {
	float rDot  = dot(rayVector, rayOrigin);
	float roLen = length(rayOrigin);

	// Prevent intersecting a second sphere in the opposite direction
	if(rDot > 0.0 && roLen > sphereRadius) return false;

	float delta = square(rDot) - square(roLen) + square(sphereRadius);

	if(delta < 0.0) return false;

	vec2 dist = vec2(-rDot + sqrt(delta), -rDot - sqrt(delta));

	iDistance = min(dist.x, dist.y);

	if(iDistance <= 0.0) iDistance = max(dist.x, dist.y);

	return true;
}
bool calculateRaySphereIntersection(
	in vec3  sphereOrigin, // Center of the sphere
	in float sphereRadius, // Radius of the sphere
	in vec3  rayVector, // Vector of the ray (where it is pointed)
	in vec3  rayOrigin, // Origin of the ray (starting point)

	out float iDistance
) {
	rayOrigin -= sphereOrigin; // Coordinates relative to sphere

	return calculateRaySphereIntersection(
		sphereRadius,
		rayVector,
		rayOrigin,
		iDistance
	);
}

// Distances from both intersections
bool calculateRaySphereIntersection(
	in float sphereRadius, // Radius of the sphere
	in vec3  rayVector, // Vector of the ray (where it is pointed)
	in vec3  rayOrigin, // Origin of the ray (starting point)

	out vec2 iDistance
) {
	float rDot  = dot(rayVector, rayOrigin);
	float roLen = length(rayOrigin);

	// Prevent intersecting a second sphere in the opposite direction
	if(rDot > 0.0 && roLen > sphereRadius) return false;

	float delta = square(rDot) - square(roLen) + square(sphereRadius);

	if(delta < 0.0) return false;

	iDistance.x = -rDot + sqrt(delta);
	iDistance.y = -rDot - sqrt(delta);

	return true;
}
bool calculateRaySphereIntersection(
	in vec3  sphereOrigin, // Center of the sphere
	in float sphereRadius, // Radius of the sphere
	in vec3  rayVector, // Vector of the ray (where it is pointed)
	in vec3  rayOrigin, // Origin of the ray (starting point)

	out vec2 iDistance
) {
	rayOrigin -= sphereOrigin; // Coordinates relative to sphere

	return calculateRaySphereIntersection(
		sphereRadius,
		rayVector,
		rayOrigin,
		iDistance
	);
}
