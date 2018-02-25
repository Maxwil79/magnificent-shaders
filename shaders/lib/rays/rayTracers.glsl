bool raytraceIntersection(
	vec3 start, // Start position in screen space
	vec3 direction, // Direction to trace in view space
	out vec3 position, // Final raytraced position in screen space
	const float quality, // Samples/steps for raytrace
	const float refinements // Number of refinements
) {
	position   = start;

	// Convert start position to be view-space since it no longer needs to be screen-space
	start = screenSpaceToViewSpace(start, gbufferProjectionInverse);

	// Get the screen-space direction. Multiplying by -start.z prevents issues when very close to a surface.
	direction *= -start.z;
	direction  = viewSpaceToScreenSpace(direction + start, gbufferProjection) - position;

	float qualityRCP = 1.0 / quality;

	// Set the increment.
	// `minof((step(0.0, direction) - position) / direction)` calculates the distance to the edge of the screen.
	vec3 increment = direction * minof((step(0.0, direction) - position) / direction) * qualityRCP;

	float difference;
	bool  intersected = false;

	// Raytrace for intersection
	// Stop at ceil(quality), or once an intersection has occured, or if trace has reached beyond the far plane.
	for (float i = 0.0; i <= quality && !intersected && position.p < 1.0; i++) {
		position   += increment; // Step forwards
		if (floor(position.st) != vec2(0.0)) break; // makes sure we don't improperly intersect anything off-screen
		difference  = texture(depthtex2, position.st).r - position.p; // Find difference between current depth and scene depth at current pixel
		intersected = difference < 0.0; // If the difference is negative, we've hit a surface
	}

	// Validate intersection
	// Middle check makes sure you're not intersecting the far plane (sky), rightmost check makes sure you're not intersecting from a point where you can't actually intersect anything
	intersected = intersected && (difference + position.p) < 1.0 && position.p > 0.0;

	if (intersected && refinements > 0.0) {
		// Refine intersection position
		// This is a binary search, it basically halves the step size, and then checks if it's in front of or behind a surface, then steps back if behind the surface and forwards if in front of the surface, and then repeats.
		for (float i = 0.0; i < refinements; i++) {
			increment *= 0.5;
			position  += texture(depthtex1, position.st).r - position.p < 0.0 ? -increment : increment;
		}
	}

	return intersected;
}

bool raytraceIntersection(vec4 position, vec3 direction, out vec4 screenSpace, in float maxSteps, in float maxRefs, in float stepSize, in float stepScale, in float refScale) {

    vec3 increment = direction * stepSize;
    increment *= abs(position.z);

    vec4 viewSpace = position;

    int refinements = 0;
    for (int i = 0; i < maxSteps; i++) {
        viewSpace.xyz += increment;
        screenSpace    = gbufferProjection * viewSpace;
        screenSpace   /= screenSpace.w;
        screenSpace    = screenSpace * 0.5 + 0.5;

        if (any(greaterThan(abs(screenSpace.xyz - 0.5), vec3(0.5)))) return false;

        float screenZ = texture2D(depthtex2, screenSpace.xy).r;
        float diff    = viewSpace.z - linearizeDepth(screenZ);

        if (diff <= 0.0) {
            if (refinements < maxRefs) {
                viewSpace.xyz -= increment;
                increment *= refScale;
                refinements++;

                continue;
            }

            if (any(greaterThan(abs(screenSpace.xyz - 0.5), vec3(0.5))) || length(increment) * 10 < -diff || screenZ == 1.0) return false;

            return true;
        }

        increment *= stepScale;
    }

    return false;
}