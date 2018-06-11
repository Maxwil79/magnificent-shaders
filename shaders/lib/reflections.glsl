#include "raytrace.glsl"

bool getRaytraceIntersection(vec3 pos, vec3 vec, out vec3 screenSpace, out vec3 viewSpace) {
	const float maxSteps  = 32;
	const float maxRefs   = 2;
	const float stepSize  = 0.5;
	const float stepScale = 1.6;
	const float refScale  = 0.1;

	vec3 increment = vec * stepSize;

	viewSpace = pos;

	uint refinements = 0;
	for (uint i = 0; i < maxSteps; i++) {
		viewSpace  += increment;
		screenSpace = viewSpaceToScreenSpace(viewSpace, gbufferProjection);

		if (any(greaterThan(abs(screenSpace - 0.5), vec3(0.5)))) return false;

		float screenZ = texture(depthtex1, screenSpace.xy).r;
		float diff    = viewSpace.z - linearizeDepth(screenZ);

		if (diff <= 0.0) {
			// Do refinements

			if (refinements < maxRefs) {
				viewSpace -= increment;
				increment *= refScale;
				refinements++;

				continue;
			}

			// Refinements are done, so make sure we ended up reasonably close
			if (any(greaterThan(abs(screenSpace - 0.5), vec3(0.5))) || length(increment) * 10 < -diff || screenZ == 1.0) return false;

			return true;
		}

		increment *= stepScale;
	}

	return false;
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

float d_GGX(vec3 normal, vec3 halfway, float roughness) {
	float alpha = roughness;
	return pow(alpha, 2.0) / (pi * pow(pow(dot(normal, halfway), 2.0) * (pow(alpha, 2.0) - 1.0) + 1.0, 2.0));
}

float f0ToIOR(float f0) {
	f0 = sqrt(f0);
	f0 *= 0.99999; // Prevents divide by 0
	return (1.0 + f0) / (1.0 - f0);
}

float f_dielectric(float cosTheta, float eta) {
	float p = 1.0 - (eta * eta * (1.0 - cosTheta * cosTheta));
	if (p <= 0.0) return 1.0; p = sqrt(p);

	vec2 r = vec2(cosTheta, p);
	r = (eta * r - r.yx) / (eta * r + r.yx);
	return dot(r, r) * 0.5;
}

float g_smithGGXCorrelated(vec3 view, vec3 normal, vec3 light, float roughness) {
	float alpha = roughness;

	float viewG  = (-1.0 + sqrt(pow(alpha, 2.0) * (1.0 - pow(dot(normal, view ), 2.0)) / pow(dot(normal, view ), 2.0) + 1.0)) * 0.5;
	float lightG = (-1.0 + sqrt(pow(alpha, 2.0) * (1.0 - pow(dot(normal, light), 2.0)) / pow(dot(normal, light), 2.0) + 1.0)) * 0.5;
	return 1.0 / (1.0 + viewG + lightG);
}

float specularBRDF(vec3 view, vec3 normal, vec3 light, float reflectance, float roughness) {
	vec3 halfway = normalize(view + light);

	float eta = 1.0 / f0ToIOR(reflectance);
	float F = f_dielectric(dot(view, halfway), eta);

	float G = g_smithGGXCorrelated(view, normal, light, roughness);

	float D = d_GGX(normal, halfway, roughness);

	float numerator   = F * G * D;
	float denominator = 4.0 * dot(view, normal) * dot(normal, light);

	return max(numerator / denominator, 0.0);
}

#define Continuum_2 //Disable this for the format used in SEUS v11.

vec3 clampNormal(vec3 n, vec3 v){
    return dot(n, v) >= 0.0 ? cross(cross(v, n), v) : n;
}

vec3 reflection(in vec3 view, in vec3 viewVector, in vec3 world) {
    vec3 reflection = vec3(0.0);
    int i = 0;
    float id = texture(colortex4, texcoord.st).b * 65535.0;
    vec3 viewVec3 = vec3(texcoord, texture(depthtex0, texcoord).r);
    vec4 viewPosition = gbufferProjectionInverse * vec4(viewVec3 * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;
	vec3 viewDirection = normalize(viewPosition.xyz);
    vec3 shadows = decode3x16(texture(colortex0, texcoord.st).a);
    float skyLightMap = pow(decode2x16(texture(colortex4, texcoord.st).r).y, 5.0);
	skyLightMap *= skyLightMap;
    vec3 normal = unpackNormal(texture(colortex5, texcoord.st).gb);
    vec3 directionWorld = mat3(gbufferModelViewInverse) * reflect(viewDirection.xyz, normal);
	vec4 specMap = decode4x16(texture(colortex5, texcoord.st).r);
	#ifdef Continuum_2
	float reflectance = specMap.r * 0.1;
	float roughness = pow(1.0 - specMap.b, 2.0);
	#else
	bool isMetal       = (id == 41 || id == 42 || id == 101 || id == 152) && specMap.r > 0.0; // For formats without metalness maps

	float reflectance = isMetal ? 1.0 : pow(specMap.r, 3.0);
	float roughness = (-0.1 * specMap.b + 0.1) / specMap.b + 0.1;
	#endif
	float F = 0.0;

    vec3 scatterCol = vec3(0.0);

    vec3 colorSky = atmos(directionWorld, scatterCol, vec3(0.0), 2);

    vec3 waterNormal = normalize(mix(normal, normalize(hash33((1.0 * frameTimeCounter) * view.xyz) * 2.0 - 1.0), roughness));
	if (dot(waterNormal, -viewDirection.xyz) < 0.0) return vec3(0.0);

    vec3 direction = reflect(viewDirection.xyz, waterNormal);

	float schlick = (1.0 - reflectance) * pow(1.0 - clamp(dot(-normalize(viewPosition.xyz), waterNormal), 0.0, 1.0), 5.0) + reflectance;

	vec3 halfway = normalize(view + lightVector2);

	float eta = 1.0 / f0ToIOR(reflectance);
	F = f_dielectric(dot(waterNormal, direction), eta);

    float fresnel = schlick;

    vec4 hitPosition;
    if (raytraceIntersection(viewVec3, direction, hitPosition.xyz, 16.0, 4.0)) {
        reflection += textureLod(colortex0, hitPosition.xy, 0).rgb;
    } else {
        reflection += skyLightMap * colorSky.rgb;
    }

    reflection *= F;

	reflection += ((sunLight*(sunIlluminance*0.1)) * min(specularBRDF(-viewDirection, normal, sunVector2, reflectance/sunIlluminance, roughness), pi) * shadows) * (1.0 - rainStrength);
	reflection += ((moonColor) * min(specularBRDF(-viewDirection, normal, moonVector2, reflectance, roughness), pi) * shadows) * (1.0 - rainStrength);

    reflection += vec3(0.0);
    
    return reflection;
}