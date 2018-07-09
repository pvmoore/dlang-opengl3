#version 330 core

layout(location = 0) in vec2 vertexPosition_modelspace;
layout(location = 1) in vec4 vertexColor;

out vec4 vColor;

uniform mat4 MVP;

void main() {	
	gl_Position		= MVP * vec4(vertexPosition_modelspace, 0, 1);
	vColor			= vertexColor;
}