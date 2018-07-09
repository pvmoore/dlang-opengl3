module gl.renderers.filledrectanglerenderer;

import gl.all;

/// vertices are assumed to be counter-clockwise
// 0--3
// |  |
// 1--2
final struct FilledRectangleData { 
	Vector2 v1,v2,v3,v4;
	RGBA colour		 = WHITE;
	Vector4 uvMinMax = Vector4(0,0,1,1);
}

final class FilledRectangleRenderer : Renderer {
	FilledRectangleData[] points;
	Texture texture;

	this(OpenGL gl) {
		super(gl);
		prog.use();
		prog.setUniform("HAS_TEXTURE", 0);
	}
	auto withTexture(Texture t) {
		texture = t;
		prog.use();
		prog.setUniform("SAMPLER0", 0);
		prog.setUniform("HAS_TEXTURE", 1);
		return this;
	}
	auto withRectangles(FilledRectangleData[] points...) {
		this.points = points;
		dataChanged = true;
		return this;
	}
	auto addRectangles(FilledRectangleData[] points...) {
		this.points ~= points;
		dataChanged = true;
		return this;
	}
	auto addRectangle(Vector2 topLeft, Vector2 bottomRight, RGBA colour) {
		FilledRectangleData d;
		d.v1 = topLeft;
		d.v2 = Vector2(topLeft.x, bottomRight.y);
		d.v3 = bottomRight;
		d.v4 = Vector2(bottomRight.x, topLeft.y);
		d.colour = colour;
		addRectangles(d);
		return this;
	}
	override void render() {
		vao.bind();
		prog.use();
		populateVbo();

		if(texture) {
			texture.bind(0);
		} 
		
		glDrawArrays(GL_POINTS, 0, cast(uint)points.length);
	}
protected:
	@property override ulong numPoints() { return points.length; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("FilledRectangleRenderer-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("FilledRectangleRenderer-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("FilledRectangleRenderer-fs", fs, GL_FRAGMENT_SHADER)
		);
	}
	override void populateVbo() {
		if(!dataChanged) return;

		const int ELEMENT_SIZE = Vector4.sizeof +	// v1,v2
								 Vector4.sizeof +	// v3,v4
								 Vector4.sizeof +	// uv,uv2
								 RGBAb.sizeof;		// colour

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
			*(cast(Vector4*)ptr) = Vector4(p.v1, p.v2); 
			ptr += Vector4.sizeof;

			*(cast(Vector4*)ptr) = Vector4(p.v3, p.v4); 
			ptr += Vector4.sizeof;

			*(cast(Vector4*)ptr) = p.uvMinMax; 
			ptr += Vector4.sizeof;

			*(cast(RGBAb*)ptr) = p.colour.toBytes;
			ptr += RGBAb.sizeof;
		}
		vbo.addData(buf[0..bytesRequired]);

		vao.enableAttrib(0, 4, GL_FLOAT,		 false, ELEMENT_SIZE, 0);
		vao.enableAttrib(1, 4, GL_FLOAT,		 false, ELEMENT_SIZE, Vector4.sizeof*1);
		vao.enableAttrib(2, 4, GL_FLOAT,		 false, ELEMENT_SIZE, Vector4.sizeof*2);
		vao.enableAttrib(3, 4, GL_UNSIGNED_BYTE, true,  ELEMENT_SIZE, Vector4.sizeof*3);

		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec4 v1_v2;
		layout(location = 1) in vec4 v3_v4;
		layout(location = 2) in vec4 uv_uv2;
		layout(location = 3) in vec4 colour;		

		uniform mat4 VP;

		out VS_OUT {
			vec4 v0;
			vec4 v1;
			vec4 v2;
			vec4 v3;
			vec4 uvs;
			vec4 colour;
		} vs_out;

		void main() {	 
			vs_out.v0     = VP * vec4(v1_v2.xy, 0, 1);
			vs_out.v1     = VP * vec4(v1_v2.zw, 0, 1);
			vs_out.v2     = VP * vec4(v3_v4.xy, 0, 1);
			vs_out.v3     = VP * vec4(v3_v4.zw, 0, 1);
			vs_out.uvs	  = uv_uv2;
			vs_out.colour = colour;
		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(triangle_strip, max_vertices = 4) out;
		
		in VS_OUT {
			vec4 v0;
			vec4 v1;
			vec4 v2;
			vec4 v3;
			vec4 uvs;
			vec4 colour;
		} gs_in[];

		out GS_OUT {
			vec2 uv;
			vec4 colour;
		} gs_out;

		void main() {
			gl_Position   = gs_in[0].v0;
			gs_out.uv     = gs_in[0].uvs.xy;
			gs_out.colour = gs_in[0].colour;
			EmitVertex();

			gl_Position   = gs_in[0].v1;
			gs_out.uv     = gs_in[0].uvs.xw;
			gs_out.colour = gs_in[0].colour;
			EmitVertex();

			gl_Position   = gs_in[0].v3;
			gs_out.uv     = gs_in[0].uvs.zy;
			gs_out.colour = gs_in[0].colour;
			EmitVertex();

			gl_Position   = gs_in[0].v2;
			gs_out.uv     = gs_in[0].uvs.zw;
			gs_out.colour = gs_in[0].colour;
			EmitVertex();

			EndPrimitive();
		}";
	string fs = "#version 330 core
		out vec4 color;

		in GS_OUT {
			vec2 uv;
			vec4 colour;
		} fs_in;

		uniform int HAS_TEXTURE;
		uniform sampler2D SAMPLER0;

		void main() {
			if(HAS_TEXTURE==1) {
				color = texture(SAMPLER0, fs_in.uv) * fs_in.colour;
			} else {
				color = fs_in.colour;
			}
		}";
}