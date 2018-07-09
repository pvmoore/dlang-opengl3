#version 330 core

in vec3 normal_worldspace;
in vec3 toLight_worldspace;

out vec4 color;

uniform vec3 diffuseColour = vec3(1,1,1);

void main() {
	vec3 unitNormal = normalize(normal_worldspace);
	vec3 unitToLight = normalize(toLight_worldspace);

	float NdotL = dot(unitNormal, unitToLight);
	float brightness = max(NdotL, 0);
	vec3 diffuse = brightness * diffuseColour;

	color = vec4(diffuse, 1);
}