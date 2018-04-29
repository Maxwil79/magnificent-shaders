#define PI 3.1415926
#define mieG 0.85

float sunIlluminance = 1e5;
float moonIlluminance = sunIlluminance * 7e-8; //Not really physically based.

float phaseFunctionRayleigh(in float cosTheta)
{
    return (3.0 / 4.0) * (1.0 + cosTheta * cosTheta);
}

#define sqaured(x) x*x

float phaseFunctionMie(in float cosTheta, in float g)
{
	return 1.5 * 1.0 / (4.0 * pi) * (1.0 - sqaured(g)) * pow(1.0 + (sqaured(g)) - 2.0*g*cosTheta, -3.0/2.0) * (1.0 + cosTheta * cosTheta) / (2.0 + sqaured(g));
}

#include "sky.glsl"

void atmosphere(inout vec3 color, in vec3 view, in vec3 sun, in vec3 moon, in ivec2 steps) {
    color = atmosphere(
        normalize(view),           // normalized ray direction
        vec3(0,6371e3,0),               // ray origin
        sun,                        // position of the sun
        sunIlluminance,                           // intensity of the sun
        6371e3,                         // radius of the planet in meters
        6471e3,                         // radius of the atmosphere in meters
        vec3(5.5e-6, 13.0e-6, 22.4e-6), // Rayleigh scattering coefficient
        9e-6,                          // Mie scattering coefficient
        8e3,                            // Rayleigh scale height
        1.2e3,                          // Mie scale height
        mieG,                           // Mie preferred scattering direction
        moon,
        steps.x,
        steps.y,
        vec3(vec3(3.426, 8.298, 0.356) * 6.0e-7) / log(2.0),
        3.2e4
    );
}
