//#define WiP_SwampWater //Looks very weird right now.
//#define WaterShadowEnable //Enables a water shadow. Takes a bit of FPS away.
#define Blah

#ifndef WiP_SwampWater
const vec3 scoeff = vec3(1.20e-3, 7.20e-3, 8.00e-3);
const vec3 acoeff = vec3(2.70e-1, 0.60e-1, 0.030e-1) * 0.2;
#else
const vec3 scoeff = vec3(0.0004, 1.5, 0.0003) * 2.075;
const vec3 acoeff = vec3(14.02, 0.05, 0.08) * 150.0;
#endif

#define WaterfogDensity 15.5 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 12.5 13.0 13.5 14.0 14.5 15.0 15.5] Changes the opacity of the water fog.

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = scoeff + acoeff;

    return exp(-(attenCoeff * WaterfogDensity) * clamp(dist, 0.0, 4e12));
}