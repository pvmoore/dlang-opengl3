#version 330 core

in vec3 normal_worldspace;
in vec3 toLight_worldspace;
in vec3 toCamera_worldspace;

out vec4 color;

uniform float shineDamping  = 10;
uniform float reflectivity  = 1;
uniform vec3 diffuseColour  = vec3(1, 1, 1);
uniform vec3 specularColour = vec3(1, 1, 1);

void main() {
	vec3 unitNormal = normalize(normal_worldspace);
	vec3 unitToLight = normalize(toLight_worldspace);
	vec3 unitToCamera = normalize(toCamera_worldspace);

	vec3 lightDirection			 = -unitToLight;
	vec3 reflectedLightDirection = reflect(lightDirection, unitNormal);

	vec3 ambient = vec3(0.0, 0.0, 0.0);

	float specularFactor = max(dot(reflectedLightDirection, unitToCamera), 0);
	float dampingFactor = pow(specularFactor, shineDamping);
	vec3 specular = dampingFactor * reflectivity * specularColour;

	float NdotL = dot(unitNormal, unitToLight);
	float brightness = max(NdotL, 0);
	vec3 diffuse = brightness * diffuseColour;

	color = vec4(ambient + diffuse + specular, 1);
}