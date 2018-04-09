#version 420

#define TonemapVersion 1 //[0 1 2] 0 = ACES tonemap. 1 = Uncharted 2 tonemap. 2 = Jodie's Robo Tonemap.

layout (location = 0) out vec4 color;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

uniform float viewWidth, viewHeight;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform sampler2D depthtex0;

in vec2 textureCoordinate;

#include "lib/util.glsl"

// Tonemapping operator used in Uncharted 2.
// Source: http://filmicgames.com/archives/75
vec3 tonemapUncharted2(
	inout vec3 color
) {
	const float A = 0.15; // Default: 0.15
	const float B = 0.50; // Default: 0.50
	const float C = 0.10; // Default: 0.10
	const float D = 0.40; // Default: 0.20
	const float E = 0.02; // Default: 0.02
	const float F = 0.30; // Default: 0.30
	const float W = 11.2; // Default: 11.2
	const float exposureBias = 2.0; // Default: 2.0

	const float whitescale = 1.0 / ((W*(A*W+C*B)+D*E)/(W*(A*W+B)+D*F))-E/F;

	color *= exposureBias;
	color = ((color*(A*color+C*B)+D*E)/(color*(A*color+B)+D*F))-E/F;
	color *= whitescale;

	return color;
}

//ACES tonemap
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.1f;
    float c = 3.43f;
    float d = 0.59f;
    float e = 0.21f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

//This belongs to Jodie
vec3 linearToSRGB(vec3 linear){
    return mix(
        linear * 12.92,
        pow(linear, vec3(1./2.4) ) * 1.055 - .055,
        step( .0031308, linear )
    );
}

void ditherScreen(inout vec3 color) {
    vec3 lestynRGB = vec3(dot(vec2(171.0, 231.0), gl_FragCoord.xy));
         lestynRGB = fract(lestynRGB.rgb / vec3(103.0, 71.0, 97.0));

    color += lestynRGB.rgb / 255.0;
}

#define sum2(a) dot(a, vec2(1.0))
#define sum3(a) dot(a, vec3(1.0))
#define sum4(a) dot(a, vec4(1.0))

vec3 adjustSaturation(inout vec3 color, in float saturation)
{
	// Get the brightness.
	float brightness = sum3(color) / 3;

	// Get the chroma
	vec3 chroma = color - brightness;

	// Saturate
	color = (chroma * saturation) + brightness;

	// Get the new brightness;
	float newBrightness = sum3(color) / 3;

	// Subtract the saturated image by the change in brightness, and return.
	color -= brightness - newBrightness;

	return color;
}

#define getLandMask(x) (x < 1.0)

#define Version 0.1

vec3 jodieRoboTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c * inversesqrt( c * c + 1. );
    return mix(c * inversesqrt( l * l + 1. ), tc, tc);
}

vec3 jodieReinhardTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c / ( c + 1. );
    return mix(c / ( l + 1. ), tc, tc);
}

vec3 tonemap(vec3 color) {
    return color * inversesqrt(color * color + 1.0);
}

#include "lib/post/tonemap.glsl"

vec3 LinearTosRGB(in vec3 color)
{
    vec3 x = color * 12.92f;
    vec3 y = 1.055f * pow(saturate(color), vec3(1.0f / 2.4f)) - 0.055f;

    vec3 clr = color;
    clr.r = color.r < 0.0031308f ? x.r : y.r;
    clr.g = color.g < 0.0031308f ? x.g : y.g;
    clr.b = color.b < 0.0031308f ? x.b : y.b;

    return clr;
}

void main() {
	color = texture(colortex0, textureCoordinate);
    float depth = texture(depthtex1, textureCoordinate.st).r;

	float i = Version;

	#if TonemapVersion == 0
    color.rgb = ACESFilm(color.rgb * 0.6);
	#elif TonemapVersion == 1
	color.rgb = tonemapUncharted2(color.rgb);
	#elif TonemapVersion == 2
	color.rgb = jodieReinhardTonemap(color.rgb);
	#endif

	float iamfloat = 1.0;

    //color.rgb = adjustSaturation(color.rgb, iamfloat);

    color.rgb = LinearTosRGB(color.rgb);

	ditherScreen(color.rgb);
}