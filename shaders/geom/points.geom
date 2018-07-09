#version 330 core

layout(points) in;
layout(line_strip, max_vertices = 64) out;

in vec4 vColor[];
out vec4 fColor;

//in gl_PerVertex
//{
//   vec4 gl_Position;
//    float gl_PointSize;
//    float gl_ClipDistance[];
//} gl_in[];

const float PI = 3.1415926;

void main() {
	fColor = vColor[0];

	float sides = 40;

    for(int i = 0; i <= sides; i++) {
        // Angle between each side in radians
        float ang = PI * 2.0 / sides * i;

        // Offset from center of point (0.3 to accomodate for aspect ratio)
        vec4 offset = vec4(cos(ang) * 0.3, -sin(ang) * 0.4, 0.0, 0.0);
        gl_Position = gl_in[0].gl_Position + offset;

        EmitVertex();
    }

    EndPrimitive();
}