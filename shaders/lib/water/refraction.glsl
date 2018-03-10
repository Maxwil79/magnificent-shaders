//These IOR values are from: https://pixelandpoly.com/ior.html
#define WaterIOR 1.333
#define AirIOR 1.000

#include "waterfog.glsl"

vec3 raytraceRefractionEffect(vec4 view, float waterDepth, float depth) {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture2D(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    float refractAmount = clamp(waterDepth, 0.0, 1.0);
    float refractionTexcoord = clamp01(4.8 - abs(view.y * 2.0 - 5.0));
    //refractAmount *= refractionTexcoord;
    vec3 waterNormal = unpackNormal(texture(colortex1, textureCoordinate.st).rg);

    vec3 refractionDirection = refract(normalize(view.xyz), waterNormal, isEyeInWater == 1 ? WaterIOR/AirIOR : AirIOR/WaterIOR);

    if (refractionDirection == vec3(0.0)) {
        // Total internal reflection
        vec3 direction = reflect(normalize(viewPosition.xyz), waterNormal);
        vec2 lightmap = texture2D(colortex2, textureCoordinate).rg;
        vec4 hitPosition;
        if (!raytraceIntersection(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r), direction, hitPosition.xyz, 32.0, 4.0)) {
            return waterFog(texture(colortex0, hitPosition.xy).rgb, waterDepth * 15e5);
        } 
        float depthDist = distance(screenSpaceToViewSpace(hitPosition.xyz, gbufferProjectionInverse), view.xyz);
        return waterFog(textureLod(colortex0, hitPosition.xy, 0.0).rgb, max(depthDist, 1.0));
    }

/*
    These are the proper settings for raytraced refraction
    const float maxSteps  = 32.0;
    const float maxRefs   = 6;
    const float stepSize  = 0.02;
    const float stepScale = 1.3;
    const float refScale  = 0.5;
*/

    raytraceIntersection(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r), refractionDirection, view.xyz, 32.0, 4.0);
    if(!raytraceIntersection(viewPosition, refractionDirection, view, 512.0, 8.0, 0.5, 1.0, 0.5) && isEyeInWater == 0) return waterFog(textureLod(colortex0,textureCoordinate.xy, 0.0).rgb, max(waterDepth, 1.0));

    float waterDepthRefracted = linearizeDepth(texture2D(depthtex0, textureCoordinate).r) - linearizeDepth(texture2D(depthtex1, view.xy).r);

    if (isEyeInWater == 0) return waterFog(textureLod(colortex0, view.xy, 0.0).rgb, max(waterDepthRefracted, 1.0));
    if (isEyeInWater == 1) return textureLod(colortex0, view.xy, 0.0).rgb;
}

vec3 refractionEffect(vec4 view, float waterDepth, vec2 lightmap, float depth, in vec3 normal) {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture2D(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    vec3 start = view.xyz;

    float refractAmount = clamp(waterDepth, 0.0, 1.0);
    float refractionTexcoord = clamp01(5.0 - abs(textureCoordinate.y * 2.0 - 5.0));
    if(isEyeInWater == 0) refractAmount *= refractionTexcoord;

    vec3 refractionDirection = refract(normalize(view.xyz), normal, AirIOR/WaterIOR);

    view.xyz += refractionDirection * refractAmount;

    view = gbufferProjection * view;
    view /= view.w;

    if(isEyeInWater == 1) view.xy = view.xy * 0.5 + 0.5;

    vec4 world = gbufferModelViewInverse * view;
    world /= world.w;

    vec4 end = gbufferProjectionInverse * vec4(view.xy, texture2D(depthtex1, view.xy * 0.5 + 0.5).r * 2.0 - 1.0, 1.0);
    end /= end.w;

    float waterDepthRefracted = linearizeDepth(texture2D(depthtex0, textureCoordinate).r) - linearizeDepth(texture2D(depthtex1, view.xy).r);

    //if(!hit) return waterFog(texture2DLod(colortex0, textureCoordinate.xy, 0).rgb, max(waterDepth, 0.0), lightmap) * phase;

    if (isEyeInWater == 0) return waterFogVolumetric(texture2DLod(colortex0, view.xy * 0.5 + 0.5, 0.0).rgb, start, end.xyz, lightmap, world.xyz);
    if (isEyeInWater == 1) return texture2DLod(colortex0, view.xy, 0.0).rgb;
}