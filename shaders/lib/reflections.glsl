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

float better_fresnel(in vec3 viewVector, in vec3 normal) {
    //The code in this function was shared by stduhpf.
    float n0 = 1.333;
    vec3 ri = normalize(viewVector.xyz);
    vec3 rt = refract(ri, normal, 1.000/n0);
    float cti = dot(ri,normal),ctt = dot(rt,normal);
    float fresnel = (n0*cti-ctt)/(n0*cti+ctt);
    fresnel*=fresnel;
    float fresnel2 = (ctt-n0*cti)/(n0*cti+ctt);
    fresnel =.5*(fresnel+fresnel2*fresnel2);
    return fresnel;
}

vec3 reflection(in vec3 view, in vec3 viewVector, in vec3 world, in vec4 color) {
    vec3 reflection = vec3(0.0);
    int i = 0;
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(texcoord, texture(depthtex0, texcoord).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;
    vec3 viewDirection = normalize(viewPosition.xyz);
    vec3 viewVec3 = vec3(texcoord, texture(depthtex0, texcoord).r);
    vec3 shadows = decode3x16(texture(colortex0, texcoord.st).a);
    float skyLight = pow(decode2x16(texture(colortex4, texcoord.st).r).y, 7.0);
    vec3 waterNormal = unpackNormal(texture(colortex1, texcoord.st).rg);

    vec4 colorSky = color;

    vec3 directionWorld = mat3(gbufferModelViewInverse) * reflect(viewDirection.xyz, waterNormal);

    atmosphere(colorSky.rgb, directionWorld, sunVector, moonVector, ivec2(8, 2));

    float fresnel = better_fresnel(view, waterNormal);

    vec3 direction = reflect(viewDirection.xyz, waterNormal);
    vec4 hitPosition;
    if (raytraceIntersection(viewVec3, direction, hitPosition.xyz, 8.0, 4.0)) {
        reflection += textureLod(colortex0, hitPosition.xy, 0).rgb * fresnel;
    } else {
    reflection += skyLight * colorSky.rgb * fresnel;
    }

    reflection += vec3(0.0);
    
    return reflection;
}