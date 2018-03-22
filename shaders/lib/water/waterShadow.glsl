#define WaterFogMode 0 //[0 1 2] 0 = default. 1 = Fixed. 2 = Swamp. Fixed only looks proper when AlternateWaterdepth is on.
//#define WaterShadowEnable //Enables a water shadow. Takes a bit of FPS away.

const vec3 scoeff2 = vec3(0.45e-2, 1.92e-2, 2.25e-2) * 2.5;
const vec3 acoeff2 = vec3(8.10e-1, 3.80e-1, 2.40e-1) * 3.0;

#if WaterFogMode == 0
const vec3 scoeff = vec3(0.005, 0.01, 0.01) * 0.35;
const vec3 acoeff = vec3(1.25, 0.55, 0.3) * 0.35;
#elif WaterFogMode == 1
const vec3 scoeff = vec3(0.0, 0.0004, 0.0005) * 0.5;
const vec3 acoeff = vec3(1.3, 0.05, 0.01) * 0.3;
#elif WaterFogMode == 2
const vec3 scoeff = vec3(1.0, 1.1, 1.3) * 0.035;
const vec3 acoeff = vec3(0.065, 0.075, 0.3) * 3.75;
#endif

#define WaterfogDensity 15.5 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 12.5 13.0 13.5 14.0 14.5 15.0 15.5 16.0 16.5 17.0 17.5 18.0 18.5 19.0 19.5 20.0 21.0 21.5 22.0 22.5 23.0 23.5 24.0 24.5 25.0 25.5 26.0 26.5 27.0 27.5 28.0 28.5 29.0 29.5 30.0 31.0 31.5 32.0 32.5 33.0 33.5 34.0 34.5 35.0 35.5 36.0 36.5 37.0 37.5 38.0 38.5 39.0 39.5 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0 95.0 100.0 110.0 120.0 130.0 140.0 150.0 160.0 170.0 180.0 190.0 200.0] Changes the opacity of the water fog.

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = scoeff + acoeff;
    #ifndef WiP_SwampWater
    float density = 1.0;
    #else
    float density = WaterfogDensity;
    #endif

    return exp(-attenCoeff * clamp(dist, 0.0, 4e12));
}