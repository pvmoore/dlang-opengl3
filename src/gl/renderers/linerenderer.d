module gl.renderers.linerenderer;

import gl.all;

final struct LineData {
	Vector2 from;
	Vector2 to;
	RGBA fromColour;
	RGBA toColour;
	float thickness = 1;
}

final class LineRenderer : Renderer {
	LineData[] lines;
	RGBA colour		= WHITE;
	float thickness = 1;

	this(OpenGL gl) {
		super(gl);
	}
	auto withLines(LineData[] lines...) {
		this.lines = lines;
		dataChanged = true;
		return this;
	}
	auto addLines(LineData[] lines...) {
		this.lines ~= lines;
		dataChanged = true;
		return this;
	}
	auto withColour(RGBA c) {
		this.colour = c;
		return this;
	}
	auto withThickness(float t) {
		this.thickness = t;
		return this;
	}
	auto addLine(Vector2 from, Vector2 to) {
		addLines(LineData(from, to, colour, colour, thickness));
		return this;
	}
protected:
	@property override ulong numPoints() { return lines.length; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("LineRenderer-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("LineRenderer-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("LineRenderer-fs", fs, GL_FRAGMENT_SHADER)
		);
	}
	override void populateVbo() {
		if(!dataChanged) return;

		const ELEMENT_SIZE = Vector2.sizeof +
							 Vector2.sizeof +
							 RGBAb.sizeof +
							 RGBAb.sizeof +
							 float.sizeof;

		long bytesRequired = lines.length*ELEMENT_SIZE;

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
		foreach(l; lines) {
			*(cast(Vector4*)ptr) = Vector4(l.from, l.to); 
			ptr += Vector4.sizeof;

			*(cast(RGBAb*)ptr) = l.fromColour.toBytes;
			ptr += RGBAb.sizeof;

			*(cast(RGBAb*)ptr) = l.toColour.toBytes;
			ptr += RGBAb.sizeof;

			*(cast(float*)ptr) = l.thickness;
			ptr += float.sizeof;
		}
		vbo.addData(buf[0..bytesRequired]);
		vao.enableAttrib(0, 4, GL_FLOAT,		 false, ELEMENT_SIZE, 0);
		vao.enableAttrib(1, 4, GL_UNSIGNED_BYTE, true,  ELEMENT_SIZE, Vector4.sizeof);
		vao.enableAttrib(2, 4, GL_UNSIGNED_BYTE, true,  ELEMENT_SIZE, Vector4.sizeof+uint.sizeof);
		vao.enableAttrib(3, 1, GL_FLOAT,	     false, ELEMENT_SIZE, Vector4.sizeof+uint.sizeof*2);

		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec4 fromTo;
		layout(location = 1) in vec4 fromColour;
		layout(location = 2) in vec4 toColour;
		layout(location = 3) in float thickness;			

		out VS_OUT {
			vec2 from;
			vec2 to;
			vec4 fromColour;
			vec4 toColour;
			float thickness;
		} vs_out;

		void main() {	 
			vs_out.from       = fromTo.xy;
			vs_out.to         = fromTo.zw;
			vs_out.fromColour = fromColour;
			vs_out.toColour   = toColour;
			vs_out.thickness  = thickness;
		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(triangle_strip, max_vertices = 4) out;

		uniform mat4 VP;

		in VS_OUT {
			vec2 from;
			vec2 to;
			vec4 fromColour;
			vec4 toColour;
			float thickness;
		} gs_in[];

		out GS_OUT {
			vec4 colour;
		} gs_out;

		void main() {
			vec2 pos0    = gs_in[0].from;
			vec2 pos1    = gs_in[0].to;
			vec2 forward = normalize(pos1 - pos0);

			// stretch the line to account for thickness
			pos0 -= forward * gs_in[0].thickness * 0.5;
			pos1 += forward * gs_in[0].thickness * 0.5;

			vec2 right   = vec2(-forward.y, forward.x);
			vec2 offset  = (vec2(gs_in[0].thickness) / 2) * right;

			gl_Position = VP * vec4(pos0 + offset, 0, 1);
			gs_out.colour = gs_in[0].fromColour;
			EmitVertex();
			gl_Position = VP * vec4(pos0 - offset, 0, 1);
			gs_out.colour = gs_in[0].fromColour;
			EmitVertex();
			gl_Position = VP * vec4(pos1 + offset, 0, 1);
			gs_out.colour = gs_in[0].toColour;
			EmitVertex();
			gl_Position = VP * vec4(pos1 - offset, 0, 1);
			gs_out.colour = gs_in[0].toColour;
			EmitVertex();

			EndPrimitive();
		}";
	string fs = "#version 330 core
		out vec4 color;

		in GS_OUT {
			vec4 colour;
		} fs_in;

		void main() {
			color = fs_in.colour;
		}";
}