
#include "waterwaves.glsl"

vec3 getRefraction(vec3 clr, vec3 fragpos, in float depth, in float dither) {

	float	waterRefractionStrength = 1.333;

	vec4 worldPos = gbufferModelViewInverse * vec4(fragpos, 1.0);

	vec2 waterTexcoord = textureCoordinate.st;

	waterRefractionStrength *= mix(0.2, 0.5, exp(-pow(length(fragpos.xyz), 1.5)));

		float deltaPos = 0.1;
		float h0 = getWaves(worldPos.xyz + cameraPosition.xyz);
		float h1 = getWaves(worldPos.xyz + cameraPosition.xyz - vec3(deltaPos, 0.0, 0.0));
		float h2 = getWaves(worldPos.xyz + cameraPosition.xyz - vec3(0.0, 0.0, deltaPos));

		float dX = (h0 - h1) / deltaPos;
		float dY = (h0 - h2) / deltaPos;

		vec3 waterRefract = normalize(vec3(dX, dY, 1.0));

		waterTexcoord = textureCoordinate.st + waterRefract.xy * waterRefractionStrength;

        vec4 view = vec4(vec3(waterTexcoord.st, depth) * 2.0 - 1.0, 1.0);
        view = gbufferProjectionInverse * view;
        view /= view.w;

        vec4 world = gbufferModelViewInverse * view;
        world /= world.w;
        world = gbufferPreviousProjection  * (gbufferPreviousModelView * world);
        vec4 end = gbufferProjectionInverse * vec4(waterTexcoord.xy * 2.0 - 1.0, texture2D(depthtex1, waterTexcoord.xy).r * 2.0 - 1.0, 1.0);
        end /= end.w;

		vec3 watercolor = vec3(0.0);
        if(isEyeInWater == 0) {
        watercolor = waterFogVolumetric(texture(colortex0, waterTexcoord.st).rgb, view.xyz, end.xyz, decode2x16(texture(colortex4, textureCoordinate.st).r), world.xyz, dither);
        } else {
        watercolor = texture(colortex0, waterTexcoord.st).rgb;
        }

		clr = watercolor;
    
	return clr;

}