#version 420

layout (location = 0) in vec2 inPosition;
layout (location = 8) in vec2 inTexCoord;

out vec2 textureCoordinate;

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

void main() {
    gl_Position = vec4(signed(inPosition), 0.0, 1.0);

    textureCoordinate = inTexCoord;
}