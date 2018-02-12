float length2(vec2 x){return dot(x,x);}

float ShadowDistortion(in vec2 pos){
float distort = 0.0;
distort = length(pos.xy) * 0.9 + (1.0 - 0.9);

return distort;
}