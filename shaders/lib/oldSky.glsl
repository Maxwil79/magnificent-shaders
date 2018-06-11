// Code originally from https://www.shadertoy.com/view/XsjyWz

#define FastSky 0 //[0 1] When disbled, this drasticly lowers FPS. I recommend keeping this Enabled.

#define MIN_WL 380.0
#define WL_STEP 5.0
#define MAX_WL 780.0

#define MIN_TEMP 800.0
#define MAX_TEMP 12000.0

#define SPECTRUM_SAMPLES 81

#define inScatteringSamples 32
#define outScatteringSamples 16
#define atmosphereHeight (100e+3)
#define height (0.0)
#define Re (6371e+3)
#define Ra (Re + atmosphereHeight) 
#define H0r (8.0e+3)
#define H0m (2.6e3)
#define H0o (7.0e3)

vec3 positionOnPlanet(in float y){
     return vec3(0.0, Re + y, 0.0);
}

#if FastSky == 0
float exposure = 5.0e-15;
#elif FastSky == 1
float exposure = 10e-15;
#endif

const vec3 cie[SPECTRUM_SAMPLES] = vec3[](
    vec3(0.0014, 0.0000, 0.0065), vec3(0.0022, 0.0001, 0.0105), vec3(0.0042, 0.0001, 0.0201),
    vec3(0.0076, 0.0002, 0.0362), vec3(0.0143, 0.0004, 0.0679), vec3(0.0232, 0.0006, 0.1102),
    vec3(0.0435, 0.0012, 0.2074), vec3(0.0776, 0.0022, 0.3713), vec3(0.1344, 0.0040, 0.6456),
    vec3(0.2148, 0.0073, 1.0391), vec3(0.2839, 0.0116, 1.3856), vec3(0.3285, 0.0168, 1.6230),
    vec3(0.3483, 0.0230, 1.7471), vec3(0.3481, 0.0298, 1.7826), vec3(0.3362, 0.0380, 1.7721),
    vec3(0.3187, 0.0480, 1.7441), vec3(0.2908, 0.0600, 1.6692), vec3(0.2511, 0.0739, 1.5281),
    vec3(0.1954, 0.0910, 1.2876), vec3(0.1421, 0.1126, 1.0419), vec3(0.0956, 0.1390, 0.8130),
    vec3(0.0580, 0.1693, 0.6162), vec3(0.0320, 0.2080, 0.4652), vec3(0.0147, 0.2586, 0.3533),
    vec3(0.0049, 0.3230, 0.2720), vec3(0.0024, 0.4073, 0.2123), vec3(0.0093, 0.5030, 0.1582),
    vec3(0.0291, 0.6082, 0.1117), vec3(0.0633, 0.7100, 0.0782), vec3(0.1096, 0.7932, 0.0573),
    vec3(0.1655, 0.8620, 0.0422), vec3(0.2257, 0.9149, 0.0298), vec3(0.2904, 0.9540, 0.0203),
    vec3(0.3597, 0.9803, 0.0134), vec3(0.4334, 0.9950, 0.0087), vec3(0.5121, 1.0000, 0.0057),
    vec3(0.5945, 0.9950, 0.0039), vec3(0.6784, 0.9786, 0.0027), vec3(0.7621, 0.9520, 0.0021),
    vec3(0.8425, 0.9154, 0.0018), vec3(0.9163, 0.8700, 0.0017), vec3(0.9786, 0.8163, 0.0014),
    vec3(1.0263, 0.7570, 0.0011), vec3(1.0567, 0.6949, 0.0010), vec3(1.0622, 0.6310, 0.0008),
    vec3(1.0456, 0.5668, 0.0006), vec3(1.0026, 0.5030, 0.0003), vec3(0.9384, 0.4412, 0.0002),
    vec3(0.8544, 0.3810, 0.0002), vec3(0.7514, 0.3210, 0.0001), vec3(0.6424, 0.2650, 0.0000),
    vec3(0.5419, 0.2170, 0.0000), vec3(0.4479, 0.1750, 0.0000), vec3(0.3608, 0.1382, 0.0000),
    vec3(0.2835, 0.1070, 0.0000), vec3(0.2187, 0.0816, 0.0000), vec3(0.1649, 0.0610, 0.0000),
    vec3(0.1212, 0.0446, 0.0000), vec3(0.0874, 0.0320, 0.0000), vec3(0.0636, 0.0232, 0.0000),
    vec3(0.0468, 0.0170, 0.0000), vec3(0.0329, 0.0119, 0.0000), vec3(0.0227, 0.0082, 0.0000),
    vec3(0.0158, 0.0057, 0.0000), vec3(0.0114, 0.0041, 0.0000), vec3(0.0081, 0.0029, 0.0000),
    vec3(0.0058, 0.0021, 0.0000), vec3(0.0041, 0.0015, 0.0000), vec3(0.0029, 0.0010, 0.0000),
    vec3(0.0020, 0.0007, 0.0000), vec3(0.0014, 0.0005, 0.0000), vec3(0.0010, 0.0004, 0.0000),
    vec3(0.0007, 0.0002, 0.0000), vec3(0.0005, 0.0002, 0.0000), vec3(0.0003, 0.0001, 0.0000),
    vec3(0.0002, 0.0001, 0.0000), vec3(0.0002, 0.0001, 0.0000), vec3(0.0001, 0.0000, 0.0000),
    vec3(0.0001, 0.0000, 0.0000), vec3(0.0001, 0.0000, 0.0000), vec3(0.0000, 0.0000, 0.0000));

