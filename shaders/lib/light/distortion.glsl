float length2(vec2 x){return dot(x,x);}

float ShadowDistortion(in vec2 pos){
float dist = sqrt(pos.x * pos.x + pos.y * pos.y);
float distort = (1.0f - 0.92) + dist * 0.92 + 0.0;

return distort;
}