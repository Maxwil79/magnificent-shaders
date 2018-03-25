#define WaterFogMode 0 //[0 1 2] 0 = default. 1 = Fixed. 2 = Swamp. Fixed only looks proper when AlternateWaterdepth is on.
//#define WaterShadowEnable //Enables a water shadow. Takes a bit of FPS away.

const vec3 scoeff2 = vec3(0.45e-2, 1.92e-2, 2.25e-2) * 2.5;
const vec3 acoeff2 = vec3(8.10e-1, 3.80e-1, 2.40e-1) * 3.0;

#if WaterFogMode == 0
const vec3 scoeff = vec3(0.005, 0.01, 0.01) * 0.65;
const vec3 acoeff = vec3(1.25, 0.55, 0.3) * 0.5;
#elif WaterFogMode == 1
const vec3 scoeff = vec3(0.0, 0.0004, 0.0005) * 0.5;
const vec3 acoeff = vec3(1.3, 0.05, 0.01) * 0.3;
#elif WaterFogMode == 2
const vec3 scoeff = vec3(1.0, 1.1, 1.3) * 0.035;
const vec3 acoeff = vec3(0.065, 0.075, 0.3) * 3.75;
#endif

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = scoeff + acoeff;

    return exp(-attenCoeff * clamp(dist, 0.0, 4e12));
}