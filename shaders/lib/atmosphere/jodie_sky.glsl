/* Jodie's Atmosphere */

#define atmosphereHeight 8228. // actual thickness of the atmosphere
#define earthRadius 600e5 // actual radius of the earth
#define mieMultiplier 1.
#define ozoneMultiplier 1. // 1. for physically based
#define rayleighDistribution 8. // physically based
#define mieDistribution 1.8 // physically based
#define sunColor vec3( 1., .899, .828 ) // physically based
#define rayleighCoefficient vec3(5.8e-6  , 1.35e-5 , 3.31e-5 )

#define ozoneCoefficient (vec3(3.426,8.298,.356) * 6e-5 / 100.) // Physically based (Kutz)
#define mieCoefficient ( 3e-6 * mieMultiplier) //good default
#define up gbufferModelView[1].xyz

vec2 js_getThickness2(vec3 rd){
    vec2 sr = earthRadius + vec2(
        atmosphereHeight,
        atmosphereHeight * mieDistribution / rayleighDistribution
    );
    vec3 ro = -up * earthRadius;
    float b = dot(rd, ro);
    float t = b * b - dot(ro, ro);
    return b + sqrt( sr * sr + t );
}

#define getEarth(a) smoothstep(0.,.1,dot(up,a))
// Improved Rayleigh phase for single scattering (Elek)
#define phaseRayleigh(a) ( .4 * (a) + 1.12 )

#define coeffFromDepth(a) ((a).x * (  ozoneCoefficient * ozoneMultiplier + rayleighCoefficient) - 1.11 * (a).y * mieCoefficient)
#define absorb(a) exp( -coeffFromDepth(a) )

//vec3 sunVector  = normalize(sunPosition );

vec2 js_sunThickness = js_getThickness2(sunVector);
vec3 js_sunCoeff = coeffFromDepth(js_sunThickness);
vec3 js_sunAbsorb = exp(-js_sunCoeff);
float js_sunEarthShadow = getEarth(sunVector);


//fixes divide by 0 errors
#define d0fix(a) ( abs(a) + .0000000001 )


// Mie phase (Cornette Shanks)
float phaseg(float x, float g){
    float g2 = g * g;
    float a = -3. * g2 + 3.;
    float b =  2. * g2 + 4.;
    float c = 1. + x * x;
    float d = pow( 1. + g2 - 2. * g * x, 1.5);
    return ( a / b ) * ( c / d );
}

float phaseMie(float VdotL, float depth){
    float g = pow(.75, depth * .0003 );
    return phaseg(VdotL,g)
        +phaseg(VdotL,.999)//sunspot
        ;
}

float phaseMie2(float VdotL, float depth){
    float g = pow(.75, depth * .0003 );
    return phaseg(VdotL,g);
}

vec3 js_sunScatter(vec3 V) {
    vec2 thickness = js_getThickness2(V);
    float VdotL = dot(V, sunVector);
    vec3 viewCoeff = coeffFromDepth(thickness);
    vec3 viewAbsorb = exp(-viewCoeff);

    vec3 rayleighScatter = thickness.x * phaseRayleigh(VdotL)         * rayleighCoefficient;
    float     mieScatter = thickness.y * phaseMie(VdotL, thickness.y) *      mieCoefficient;

    vec3 absorption = d0fix( js_sunAbsorb - viewAbsorb ) / d0fix( js_sunCoeff - viewCoeff );

    return sunColor * (rayleighScatter + mieScatter) * absorption * js_sunEarthShadow;
}

vec3 js_sunAmbient(vec3 V) {
    vec2 thickness = js_getThickness2(V);
    float VdotL = dot(V, sunVector);
    vec3 viewCoeff = coeffFromDepth(thickness);
    vec3 viewAbsorb = exp(-viewCoeff);

    vec3 rayleighScatter = thickness.x * phaseRayleigh(VdotL)          * rayleighCoefficient;
    float     mieScatter = thickness.y * phaseMie2(VdotL, thickness.y) *      mieCoefficient;

    vec3 absorption = d0fix( js_sunAbsorb - viewAbsorb ) / d0fix( js_sunCoeff - viewCoeff );

    return sunColor * (rayleighScatter + mieScatter) * absorption * js_sunEarthShadow * getEarth(V);
}

vec3 js_sunColor() {
    return absorb(js_getThickness2(sunVector)) * getEarth(sunVector);
}


#undef up
#undef atmosphereHeight
#undef earthRadius
#undef mieMultiplier
#undef ozoneMultiplier
#undef rayleighDistribution
#undef mieDistribution
#undef getEarth
#undef phaseRayleigh
#undef rayleighCoefficient
#undef ozoneCoefficient
#undef mieCoefficient
#undef absorb
#undef sunColor
#undef d0fix
