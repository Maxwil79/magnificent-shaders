#version 120

varying vec2 uvcoord;
varying float isWater;

uniform sampler2D tex;

void main() {
    gl_FragData[0] = texture2D(tex, uvcoord);

    if(isWater == 1.0) gl_FragData[0] = vec4(1.0);

}