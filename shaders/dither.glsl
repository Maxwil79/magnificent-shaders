float hash12(vec2 p){
    p  = fract(p * .1031);
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

float dither=hash12(textureCoordinate*vec2(viewWidth*viewWidth,viewHeight*viewHeight)+vec2(frameTimeCounter * 90.0, frameTimeCounter * 50.0));
float dither2=hash12(textureCoordinate*vec2(viewWidth,viewHeight));

float noise = fract(sin(dot(textureCoordinate.xy, vec2(18.9898f, 28.633f))) * 4378.5453f) * 4.0 / 5.0;
mat2 noiseM = mat2(cos(noise), -sin(noise),
						   sin(noise), cos(noise));

mat2 rot = noiseM;