const mat3 xyz_to_rgb_matrix = mat3(
	3.240479, -1.537150, -0.498535,
    -0.969256, 1.875992, 0.041556,
    0.055648, -0.204043, 1.057311);

vec3 spectrum_to_xyz(in float w)
{
    w = clamp(w, MIN_WL, MAX_WL) - MIN_WL;
    float n = floor(w / WL_STEP);
    int n0 = min(SPECTRUM_SAMPLES - 1, int(n));
    int n1 = min(SPECTRUM_SAMPLES - 1, n0 + 1);
    float t = w - (n * WL_STEP);
    return mix(cie[n0], cie[n1], t / WL_STEP);
}

vec3 xyz_to_rgb(in vec3 xyz)
{
    return xyz * xyz_to_rgb_matrix;
}

float black_body_radiation_s(in float temperature, in float wavelength)
{
    float e = exp(1.4387752e+7 / (temperature * wavelength));
    return 3.74177e+29 / (pow(wavelength, 5.0) * (e - 1.0));
}

vec4 black_body_radiation(in float t, in vec4 w)
{
    return vec4(
        black_body_radiation_s(t, w.x), 
        black_body_radiation_s(t, w.y), 
        black_body_radiation_s(t, w.z),
        black_body_radiation_s(t, w.w));
}

float atmosphereIntersection(in vec3 origin, in vec3 direction)
{
    float b = dot(direction, origin);
    float d = b * b - dot(origin, origin) + Ra * Ra;
    return (d >= 0.0) ? (-b + sqrt(d)) : 0.0;
}

float planetIntersection(in vec3 origin, in vec3 direction)
{
    float b = dot(direction, origin);
    float d = b * b - dot(origin, origin) + Re * Re;
    return (d >= 0.0) ? (-b - sqrt(d)) : 0.0;
}

vec2 density(in vec3 pos)
{
    float h = max(0.0, length(pos) - Re);
    return vec2(exp(-h / H0r), exp(-h / H0m));
}

float ozoneDensity(in vec3 pos)
{
    float h = max(0.0, length(pos) - Re);
    return exp(-h / H0o);
}

vec2 opticalDensity(in vec3 from, in vec3 to, in int samples)
{
    vec3 dp = (to - from) / float(samples);

    vec2 result = vec2(0.0);
    for (int i = 0; i < samples; ++i)
    {
        result += density(from);
        from += dp;
    }
    return result * length(dp);
}

