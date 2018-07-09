module gl.renderers.circlerenderer;

import gl.all;

final struct CircleData { 
	Vector2 centre;
	float radius;
	float edgeThickness = 0;
	RGBA fillColour;		// if alpha channel == 0 then there is no fill
	RGBA edgeColour;		// if(edgeThickness == 0) then there is no edge
}

final class CircleRenderer : Renderer {
	CircleData[] points;

	this(OpenGL gl) {
		super(gl);
	}
	auto clearCircles() {
		this.points.length = 0;
		dataChanged = true;
		return this;
	}
	auto withCircles(CircleData[] points...) {
		this.points = points;
		dataChanged = true;
		return this;
	}
	auto updateCirclePos(int index, Vector2 pos) {
		points[index].centre = pos;
		dataChanged = true;
		return this;
	}
	auto addOutlined(Vector2 pos, float radius, RGBA colour, float thickness=1) {
		return addCircles(CircleData(
			pos, radius, thickness, RGBA_NONE, colour)
		);
	}
	auto addFilled(Vector2 pos, float radius, RGBA colour) {
		return addCircles(CircleData(	
			pos, radius, 0, colour, RGBA_NONE)
		);
	}
	auto addFilledOutlined(Vector2 pos, float radius, RGBA fillColour, RGBA edgeColour, float thickness=1) {
		return addCircles(CircleData(	
			pos, radius, thickness, fillColour, edgeColour)
		);
	}	
	auto addCircles(CircleData[] points...) {
		this.points ~= points;
		dataChanged = true;
		return this;
	}
protected:
	@property override ulong numPoints() { return points.length; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("CircleRenderer-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("CircleRenderer-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("CircleRenderer-fs", fs, GL_FRAGMENT_SHADER)
		);
	}
	override void populateVbo() {
		if(!dataChanged) return;

		const int ELEMENT_SIZE = Vector4.sizeof * 3;

		long bytesRequired = points.length*ELEMENT_SIZE;

		// alloc and bind the VBO
		if(vbo is null) {
			vbo = VBO.array(bytesRequired, GL_STREAM_DRAW);
			buf.length = bytesRequired;
		} else if(bytesRequired > vbo.sizeBytes) {
			vbo.bind();
			vbo.realloc(bytesRequired, GL_STREAM_DRAW);
			buf.length = bytesRequired;
		} else {
			vbo.bind();
		}

		ubyte* ptr = buf.ptr;
		foreach(p; points) {
			*(cast(Vector4*)ptr) = Vector4(p.centre, p.radius, p.edgeThickness); 
			ptr += Vector4.sizeof;

			*(cast(Vector4*)ptr) = p.fillColour;
			ptr += Vector4.sizeof;

			*(cast(Vector4*)ptr) = p.edgeColour;
			ptr += Vector4.sizeof;
		}
		vbo.addData(buf[0..bytesRequired]);
		vao.enableAttrib(0, 4, GL_FLOAT, false, ELEMENT_SIZE, 0);
		vao.enableAttrib(1, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof);
		vao.enableAttrib(2, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof*2);

		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec4 posRadiusThickness;	// xy, radius, edgeThickness
		layout(location = 1) in vec4 fillColour;
		layout(location = 2) in vec4 edgeColour;				

		out VS_OUT {
			vec2 pos;
			vec4 fillColour;
			vec4 edgeColour;
			float radius;
			float edgeThickness;
		} vs_out;

		void main() {	 
			vs_out.pos			 = posRadiusThickness.xy;
			vs_out.fillColour	 = fillColour;
			vs_out.edgeColour	 = edgeColour;
			vs_out.radius		 = posRadiusThickness.z;
			vs_out.edgeThickness = posRadiusThickness.w;
		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(triangle_strip, max_vertices = 4) out;

		uniform mat4 VP;

		in VS_OUT {
			vec2 pos;
			vec4 fillColour;
			vec4 edgeColour;
			float radius;
			float edgeThickness;
		} gs_in[];

		out GS_OUT {
			vec2 pos;
			vec4 fillColour;
			vec4 edgeColour;
			float radius;
			float edgeThickness;
		} gs_out;

		void main() {
			vec2 pp = gs_in[0].pos;

			float r		 = gs_in[0].radius + (gs_in[0].edgeThickness*0.501); 
			vec4 pos0    = vec4(pp-r, 0, 1);
			vec4 pos2    = vec4(pp+r, 0, 1);
			vec4 pos1    = vec4(pp.x-r, pp.y+r, 0, 1);
			vec4 pos3    = vec4(pp.x+r, pp.y-r, 0, 1);

			gl_Position		     = VP * pos0;
			gs_out.pos		     = pos0.xy-pp;
			gs_out.fillColour    = gs_in[0].fillColour;
			gs_out.edgeColour    = gs_in[0].edgeColour;
			gs_out.radius	     = gs_in[0].radius;
			gs_out.edgeThickness = gs_in[0].edgeThickness;
			EmitVertex();

			gl_Position			 = VP * pos1;
			gs_out.pos			 = pos1.xy-pp;
			gs_out.fillColour    = gs_in[0].fillColour;
			gs_out.edgeColour    = gs_in[0].edgeColour;
			gs_out.radius	     = gs_in[0].radius;
			gs_out.edgeThickness = gs_in[0].edgeThickness;
			EmitVertex();

			gl_Position			 = VP * pos3;
			gs_out.pos			 = pos3.xy-pp;
			gs_out.fillColour    = gs_in[0].fillColour;
			gs_out.edgeColour    = gs_in[0].edgeColour;
			gs_out.radius	     = gs_in[0].radius;
			gs_out.edgeThickness = gs_in[0].edgeThickness;
			EmitVertex();

			gl_Position			 = VP * pos2;
			gs_out.pos			 = pos2.xy-pp;
			gs_out.fillColour    = gs_in[0].fillColour;
			gs_out.edgeColour    = gs_in[0].edgeColour;
			gs_out.radius	     = gs_in[0].radius;
			gs_out.edgeThickness = gs_in[0].edgeThickness;
			EmitVertex();

			EndPrimitive();
		}";
	string fs = "#version 330 core
		out vec4 color;

		in GS_OUT {
			vec2 pos;
			vec4 fillColour;
			vec4 edgeColour;
			float radius;
			float edgeThickness;
		} fs_in;

		void main() {
			float dist = length(fs_in.pos);
			float max  = fs_in.radius + (fs_in.edgeThickness*0.501);
			if(dist > max) discard;
			
			if(fs_in.edgeThickness > 0 && dist >=  fs_in.radius-fs_in.edgeThickness*0.501) {
				color = fs_in.edgeColour;
			} else if(fs_in.fillColour.a == 0) {
				discard;
			} else {
				color = fs_in.fillColour;
			}
		}";
}