module gl.renderers.linerenderer3d;

import gl.all;

final class LineRenderer3D : Renderer {
	LineData3D[] lines;
	RGBA colour = WHITE;

	final static struct LineData3D {
		Vector3 from;
		Vector3 to;
		RGBA colour;
	}

	this(OpenGL gl) {
		super(gl);
	}
	auto setColour(RGBA c) {
	    colour = c;
	    return this;
	}
	auto addLine(Vector3 from, Vector3 to) {
        lines ~= LineData3D(from, to, colour);
        dataChanged = true;
        return this;
    }
	auto addLine(Vector3 from, Vector3 to, RGBA colour) {
		lines ~= LineData3D(from, to, colour);
		dataChanged = true;
		return this;
	}
	auto clear() {
		lines.length = 0;
		dataChanged = true;
		return this;
	}
	override void render() {
		if(numPoints==0) return;
		vao.bind();
		prog.use();
		populateVbo();

		glDrawArrays(GL_LINES, 0, cast(uint)numPoints);
	}
protected:
	@property override ulong numPoints() { return lines.length*2; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("LineRenderer3D-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("LineRenderer3D-fs", fs, GL_FRAGMENT_SHADER)
		);
	}
	override void populateVbo() {
		if(!dataChanged) return;

		const ELEMENT_SIZE = Vector3.sizeof +
							 RGBAb.sizeof;

		long bytesRequired = numPoints()*ELEMENT_SIZE;

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
			*(cast(Vector3*)ptr) = l.from;
			ptr += Vector3.sizeof;

			*(cast(RGBAb*)ptr) = l.colour.toBytes;
			ptr += RGBAb.sizeof;

			//

			*(cast(Vector3*)ptr) = l.to;
			ptr += Vector3.sizeof;

			*(cast(RGBAb*)ptr) = l.colour.toBytes;
			ptr += RGBAb.sizeof;
		}
		vbo.addData(buf[0..bytesRequired]);
		vao.enableAttrib(0, 3, GL_FLOAT,		 false, ELEMENT_SIZE, 0);
		vao.enableAttrib(1, 4, GL_UNSIGNED_BYTE, true,  ELEMENT_SIZE, Vector3.sizeof);

		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec3 pos;				
		layout(location = 1) in vec4 colour;			

		uniform mat4 VP;

		out VS_OUT {
			vec4 colour;
		} vs_out;

		void main() {	 
			gl_Position       = VP * vec4(pos, 1);
			vs_out.colour	  = colour;		
		}";
	string fs = "#version 330 core
		out vec4 color;

		in VS_OUT {
			vec4 colour;
		} fs_in;

		void main() {
			color = fs_in.colour;
		}";
}