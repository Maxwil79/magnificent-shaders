const float rpi = 1./acos(-1.);
const float hpi = acos(0.);
const float phi = sqrt(5.) * .5 + .5;
const float goldenAngle = tau / phi / phi;
#define max4(a,b,c,d) max(max(a,b),max(c,d))

#define diagonal2(m) vec2((m)[0].x, (m)[1].y)
#define diagonal3(m) vec3(diagonal2(m), m[2].z)
#define diagonal4(m) vec4(diagonal3(m), m[2].w)

vec3 toViewSpace(vec3 p) {
	p = p * 2. - 1.;
	vec4 fragposition = diagonal4(gbufferProjectionInverse) * p.xyzz + gbufferProjectionInverse[3];
	return fragposition.xyz / fragposition.w;
}

vec3 toViewSpace(vec2 p) {
	return toViewSpace( vec3( p, texture2D(depthtex1, p).x ) );
}

vec3 toViewSpace(vec2 p,float d) {
	return toViewSpace( vec3(p, d) );
}

float facos(const float sx){
	float x = clamp(abs( sx ),0.,1.);
	float a = sqrt( 1. - x ) * ( -0.16882 * x + 1.56734 );
	return sx > 0. ? a : pi - a;
	//float c = clamp(-sx * 1e35, 0., 1.);
	//return c * pi + a * -(c * 2. - 1.); //no conditional version
}

vec2 sincos(const float x){
	return vec2(sin(x),cos(x));
}

#define aoCones 3 // AO quality [ 3 5 8 16 ]
#define radius 8.
const float ambientBayerSize = 32.;
const float ambientTemporalSamples = 2.;

vec3 getHorizonVec (const vec2 offset, const float r, const vec3 normal, const float PdotN, const vec3 position){

	vec2 screenPosition = offset * r + texcoord;
	vec3 occluder = toViewSpace(screenPosition);

	// get intersection with tangent plane
	float OdotN = dot(occluder, normal);
	float tangent = PdotN / OdotN;
	// prevents from going to infinity
	tangent = OdotN >= 0. ? 16.: tangent;

	// perspective bias
	#define perspectiveBias clamp( r/(occluder.z-position.z), 0., 1. )

	// prevent occlusion behind the tangent plane
	float correction = min(1.0, tangent);
	// make occluders far in front occlude less (halo correction)
	correction = mix(tangent, correction, perspectiveBias);
	// discard samples that are off-screen
	correction = clamp(screenPosition, 0., 1.) != screenPosition ? tangent : correction;

	// return horizon direction
	return normalize(occluder * correction - position);
}

#undef perspectiveBias


vec4 getHorizonAngle(const vec2 offset, const vec3 normal, const float PdotN, const vec3 position){
	// get horizon vectors on both sides
	vec3 d0 = getHorizonVec( offset, radius     , normal, PdotN, position);
	vec3 d1 = getHorizonVec(-offset, radius     , normal, PdotN, position);
	// get horizon vectors closer to texcoord to catch occlusion by smaller objects
	vec3 d2 = getHorizonVec( offset, radius / 8., normal, PdotN, position);
	vec3 d3 = getHorizonVec(-offset, radius / 8., normal, PdotN, position);

	// get horizon angles
	float dot01 = dot(d0, d1);
	float dot03 = dot(d0, d3);
	float dot21 = dot(d2, d1);
	float dot23 = dot(d2, d3);

	// select smallest horizon angle
	float cosSkyAngle = max4(dot01, dot03, dot21, dot23); // max because we are comparing cosines not angles

	d1 = (dot03==cosSkyAngle||dot23==cosSkyAngle) ? d3 : d1;
	d0 = (dot21==cosSkyAngle||dot23==cosSkyAngle) ? d2 : d0;

	vec3 horizonDirection = d1 + d0;

	//nanfix
	horizonDirection = dot(horizonDirection,normal)<=0.? normal : horizonDirection;
	cosSkyAngle = min(cosSkyAngle, .3);

	return vec4(
		normalize( horizonDirection ),
		facos(cosSkyAngle)
	);
}

/*
// to be used with vanilla ao
vec4 getHorizonAngleCheap(vec2 offset, vec3 normal, float PdotN, vec3 position){
	// get horizon vectors on both sides
	vec3 d0 = getHorizonVec( offset, radius, normal, PdotN, position);
	vec3 d1 = getHorizonVec(-offset, radius, normal, PdotN, position);

	return vec4(
		// average direction of sky ( normal*1e-4 to prevent zero vector )
		normalize( normal * 1e-4 + d1 + d0 ),
		dot(d0, d1)
	);
}
*/

vec2 ambientSampleMap(const float i){
	const float angle = pow(ambientBayerSize,2.)*float(aoCones)*ambientTemporalSamples * .5 * goldenAngle;
	vec2 p = sincos( i * angle );
	return p * ( sqrt(i * .97 + .03) * 
		(clamp(p.x*1e35,0.,1.)*2.-1.) // fast sign()
	);
}

vec4 getHorizonCone(const vec3 normal, float normFactor, const vec3 position, const float screenDither) {

	float PdotN = dot(position, normal);

	// prevent sampling pattern from being too big
	normFactor = min(normFactor, .4);

	// size of sampling pattern based on depth
	vec2 screenSamplingRadius = vec2( normFactor, aspectRatio * normFactor);

	const float rSteps = 1. / float(aoCones);

	float dither = ( (float(frameCounter%2)*.5)*(1./ambientBayerSize/ambientBayerSize)+screenDither) * rSteps;
	
	vec4 data = vec4(0);
	for (int i = 0; i < aoCones; ++i) {
		float index = float(i) * rSteps + dither;
		vec2 point = ambientSampleMap(index) * screenSamplingRadius;
		data += getHorizonAngle(point, normal, PdotN, position);
	}

	data.a *= rSteps;
	data.xyz = normalize(data.xyz);

	return vec4(data.xyz, data.a);
}

#undef radius