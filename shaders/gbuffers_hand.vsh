#version 420 compatibility

#define CorrectHandProjection //This makes the projection of the hand correct, this is useful because it gives access to the actual depth of the hand. Turn this off for vanilla hand projection.
//#define HandFovOverride //Overrides the hand FOV.
	#define HandFOV 80.0 //[10.0 20.0 30.0 40.0 50.0 60.0 70.0 80.0 90.0 100.0 110.0 120.0 130.0] 

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

	vec4 viewSpacePosition = gl_ModelViewMatrix * inPosition;

	gl_Position            = (mat3x3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz).xyzz * vec4(gl_ProjectionMatrix[0].x, gl_ProjectionMatrix[1].y, gl_ProjectionMatrix[2].zw) + gl_ProjectionMatrix[3];
}