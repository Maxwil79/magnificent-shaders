#version 420 compatibility

layout (location = 0) in vec4 inPosition;
layout (location = 2) in vec4 inNormal;
layout (location = 3) in vec4 inColor;
layout (location = 8) in vec4 inTexCoord;
layout (location = 9) in vec4 inLightmapCoord;
layout (location = 10) in vec4 mc_Entity;
layout (location = 11) in vec2 quadMidUV;

uniform mat4  gbufferProjection; 

uniform float frameTimeCounter;

out float idData;

out vec2 textureCoordinate;
out vec2 lightmapCoordinate;

out vec3 normals;

out vec4 tint;

void main() {
    tint = inColor;

	vec4 v = inPosition;
	float speed = 0.5;
	float t = frameTimeCounter * speed;
	float waveHeight = 0.5;
	float waveWidth = 10.5;
	
	if(mc_Entity.x == 31.0 || mc_Entity.x == 37.0 || mc_Entity.x == 38.0 && inTexCoord.y < quadMidUV.y) v.zyx += (
	    // Add some offset to the waves to make it slightly less regular
	    sin(waveWidth * inPosition.x + t * 1.3) *
	    cos(waveWidth * inPosition.y + t * 0.9) * waveHeight
    ) + (
        // Extra waves to add interest
	    cos(waveWidth * 2.0 * inPosition.x + t * -.3) *
	    sin(waveWidth * 4.0 * inPosition.y + t * 3.9) * ( waveHeight / 2.5 )
    );

	idData = mc_Entity.x;

	textureCoordinate = inTexCoord.st;
	lightmapCoordinate = inLightmapCoord.st / 240;
    
    normals = normalize(gl_NormalMatrix * gl_Normal);

    gl_Position = gbufferProjection * (gl_ModelViewMatrix * inPosition);
}