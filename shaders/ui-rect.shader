//---------------------------------------------------------------------------
//VERTEXSHADER
//---------------------------------------------------------------------------
#version 330 core
layout(location = 0) in vec4 pos_size;
layout(location = 1) in vec4 colour;

out VS_OUT {
	vec2 pos;
	vec2 size;
	vec4 colour;
} vs_out;

void main() {
	vs_out.pos    = pos_size.xy;
	vs_out.size   = pos_size.zw;
	vs_out.colour = colour;
}
//---------------------------------------------------------------------------
//GEOMETRYSHADER
//---------------------------------------------------------------------------
#version 330 core
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

uniform mat4 VP;
uniform vec2 POS;
uniform vec2 SIZE;

in VS_OUT {
	vec2 pos;
	vec2 size;
	vec4 colour;
} gs_in[];

out GS_OUT {
    vec2 pos;
    vec2 size;
	vec4 colour;
} gs_out;

void main() {
    float x = gs_in[0].pos.x;
    float y = gs_in[0].pos.y;
    float w = gs_in[0].size.x;
    float h = gs_in[0].size.y;

    // top left
	gl_Position   = VP * vec4(x,y, 0, 1);
	gs_out.pos    = vec2(0,0);
	gs_out.size   = gs_in[0].size;
	gs_out.colour = gs_in[0].colour;
	EmitVertex();

    // top right
	gl_Position   = VP * vec4(x+w,y, 0, 1);
	gs_out.pos    = vec2(w,0);
	gs_out.size   = gs_in[0].size;
	gs_out.colour = gs_in[0].colour;
	EmitVertex();

    // bottom left
	gl_Position   = VP * vec4(x,y+h, 0, 1);
	gs_out.pos    = vec2(0,h);
	gs_out.size   = gs_in[0].size;
	gs_out.colour = gs_in[0].colour;
	EmitVertex();

    // bottom right
	gl_Position   = VP * vec4(x+w,y+h, 0, 1);
	gs_out.pos    = vec2(w,h);
	gs_out.size   = gs_in[0].size;
	gs_out.colour = gs_in[0].colour;
	EmitVertex();

	EndPrimitive();
}

//---------------------------------------------------------------------------
//FRAGMENTSHADER
//---------------------------------------------------------------------------
#version 330 core
out vec4 color;

in GS_OUT {
    vec2 pos;       // relative to (0,0)
    vec2 size;
	vec4 colour;
} fs_in;

uniform float CORNER_RADIUS = 10;

void main() {
    vec2 pos  = fs_in.pos;
    vec2 size = fs_in.size;
    vec2 mid  = size/2;

	vec2 top = vec2(CORNER_RADIUS, CORNER_RADIUS);

    if(pos.x>mid.x) {
        pos.x = size.x-pos.x;
    }
    if(pos.y>mid.y) {
        pos.y = size.y-pos.y;
    }

	float d = distance(pos, top);

	if(pos.x<CORNER_RADIUS &&
	   pos.y<CORNER_RADIUS &&
	   d>CORNER_RADIUS)
    {
	    // we are in a corner
	    discard;
	} else {
	    float y = 1;
	    if(fs_in.pos.y<=6) {
	        y = 1.25 - (fs_in.pos.y/6)*0.25;
	    } else if(fs_in.pos.y>=size.y-6) {
	        y = 0.75 + ((size.y-fs_in.pos.y)/6)*0.25;
	    }

        color = fs_in.colour * y;
    }
}