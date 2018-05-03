const vec3 scoeff = vec3(0.0007, 0.005, 0.005) * 0.85;
const vec3 acoeff = vec3(0.2510, 0.0867, 0.0476) * 1.65;

vec3 waterFog(vec4 color, float dist) {

    vec3 transmittance = exp(-acoeff * dist);
    vec3 scattered = scoeff * (1.0 - exp(-acoeff * dist)) / acoeff;

    vec4 colorDirect = color;

    atmosphere(colorDirect.rgb, lightVector.xyz, sunVector, moonVector, ivec2(16, 4));

    vec2 lightmap = decode2x16(texture(colortex4, texcoord.st).r).xy;
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;
    vec3 lighting = lightmap.y * colorDirect.rgb;

    return color.rgb * transmittance + lighting * scattered;
}

float noise = fract(sin(dot(texcoord.xy, vec2(18.9898f, 28.633f))) * 4378.5453f) * 4.0 / 5.0;
mat2 noiseM = mat2(cos(noise), -sin(noise),
						   sin(noise), cos(noise));

#define square(x) x*x

const vec2[16] diskOffset = vec2[16](
	vec2(0.9553798f, 0.08792616f),
	vec2(0.7564816f, 0.6107687f),
	vec2(0.4300687f, -0.339003f),
	vec2(0.2410402f, 0.398774f),
	vec2(0.07018216f, -0.8776324f),
	vec2(-0.2103648f, -0.3532368f),
	vec2(0.8417408f, -0.5299217f),
	vec2(0.1464538f, -0.0502334f),
	vec2(0.5003511f, -0.7529236f),
	vec2(-0.132682f, 0.6056585f),
	vec2(-0.2401425f, 0.1240332f),
	vec2(0.3478812f, 0.8243276f),
	vec2(-0.8337253f, 0.1119805f),
	vec2(-0.6568771f, -0.3930125f),
	vec2(-0.6461575f, 0.7098891f),
	vec2(-0.3569236f, -0.9252638f)
);

float water_fournierForandPhase(float theta, float mu, float n) {
    float v     = (3.0 - mu) * 0.5;
    float u     = 2.0 * clamp01(sin(theta / 2.0));
    float delta = square(u) / (3.0 * square(n - 1.0));

    float deltapv = pow(delta + 1e-9, v);

    float
    result  = (v * (1.0 - delta) - (1.0 - deltapv)) + (4.0 / (square(u) + 1e-9)) * (delta * (1.0 - deltapv) - v * (1.0 - delta));
    result /= 4.0 * pi * square(1.0 - delta) * deltapv + 5e-6;

    return result;
}

float miePhase(float cosTheta, float g) {
	float gg = g * g;

	float p1 = (3.0 * (1.0 - gg)) / (2.0 * (2.0 + gg));
	return p1 * (cosTheta * cosTheta + 1.0) / pow(1.0 + gg - 2.0 * g * cosTheta, 1.5);
}

