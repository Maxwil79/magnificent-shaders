float ShadowDistortion(in vec2 pos){
float dist = sqrt(pos.x * pos.x + pos.y * pos.y);
float distort = (1.0f - 0.9) + dist * 0.9 + 0.0;

return distort;
}