/*
vec3 F_Schlick (in vec3 f0 , in float f90 , in float u) {
     return f0 + ( f90 - f0 ) * pow (1.f - u , 5.f);
}

float Fr_DisneyDiffuse ( float NdotV, float NdotL, float LdotH, float linearRoughness) {
 float energyBias = lerp (0 , 0.5 , linearRoughness );
 float energyFactor = lerp (1.0 , 1.0 / 1.51 , linearRoughness );
 float fd90 = energyBias + 2.0 * LdotH * LdotH * linearRoughness ;
 vec3 f0 = vec3 (1.0f , 1.0f , 1.0f);
 float lightScatter = F_Schlick ( f0 , fd90 , NdotL ) .r;
 float viewScatter = F_Schlick (f0 , fd90 , NdotV ).r;

 return lightScatter * viewScatter * energyFactor ;
}
*/
/*
const float tau = pi*2.0;

const int noiseTextureResolution = 96;

float waterNoise(vec2 coord) {
		vec2 floored = floor(coord);
		vec4 samples = textureGather(noisetex, floored / noiseTextureResolution); // textureGather is slightly offset (at least on nvidia) and this offset can change with driver versions, which is why i floor the coords
		vec4 weights = (coord - floored).xxyy * vec4(1,-1,1,-1) + vec4(0,1,0,1);
		weights *= weights * (-2.0 * weights + 3.0);
		return dot(samples, weights.yxxy * weights.zzww);
}

float getWaves(in vec3 position)
{
	const uint numWaves = 4;
	float waveTime = frameTimeCounter * 0.05;

	// Base translation
	vec2 p = -(position.xz + position.y) + waveTime;

	// Scale
	p /= 35.0;

	const float weightArray[numWaves] = float[numWaves] (
		1.0,
		8.0,
		15.0,
		25.0
	);

	vec2 pArray[numWaves] = vec2[numWaves] (
		(p / 1.6) + waveTime * vec2(0.03, 0.07),
		(p / 3.1) + waveTime * vec2(0.08, 0.06),
		(p / 4.7) + waveTime * vec2(0.07, 0.10),
		(p / 8.9) + waveTime * vec2(0.04, 0.02)
	);

	const vec2 scaleArray[numWaves] = vec2[numWaves] (
		vec2(2.0, 1.4),
		vec2(1.7, 0.7),
		vec2(1.0, 1.2),
		vec2(1.0, 0.8)
	);

	vec2 translationArray[numWaves] = vec2[numWaves] (
		vec2(pArray[0].y * 0.5, pArray[0].x * 2.2),
		vec2(pArray[1].y * 0.9, pArray[1].x * 1.1),
		vec2(pArray[2].y * 1.5, pArray[2].x * 1.5),
		vec2(pArray[3].y * 1.5, pArray[3].x * 1.7)
	);

	float waves   = 0.0;
	float weights = 0.0;

	for(int id = 0; id < numWaves; id++) {
		float wave = waterNoise(((pArray[id] * scaleArray[id]) + translationArray[id]) * noiseTextureResolution).r;

		waves   += wave * weightArray[id];
		weights += weightArray[id];
	}

	waves /= weights;

	waves *= 0.4;
	waves -= 0.4;

	return waves;
}

vec3 getWaterNormal(in vec3 world) {
	const float sampleDist = 0.61;
	vec3 newWorld = world;
	vec2 heightDiffs = vec2(getWaves(vec3(sampleDist,0.0,-sampleDist) + newWorld), getWaves(vec3(-sampleDist,0.0,sampleDist) + newWorld)) - getWaves(vec3(-sampleDist,0.0,-sampleDist) + newWorld);
	heightDiffs *= 13.91;

	vec3 waterNormal;
	waterNormal.xy = heightDiffs;
	waterNormal.z  = sqrt(1.0 - dot(waterNormal.xy, waterNormal.xy));

	return waterNormal;
}

vec2 pointOnSpiral(float index, float total) {
	index = sqrt(index * tau * 2.0);
	return vec2(sin(index), cos(index)) * index / sqrt(total * tau * 2.0);
}

float getCaustics(in vec3 position) {
    vec3 lightingVector = mat3(gbufferModelViewInverse) * normalize(shadowLightPosition);
    float surfaceDistance = position.y - 62.9;

    vec3 flatRefract = refract(-lightingVector, vec3(0.0, 1.0, 0.0), 0.75);
    vec3 surfacePosition = position - flatRefract * (surfaceDistance / flatRefract.y);
    
    float getDither = dither;

    float distanceThreshold = sqrt(4.0 / pi) / (0.30 * 1.0);

    float finalCaustic = 0.0;
    for(float j = -0.5; j <= 0.5; j++) {
        for (float i = -0.5; i <= 0.5; i++) {
            vec3 samplePos = vec3(i*i*i, 0.0, j*j*j) * getDither + surfacePosition;
            samplePos.xy += pointOnSpiral(i*i*i, i*i*i + j*j*j);
            vec3 refractVector = refract(-lightingVector, getWaterNormal(samplePos).xzy, 0.75);

            samplePos = refractVector * (surfaceDistance / refractVector.y) + samplePos;

            finalCaustic += 1.0 - clamp(distance(position, samplePos) * distanceThreshold, 0.0, 1.0);
        }
    }
    return pow(finalCaustic / (1.0 * 1.0), 1.5);
}
*/
#include "distortion.glsl"

