module gl.renderers.spriterenderer;

import gl.all;
/**
	Render multiple Sprite objects. 
	All Sprites need to be using the same texture.
*/
final class SpriteRenderer : Renderer {
	Texture texture;
	BitmapSprite[] sprites;
	bool isDynamic = true;

	this(OpenGL gl, bool isDynamic = true) {
		super(gl);
		this.isDynamic = isDynamic;
	}
	auto withSprites(BitmapSprite[] sprites...) {
		this.sprites = sprites;
		dataChanged = true;
		return this;
	}
	auto addSprites(BitmapSprite[] sprites...) {
		this.sprites ~= sprites;
		dataChanged = true;
		return this;
	}
	auto withTexture(Texture t) {
		texture = t;
		prog.use();
		prog.setUniform("SAMPLER0", 0);
		return this;
	}
	/** Any property other than texture has changed */
	auto spritePropertyChanged() {
		dataChanged = true;
		return this;
	}
	override void render() {
		vao.bind();
		prog.use();
		populateVbo(); 

		texture.bind(0);

		glDrawArrays(GL_POINTS, 0, cast(int)sprites.length);
	}
protected:
	@property override ulong numPoints() { return sprites.length; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("SpriteRenderer-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("SpriteRenderer-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("SpriteRenderer-fs", fs, GL_FRAGMENT_SHADER)
		); 
	}
	override void populateVbo() {
		if(!isDynamic && !dataChanged) return;

		const ELEMENT_SIZE = Vector4.sizeof +
							 Vector4.sizeof +
							 Vector4.sizeof +
							 Vector2.sizeof;

		long bytesRequired = sprites.length*ELEMENT_SIZE;

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
		foreach(s; sprites) {
			*(cast(Vector4*)ptr) = Vector4(s.pos, s.up);
			ptr += Vector4.sizeof;

			*(cast(Vector4*)ptr) = s.uv;
			ptr += Vector4.sizeof;

			*(cast(Vector4*)ptr) = s.colour;
			ptr += Vector4.sizeof;

			*(cast(Vector2*)ptr) = s.size;
			ptr += Vector2.sizeof;
		}
		vbo.addData(buf[0..bytesRequired]);
		vao.enableAttrib(0, 4, GL_FLOAT, false, ELEMENT_SIZE, 0);
		vao.enableAttrib(1, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof);
		vao.enableAttrib(2, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof*2);
		vao.enableAttrib(3, 2, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof*3);
		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec4 modelProps;		// pos, up
		layout(location = 1) in vec4 uvs;				// uvmin, uvmax
		layout(location = 2) in vec4 colour;
		layout(location = 3) in vec2 modelProps2;		// scale, 0

		out VS_OUT {
			vec4 uvs;
			vec4 colour;
			vec2 pos;
			vec2 scale;
			float angleRadians;
		} vs_out;

		float toRadians(in vec2 v) {
			return atan(v.x, -v.y);
		}

		void main() {	 
			vs_out.uvs			= uvs;
			vs_out.pos			= modelProps.xy;
			vs_out.angleRadians = toRadians(modelProps.zw);
			vs_out.scale		= modelProps2;
			vs_out.colour		= colour;

		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(triangle_strip, max_vertices = 4) out;

		uniform mat4 VP;

		in VS_OUT {
			vec4 uvs;
			vec4 colour;
			vec2 pos;
			vec2 scale;
			float angleRadians;
		} gs_in[];

		out GS_OUT {
			vec2 uvs;
			vec4 colour;
		} gs_out;	

		mat4 getTranslationMatrix() {
			mat4 m = mat4(1); 
			m[3][0] = gs_in[0].pos.x + gs_in[0].scale.x*0.5;
			m[3][1] = gs_in[0].pos.y + gs_in[0].scale.y*0.5;
			return m;
		}
		mat4 getScaleMatrix() {
			mat4 m = mat4(1);
			m[0][0] = gs_in[0].scale.x;	
			m[1][1] = gs_in[0].scale.y;	
			return m;
		}
		mat4 getRotationZMatrix() {
			mat4 m = mat4(1);
			float angle = gs_in[0].angleRadians;	
			float C = cos(angle);
			float S = sin(angle);
			m[0][0] = C;
			m[0][1] = S;
			m[1][0] = -S;
			m[1][1] = C;
			return m;
		}
		mat4 getModelMatrix() {
			return getTranslationMatrix() * getRotationZMatrix() * getScaleMatrix();
		}

		const vec4 v0 = vec4(-0.5, -0.5, 0, 1);	
		const vec4 v1 = vec4(-0.5, 0.5, 0, 1);	
		const vec4 v2 = vec4(0.5, 0.5, 0, 1);	
		const vec4 v3 = vec4(0.5, -0.5, 0, 1);	

		void main() {
			mat4 MVP = VP * getModelMatrix();
			vec4 v0_transformed = MVP * v0;
			vec4 v1_transformed = MVP * v1;
			vec4 v2_transformed = MVP * v2;
			vec4 v3_transformed = MVP * v3;

			gl_Position = v0_transformed;		
			gs_out.uvs = gs_in[0].uvs.xy;	
			gs_out.colour = gs_in[0].colour;
			EmitVertex();
			gl_Position = v1_transformed;
			gs_out.uvs = gs_in[0].uvs.xw;
			gs_out.colour = gs_in[0].colour;
			EmitVertex();
			gl_Position = v3_transformed;
			gs_out.uvs = gs_in[0].uvs.zy;	
			gs_out.colour = gs_in[0].colour;
			EmitVertex();
			gl_Position = v2_transformed;
			gs_out.uvs = gs_in[0].uvs.zw;	
			gs_out.colour = gs_in[0].colour;
			EmitVertex();

			EndPrimitive();
		}";
	string fs = "#version 330 core
		in GS_OUT {
			vec2 uvs;
			vec4 colour;
		} fs_in;	

		out vec4 color;
		uniform sampler2D SAMPLER0;
		void main() {
			color = texture(SAMPLER0, fs_in.uvs) * fs_in.colour;
		}";
}
