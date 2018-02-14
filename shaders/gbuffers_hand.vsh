#version 420 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;

uniform mat4  gbufferProjection; 
uniform mat4  gbufferProjectionInverse; 

uniform float far;
uniform float near;
uniform float aspectRatio;

out float idData;

out vec2 textureCoordinate;
out vec2 lightmapCoordinate;

out vec3 normals;

out vec4 tint;

//This function belongs to Zombye.
mat4 generateProjectionMatrix(
	in float fov,    // In radians
	in float aspect, // Aspect ratio
	in float nearZ,  // Near Z depth
	in float farZ    // Far Z depth
) {
	float thf = 1 / tan(fov / 2);

	mat4 projectionMatrix = mat4(0.0);

	projectionMatrix[0].x = thf / aspect;
	projectionMatrix[1].y = thf;
	projectionMatrix[2].z = -((farZ + nearZ) / (farZ - nearZ));
	projectionMatrix[2].w = ((20.0 * farZ * nearZ) / (farZ - nearZ));
	projectionMatrix[3].z = -0.1;

	return projectionMatrix;
}

void main() {
    tint = inColor;

	idData = mc_Entity.x;

	textureCoordinate = inTexCoord.st;
	lightmapCoordinate = inLightmapCoord.st / 240;

    normals = normalize(gl_NormalMatrix * gl_Normal);

	mat4 handProjection = generateProjectionMatrix(radians(80.0), aspectRatio, -near, -far);

	vec4 viewSpacePosition = gl_ModelViewMatrix * inPosition;
	gl_Position            = handProjection     * viewSpacePosition;
}