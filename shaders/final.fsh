#version 420

#define TonemapVersion 0 //[0 1] 0 = Zombye's tonemap. 1 = Uncharted 2 tonemap.

layout (location = 0) out vec4 color;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

in vec2 textureCoordinate;

// Tonemapping operator used in Uncharted 2.
// Source: http://filmicgames.com/archives/75
vec3 tonemapUncharted2(
	inout vec3 color
) {
	const float A = 0.15; // Default: 0.15
	const float B = 0.50; // Default: 0.50
	const float C = 0.10; // Default: 0.10
	const float D = 0.20; // Default: 0.20
	const float E = 0.01; // Default: 0.02
	const float F = 0.30; // Default: 0.30
	const float W = 11.2; // Default: 11.2
	const float exposureBias = 2.0; // Default: 2.0

	const float whitescale = 1.0 / ((W*(A*W+C*B)+D*E)/(W*(A*W+B)+D*F))-E/F;

	color *= exposureBias;
	color = ((color*(A*color+C*B)+D*E)/(color*(A*color+B)+D*F))-E/F;
	color *= whitescale;

	return color;
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

vec3 Uncharted2Tonemap(vec3 x)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
    return x*((vec3(A+C+B)+D+E)/(vec3(A+B)+D*F))-E/F;
}

vec3 jodieRoboTonemap(vec3 c){
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c * inversesqrt( c * c + 1. );
    return mix(c * inversesqrt( l * l + 1. ), tc, tc);
}

vec4 ps_main()
{
     vec3 texColor = texture(colortex0, textureCoordinate.st).rgb;
     //texColor = vec3(16);  // Hardcoded Exposure Adjustment
     float ExposureBias = 2.0f;
     vec3 curr = Uncharted2Tonemap(texColor);
     vec3 whiteScale = 1.0f/Uncharted2Tonemap(texColor);
     vec3 color = curr*whiteScale;
     vec3 retColor = pow(color,vec3(1/2.2));
     return vec4(retColor,1);
}

vec3 tonemap(vec3 color) {
    return color * inversesqrt(color * color + 1.0);
}

void main() {
    color = texture(colortex0, textureCoordinate.st);
    float depth = texture(depthtex1, textureCoordinate.st).r;

	float i = Version;

	#if TonemapVersion == 0
    color.rgb = jodieRoboTonemap(color.rgb);
	#elif TonemapVersion == 1
	color.rgb = tonemapUncharted2(color.rgb);
	#endif

	float iamfloat = 1.0;

    color.rgb = adjustSaturation(color.rgb, iamfloat);

    color.rgb = linearToSRGB(color.rgb);

	ditherScreen(color.rgb);
}