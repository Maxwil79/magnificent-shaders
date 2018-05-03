//Defines 
#define SaturationAmount 0.35 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define BleachAmount 0.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define ContrastAmount 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define FilmicStrength 0.9 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define FadeAmount 0.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define LinearizationAmount 0.75 //[0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define CurveAmount 0.05 //[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define BaseGammaAmount 1.6 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define EffectGammaAmount 1.5 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

//Tonemaps
const float Exposure = 0.75;    
const float Gamma = 1.00;  

//Filmic Pass
const float Filmic_Contrast = ContrastAmount;
const float Filmic_Bleach = BleachAmount;                       // More bleach means more contrasted and less colorful image
const float Saturation = -SaturationAmount;

const float Filmic_Strength = FilmicStrength;                    // Strength of the color curve altering
const float Fade = FadeAmount;                                // Decreases contrast to imitate faded image
const float Linearization = LinearizationAmount;              
const float BaseCurve = CurveAmount;
const float BaseGamma = BaseGammaAmount;
const float EffectGamma = EffectGammaAmount;