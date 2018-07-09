#version 330 core

in vec4 fragmentColor;
in vec2 UV;

out vec4 color;

uniform sampler2D textureSampler0;

void main() {
	color = texture(textureSampler0, UV) * fragmentColor;
}
