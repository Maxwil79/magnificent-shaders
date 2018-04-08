#define WaterFogMode 0 //[0] 0 = default.

const vec3 scoeff = vec3(0.003) / log(2.0);
const vec3 acoeff = vec3(0.4510, 0.0867, 0.0476) / log(2.0);

vec3 waterFogShadow(float dist) {
    vec3 attenCoeff = scoeff + acoeff;

    return exp(-(attenCoeff * 1.5) * clamp(dist, 0.0, 4e12));
}