#define Torch_Temperature 3450 //[1000 1100 1150 1200 1250 1300 1350 1400 1450 1500 1550 1600 1650 1700 1750 1800 1850 1900 1950 2000 2100 2150 2200 2250 2300 2350 2400 2450 2500 2550 2600 2650 2700 2750 2800 2850 2900 2950 3000 3100 3150 3200 3250 3300 3350 3400 3450 3500 3550 3600 3650 3700 3750 3800 3850 3900 3950] A lower value gives a more red result, and can make Endermen eyes look strange.
#define Attenuation 3.5 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5] A higher value will make the torch lightmaps smaller.

vec3 blockLightColor = 0.0035 * blackbody(Torch_Temperature);

vec3 getShading(in vec3 color, in vec3 world, in float id, out float shadowOpaque, in vec3 viewVector) {

    mat4 shadowMVP = shadowProjection * shadowModelView;
    vec4 shadowPos  = shadowMVP * vec4(world, 1.0);

    shadowPos.xy /= ShadowDistortion(shadowPos.st);
    shadowPos.z /= 6.0;

    shadowPos = shadowPos * 0.5 + 0.5;

    vec3 shadows = vec3(0.0);
    vec3 lighting = vec3(0.0);

    float noise = fract(sin(dot(textureCoordinate.xy, vec2(18.9898f, 28.633f))) * 4378.5453f) * 4.0 / 5.0;
    mat2 noiseM = mat2(cos(noise), -sin(noise),
						   sin(noise), cos(noise));

	mat2 rot = noiseM;

    #if ShadowType == 0
    #include "shadows/hard.glsl"
    #elif ShadowType == 1
    #include "shadows/soft.glsl"
    #endif

    #ifdef WaterShadowEnable
    float shadowDepthSample = texture(shadowtex0, shadowPos.st).r - shadowPos.z;
    vec3 waterShadow = waterFogShadow((shadowDepthSample * 2.0) * shadowProjectionInverse[2].z);
    float waterShadowCast = float(texture(shadowcolor1, shadowPos.st).r > shadowPos.z - 0.0009);

    if(waterShadowCast == 1.0) shadows *= waterShadow;
    #endif

    vec3 normal = decodeNormal3x16(texture(colortex4, textureCoordinate.st).g) * mat3(gbufferModelView);

    float shadowCast = float(texture(shadowtex0, shadowPos.st).r);

    float NdotL = dot(normal,lightVector);
    float NdotV = dot(normal,viewVector);

    vec3 H = normalize(lightVector+viewVector);
    float NdotH = dot(normal,H);
    float LdotH = dot(lightVector,H);

    float diffuse = max(0.0, NdotL);
    if(id == 51.0) diffuse = 1.0;
    if(id == 18.0 || id == 31.0 || id == 38.0 || id == 59.0 || id == 80.0 || id == 106.0 || id == 141.0 || id == 142.0 || id == 161.0 || id == 175.0 || id == 207.0) diffuse = 1.0;

    //if(diffuse == max(0.0, NdotL) && shadowCast == 1.0) shadows = vec3(1.0);

    vec2 lightmap = decode2x16(texture(colortex4, textureCoordinate.st).r);

    lighting = (get_atmosphere_transmittance(sunVector, upVector, moonVector) * diffuse) * shadows + lighting;
    lighting = blockLightColor * pow(lightmap.x, Attenuation) + lighting;
    lighting = (get_atmosphere_ambient(vec3(0.0), vec3(0.0), sunVector, upVector, moonVector)) * pow(lightmap.y, 5.0) + lighting;

    vec3 emission = color * 0.15;
    if (id == 10.0 || id == 11.0 || id == 51.0 || id == 89.0) {
        emission *= sqrt(dot(color.rgb, color.rgb)) / 50.0;
    } else if (id == 50.0) {
        emission *= pow(max(dot(color.rgb, color.rgb) * 1.3 - 0.3, 0.0), 0.0005) / 50.0;
    } else if (id == 62.0 || id == 94.0 || id == 149.0) {
         emission *= max(color.r * 100.6 - 0.6, 0.0) * abs(dot(color.rgb, vec3(1.0 / 3.0)) - color.r);
    } else if (id == 76.0 || id == 213.0) {
         emission *= max(color.r * 1.6 - 0.6, 0.0) * 0.0005;
    } else if (id == 169.0) {
        emission *= pow(max(dot(color.rgb, color.rgb) * 1.3 - 0.3, 0.0), 2.0) / 100.0;
    } else if (id == 124.0) {
        emission *= sqrt(max(dot(color.rgb, color.rgb) * 1.01 - 0.01, 0.0));
    } else {
        emission *= 0.0;
    }

    color = color * lighting + emission;
    return color;
}