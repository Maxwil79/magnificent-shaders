//#define WiP_SwampWater //Looks very weird right now.
//#define WaterShadowEnable //Enables a water shadow. Takes a bit of FPS away.

#ifndef WiP_SwampWater
const vec3 scoeff = vec3(1.20e-3, 7.20e-3, 8.00e-3);
const vec3 acoeff = vec3(2.70e-1, 0.40e-1, 0.030e-1) * 0.09;
#else
const vec3 scoeff = vec3(0.45, 0.45, 0.03) * 0.035;
const vec3 acoeff = vec3(0.075, 0.065, 0.3) * 0.75;
#endif

#define WaterfogDensity 15.5 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 12.5 13.0 13.5 14.0 14.5 15.0 15.5 16.0 16.5 17.0 17.5 18.0 18.5 19.0 19.5 20.0 21.0 21.5 22.0 22.5 23.0 23.5 24.0 24.5 25.0 25.5 26.0 26.5 27.0 27.5 28.0 28.5 29.0 29.5 30.0] Changes the opacity of the water fog.

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = scoeff + acoeff;

    return exp(-(attenCoeff * WaterfogDensity) * clamp(dist, 0.0, 4e12));
}