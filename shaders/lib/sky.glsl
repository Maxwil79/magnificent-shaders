#define fstep(a, b) clamp(((b)-(a))*1e35, 0., 1.)

vec2 rsi(vec3 r0, vec3 rd, float sr) {
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, r0);
    float c = dot(r0, r0) - (sr * sr);
    float d = (b*b) - 4.0*a*c;
    if (d < 0.0) return vec2(1e5,-1e5);
    return vec2(
        (-b - sqrt(d))/(2.0*a),
        (-b + sqrt(d))/(2.0*a)
    );
}

vec3 atmosphere(vec3 r, vec3 r0, vec3 pSun, float iSun, float rPlanet, float rAtmos, vec3 kRlh, float kMie, float shRlh, float shMie, float g, in vec3 pMoon, in int iSteps, in int jSteps, in vec3 kOzo, in float shOzo) {
    pSun = normalize(pSun);
    pMoon = normalize(pMoon);
    r = normalize(r);

    vec3 sunColor = iSun * blackbody(5778);
    float iMoon = moonIlluminance;
    vec3 moonColor = iMoon * blackbody(5778);

    vec2 p = rsi(r0, r, rAtmos);
    if (p.x > p.y) return vec3(0,0,0);
    p.y = min(p.y, rsi(r0, r, rPlanet).x);
    float iStepSize = (p.y - p.x) / float(iSteps);

    float iTime = 0.0;

    vec3 totalRlh = vec3(0,0,0);
    vec3 totalOzo = vec3(0,0,0);
    vec3 totalMie = vec3(0,0,0);

    float iOdRlh = 0.0;
    float iOdOzo = 0.0;
    float iOdMie = 0.0;

    float mu = dot(r, lightVector);
    float ozoMu = dot(mat3(gbufferModelViewInverse) * upVector, lightVector);
    float sunMu = dot(r, pSun);
    float moonMu = dot(r, pMoon);
    float mumu = mu * mu;
    float ozoMuMu = ozoMu*ozoMu;
    float gg = g * g;
    float pRlh = 3.0 / (16.0 * PI) * (1.0 + mumu);
    float pOzo = 3.0 / (16.0 * PI) * (1.0 - ozoMuMu);
    float pMie = clamp(3.0 / (8.0 * PI) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * g, 1.5) * (2.0 + gg)), 0.0, 10.0) * 4.0;

    for (int i = 0; i < iSteps; i++) {

        float odStepRlh = 0.0;
        float odStepMie = 0.0;

        {
            vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

            float iHeight = length(iPos) - rPlanet;

            odStepRlh = exp(-max(iHeight, 0.0) / shRlh) * iStepSize;
            odStepMie = exp(-max(iHeight, 0.0) / shMie) * iStepSize;

            iOdRlh += odStepRlh;
            iOdMie += odStepMie;

            float jTime = 0.0;

            float jOdRlh = 0.0;
            float jOdMie = 0.0;

            float jStepSize = rsi(iPos, pSun, rAtmos).y / float(jSteps);

            for (int j = 0; j < jSteps; j++) {

                vec3 jPos = iPos + pSun * (jTime + jStepSize * 0.5);

                float jHeight = length(jPos) - rPlanet;

                jOdRlh += exp(-max(jHeight, 0.0) / shRlh) * jStepSize;
                jOdMie += exp(-max(jHeight, 0.0) / shMie) * jStepSize;

                jTime += jStepSize;
            }            

            vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

            totalRlh += odStepRlh * attn * sunColor;
            totalMie += odStepMie * attn * sunColor;
        }

        {
            vec3 iPos = r0 + r * (iTime + iStepSize * 0.5);

            float iHeight = length(iPos) - rPlanet;

            odStepRlh = exp(-max(iHeight, 0.0) / shRlh) * iStepSize;
            odStepMie = exp(-max(iHeight, 0.0) / shMie) * iStepSize;

            iOdRlh += odStepRlh;
            iOdMie += odStepMie;

            float jTime = 0.0;

            float jOdRlh = 0.0;
            float jOdMie = 0.0;

            float jStepSize = rsi(iPos, pMoon, rAtmos).y / float(jSteps);

            for (int j = 0; j < jSteps; j++) {

                vec3 jPos = iPos + pMoon * (jTime + jStepSize * 0.5);

                float jHeight = length(jPos) - rPlanet;

                jOdRlh += exp(-max(jHeight, 0.0) / shRlh) * jStepSize;
                jOdMie += exp(-max(jHeight, 0.0) / shMie) * jStepSize;

                jTime += jStepSize;
            }

            vec3 attn = exp(-(kMie * (iOdMie + jOdMie) + kRlh * (iOdRlh + jOdRlh)));

            totalRlh += odStepRlh * attn * moonColor;
            totalMie += odStepMie * attn * moonColor;
        }

        iTime += iStepSize;

    }

    return ((pRlh * kRlh * totalRlh + pOzo * kOzo * totalOzo) + pMie * kMie * totalMie) * blackbody(5778);
}