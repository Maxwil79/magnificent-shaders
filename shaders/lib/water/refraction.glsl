//These IOR values are from: https://pixelandpoly.com/ior.html
#define WaterIOR 1.333
#define AirIOR 1.000

#include "waterfog.glsl"

vec3 refractionEffect(vec4 view, float waterDepth, vec2 lightmap, float depth, in vec3 normal, in float dither) {
    vec4 viewPosition = gbufferProjectionInverse * vec4(vec3(textureCoordinate, texture2D(depthtex0, textureCoordinate).r) * 2.0 - 1.0, 1.0);
    viewPosition /= viewPosition.w;

    vec3 start = view.xyz;

    float refractAmount = clamp(waterDepth, 0.0, 1.0);
    float refractionTexcoord = clamp01(5.0 - abs(textureCoordinate.y * 2.0 - 5.0));
    if(isEyeInWater == 0) refractAmount *= refractionTexcoord;

    vec4 world = gbufferModelViewInverse * view;
    world /= world.w;

    vec3 refractionDirection = refract(normalize(view.xyz), normal, isEyeInWater == 1 ? WaterIOR/AirIOR : AirIOR/WaterIOR);
    if (refractionDirection == vec3(0.0)) {
        // Total internal reflection
        vec3 direction = reflect(normalize(viewPosition.xyz), normal);
        vec2 lightmap = texture2D(colortex2, textureCoordinate).rg;
        vec4 hitPosition;
        if (!raytraceIntersection(vec3(textureCoordinate, texture(depthtex0, textureCoordinate).r), direction, hitPosition.xyz, 64.0, 4.0)) {
            vec3 hitViewPositon = screenSpaceToViewSpace(hitPosition.xyz, gbufferProjectionInverse);
            return vec3(0.0);
        } 
        return waterFogVolumetric(texture(colortex0, hitPosition.xy).rgb, viewPosition.xyz, screenSpaceToViewSpace(hitPosition.xyz, gbufferProjectionInverse), lightmap, world.xyz, dither);
    }

    view.xyz += refractionDirection * refractAmount;

    view = gbufferProjection * view;
    view /= view.w;

    if(isEyeInWater == 1) view.xy = view.xy * 0.5 + 0.5;

    //vec4 world = gbufferModelViewInverse * view;
    //world /= world.w;

    vec4 end = gbufferProjectionInverse * vec4(view.xy, texture2D(depthtex1, view.xy * 0.5 + 0.5).r * 2.0 - 1.0, 1.0);
    end /= end.w;

    float waterDepthRefracted = linearizeDepth(texture2D(depthtex0, textureCoordinate).r) - linearizeDepth(texture2D(depthtex1, view.xy).r);

    if (isEyeInWater == 0) return waterFogVolumetric(texture2DLod(colortex0, view.xy * 0.5 + 0.5, 0.0).rgb, start, end.xyz, lightmap, world.xyz, dither);
    if (isEyeInWater == 1) return texture2DLod(colortex0, view.xy, 0.0).rgb;
}

#include "fakeRefraction.glsl"