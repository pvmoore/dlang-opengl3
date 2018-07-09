#version 330 core
//VERTEX SHADER

layout(location = 0) in vec3 vertexPosition_modelspace;
layout(location = 1) in vec3 vertexNormal_modelspace;

out vec3 normal_worldspace;
out vec3 toLight_worldspace;

uniform mat4 MVP;
uniform mat4 V;
uniform mat4 M;
uniform vec3 LightPosition_worldspace;

void main() {
	gl_Position = MVP * vec4(vertexPosition_modelspace, 1);

	vec4 position_worldspace = M * vec4(vertexPosition_modelspace, 1);

	normal_worldspace = (M*vec4(vertexNormal_modelspace, 0)).xyz;

	toLight_worldspace = LightPosition_worldspace - position_worldspace.xyz;
}