vec3 water_volume(vec4 color, vec3 start, vec3 end, vec2 lightmap, vec3 world) {  
    const vec3 attenCoeff = acoeff + scoeff;

    int steps = VolumetricSteps;

    lightmap = pow(lightmap, vec2(2.0, 5.0));
    if (isEyeInWater == 1) lightmap = vec2(eyeBrightnessSmooth) / 240.0;

    vec4 colorDirect = color;
    vec4 colorSky = color;

    atmosphere(colorDirect.rgb, lightVector.xyz, sunVector, moonVector, ivec2(8, 2));
    atmosphere(colorSky.rgb, mat3(gbufferModelViewInverse) * upVector, sunVector, moonVector, ivec2(8, 2));

    vec3 lightColor = vec3(0.0);
    lightColor = colorDirect.rgb;
    vec3 skyLightColor = colorSky.rgb * (vec3(0.93636, 1.5606, 2.40908)) * lightmap.y;

	vec3 rayVec  = end - start;
	     rayVec /= steps;
	float stepSize = length(rayVec);


	float VoL   = dot(normalize(end - start), lightVector2);
    float isotropicPhase = 0.25 / pi;
    float waterPhase = isotropicPhase + water_fournierForandPhase(acos(dot(normalize(end - start), lightVector2)), 3.23, 1.24);

    vec3 transmittance = vec3(1.0);
	vec3 scattered  = vec3(0.0) * transmittance;

    vec3 increment = (end - start) / steps;
    start -= increment * bayer64(gl_FragCoord.st);

    mat4 shadowMatrix = shadowProjection * shadowModelView * gbufferModelViewInverse; //Thank you to BuilderB0y for showin me this. 

	// Shadow map properties

	float mapRadius = shadowProjectionInverse[1].y;
	float mapDepth  = shadowProjectionInverse[2].z * -16.0;
	int mapResolution = shadowMapResolution;

	// Calculate spread
	float spread = (tan(radians(1.75)) * mapDepth / (2.0 * mapRadius)) / 1.0;

    start = mat3(shadowMatrix) * start + shadowMatrix[3].xyz;
    end = mat3(shadowMatrix) * end + shadowMatrix[3].xyz;
    increment = mat3(shadowMatrix) * increment;
    vec4 curPos = vec4(start, 1.0);
    float lengthOfIncrement = length(increment);
    vec3 sunlightConribution = lightColor;
    vec3 skylightContribution = skyLightColor;
    float depth = stepSize;
    for (int i = 0; i < steps; i++) {
        curPos.xyz += increment;
        vec3 shadowPos = curPos.xyz / vec3(vec2(ShadowDistortion(curPos.xy)), 6.0) * 0.5 + 0.5;

        /*
	    // Noise
	    mat2 rot = noiseM;

	    float depthAverage = 0.0;
	    for (int i = 0; i < diskOffset.length(); i++) {
	    	vec2 scoord = shadowPos.xy + (diskOffset[i] / mapRadius);

	    	vec4 depthSamples = textureGather(shadowtex1, scoord);
	    	depthSamples = max(vec4(0.0), shadowPos.z - depthSamples);
	    	depthAverage += dot(depthSamples, vec4(0.25));
	    }

	    float penumbraSize = max(depthAverage * spread, 1.0 / mapResolution);

	    penumbraSize = clamp(penumbraSize, 0.0, 0.008);

	    vec3 shadow = vec3(0.0);

	    for (int i = 0; i < diskOffset.length(); i++) {
	    	vec3 sampleCoord = vec3(shadowPos.st + (hash22(gl_FragCoord.st) * diskOffset[i] * penumbraSize), shadowPos.p);

	    	float shadowOpaque      = float(textureLod(shadowtex0,   sampleCoord.st,    0).r > shadowPos.p - 0.000003);
	    	float shadowTransparent = float(textureLod(shadowtex1,   sampleCoord.st, 0).r > shadowPos.p - 0.000003);

	    	shadow = mix(vec3(shadowOpaque), vec3(1.0), float(shadowTransparent > shadowOpaque));
	        shadow *= sunlightConribution / diskOffset.length();

            scattered += (shadow + (skylightContribution / diskOffset.length()/6.0)) * transmittance;
        }
        */
    	float shadowOpaque      = float(textureLod(shadowtex0,   shadowPos.st,    0).r > shadowPos.p - 0.000003);
	    float shadowTransparent = float(textureLod(shadowtex1,   shadowPos.st, 0).r > shadowPos.p - 0.000003);

	    vec3 shadow = mix(vec3(shadowOpaque), vec3(1.0), float(shadowTransparent > shadowOpaque));
	        shadow *= sunlightConribution;
        
        scattered += (shadow + skylightContribution) * transmittance;
        transmittance *= exp(-attenCoeff * depth);
    } scattered *= scoeff;
    scattered *= (1.0 - exp(-attenCoeff * depth)) / (attenCoeff);

    return color.rgb * transmittance + scattered;
}