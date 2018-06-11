#version 400

layout (location = 0) in vec4 inPosition;

out vec2 texcoord;

// Signed normalized to/from unsigned normalized
#define signed(a) ((a * 2.0) - 1.0)
#define unsigned(a) ((a * 0.5) + 0.5)

void main() {
    gl_Position = inPosition * 2.0 - 1.0;

    texcoord = inPosition.xy;
}