vec4 in_scattering(in vec3 target, in vec3 sun, in vec3 moon, in vec2 phase, in vec4 betaR, in vec4 betaM, in vec3 position, in int samples1, in int samples2)
{
    vec3 posStep = (target - position) / float(samples1);
    float ds = length(posStep);

    vec4 resultR = vec4(0.0);
    vec4 resultM = vec4(0.0);
    vec3 pos = position;
    vec2 opticalDepthToCamera = vec2(0.0);
    for (int i = 0; i < samples1; ++i)
    {
        vec2 d = density(pos);

        {
            vec2 opticalDepthToLight = opticalDensity(pos, pos + sun * atmosphereIntersection(pos, sun), samples2);
        
            vec4 transmittance = exp(-betaR * (opticalDepthToCamera.x + opticalDepthToLight.x) - betaM * (opticalDepthToCamera.y + opticalDepthToLight.y));
            resultR += d.x * transmittance * sunIlluminance;
            resultM += d.y * transmittance * sunIlluminance;
        }
    
        {
            vec2 opticalDepthToLight = opticalDensity(pos, pos + moon * atmosphereIntersection(pos, moon), samples2);
        
            vec4 transmittance = exp(-betaR * (opticalDepthToCamera.x + opticalDepthToLight.x) - betaM * (opticalDepthToCamera.y + opticalDepthToLight.y));
            resultR += d.x * transmittance * moonIlluminance;
            resultM += d.y * transmittance * moonIlluminance;
        }
        
        opticalDepthToCamera += d * ds;
        pos += posStep;
    }
    
    return (resultR * betaR * phase.x + resultM * betaM * phase.y) * (ds / (4.0 * PI));
}

vec3 fromSpherical(in float phi, in float theta)
{
    return vec3(cos(phi) * cos(theta), sin(theta), sin(phi) * cos(theta));
}

vec4 betaR(in vec4 wl)
{
    wl /= 100.0;
    vec4 wl2 = wl * wl;
    return vec4(0.012) / (wl2 * wl2);
}

vec4 betaM(in vec4 wl)
{
    wl /= 100.0;
    return vec4(2.913e-4) / (wl * wl);
}

vec3 ozoneAbsorption(){
    return vec3(0.0);
}

void atmosphereResult (inout vec4 color, in vec2 coord, in vec3 view, in int samples1, in int samples2) 
{
    float u = coord.x / screenRes.x;
    float v = coord.y / screenRes.y;

    vec3 sun = sunVector.xyz;
    vec3 moon = moonVector.xyz;
    vec3 dir = view.xyz;
    float a = atmosphereIntersection(positionOnPlanet(cameraPosition.y), dir);
    vec3 target = positionOnPlanet(cameraPosition.y) + a * dir;
    
    float cosTheta = dot(dir, mix(moon, sun, float(sunAngle < 0.5)));
    vec2 phase = vec2(phaseFunctionRayleigh(cosTheta), phaseFunctionMie(cosTheta, mieG) * 8.0);

#if (FastSky)
	vec3 xyz = vec3(0.0);
    {
        vec4 wl = vec4(623.0, 540.0, 450.0, 0.0) + vec4(3.426, 8.298, .356, 0.0);
        vec4 radiation = black_body_radiation(5778.0, wl);
		vec4 s = radiation * in_scattering(target, sun, moon, phase, betaR(wl), betaM(wl), positionOnPlanet(cameraPosition.y), samples1, samples2);
        xyz += s.x * spectrum_to_xyz(wl.x);
        xyz += s.y * spectrum_to_xyz(wl.y);
        xyz += s.z * spectrum_to_xyz(wl.z);
    }    
#else
    vec4 w[4] = vec4[](
        vec4(400.0, 425.0, 450.0, 475.0), 
        vec4(500.0, 525.0, 550.0, 575.0),
        vec4(600.0, 625.0, 650.0, 675.0),
        vec4(700.0, 725.0, 750.0, 775.0));
    
	vec3 xyz = vec3(0.0);
    for (int i = 0; i < 4; ++i)
    {
        vec4 wl = w[i];
        vec4 radiation = black_body_radiation(5778.0, wl);
		vec4 s = radiation * in_scattering(target, sun, moon, phase, betaR(wl), betaM(wl), positionOnPlanet(cameraPosition.y), samples1, samples2);
        xyz += s.x * spectrum_to_xyz(wl.x);
        xyz += s.y * spectrum_to_xyz(wl.y);
        xyz += s.z * spectrum_to_xyz(wl.z);
        xyz += s.w * spectrum_to_xyz(wl.w);
    }
#endif

    vec3 result = xyz_to_rgb(xyz);
    //result += ozoneAbsorption();

    color = vec4(result * exposure, 1.0);
}

void useAtmosphereAmbient(inout vec4 color, in vec3 upVec, in int samples1, in int samples2){
    atmosphereResult(color, gl_FragCoord.st, upVec, samples1, samples2);
}

void useAtmosphereDirect(inout vec4 color, in vec3 lightVec, in int samples1, in int samples2){
    atmosphereResult(color, gl_FragCoord.st, lightVec, samples1, samples2);
}