bool raytraceIntersection(
	vec3 start,
	vec3 direction,
	out vec3 position,
	const float quality,
	const float refinements
) {
	position   = start;

	start = screenSpaceToViewSpace(start, gbufferProjectionInverse);

	direction *= -start.z;
	direction  = viewSpaceToScreenSpace(direction + start, gbufferProjection) - position;

	float qualityRCP = 1.0 / quality;

	vec3 increment = direction * minof((step(0.0, direction) - position) / direction) * qualityRCP;

	float difference;
	bool  intersected = false;

	for (float i = 0.0; i <= quality && !intersected && position.p < 1.0; i++) {
		position   += increment;
		if (floor(position.st) != vec2(0.0)) break;
		difference  = texture(depthtex2, position.st).r - position.p;
		intersected = difference < 0.0;
	}

	intersected = intersected && (difference + position.p) < 1.0 && position.p > 0.0;

	if (intersected && refinements > 0.0) {
		for (float i = 0.0; i < refinements; i++) {
			increment *= 0.5;
			position  += texture(depthtex1, position.st).r - position.p < 0.0 ? -increment : increment;
		}
	}

	return intersected;
}