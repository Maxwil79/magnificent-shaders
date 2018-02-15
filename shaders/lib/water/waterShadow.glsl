//#define WiP_SwampWater //Looks very weird right now.
//#define WaterShadowEnable //Enables a water shadow. Takes a bit of FPS away.

#ifndef WiP_SwampWater
const vec3 scoeff = vec3(0.0000, 0.01, 0.01) * 4.0;
const vec3 acoeff = vec3(1.15, 0.09, 0.002) / (3.5*3.5);
#else
const vec3 scoeff = vec3(0.0004, 1.5, 0.0003) * 2.075;
const vec3 acoeff = vec3(14.02, 0.05, 0.08) * 150.0;
#endif

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = scoeff + acoeff;

    return exp(-(attenCoeff * 11.0) * clamp(dist, 0.0, 4e12));
}