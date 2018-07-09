module gl.renderers.gridrenderer;

import gl.all;

final class GridRenderer : Renderer {
	VBO verticalVbo, horizontalVbo;
	float x, y, width, height;
	int numVertical, numHorizontal;
	float verticalGap=1, horizontalGap=1;
	bool hasVerticalLines, hasHorizontalLines;
	RGBA colour;

	this(OpenGL gl, float x, float y, float w, float h, RGBA colour=WHITE) {
		super(gl);
		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
		this.colour = colour;
		prog.use();
		prog.setUniform("COLOUR", colour);
	}
	override void destroy() {
		if(verticalVbo) verticalVbo.destroy();
		if(horizontalVbo) horizontalVbo.destroy();
		super.destroy();
	}
	auto resize(float x, float y, float width, float height) {
		this.x = x; 
		this.y = y;
		this.width = width; 
		this.height = height;
		this.numHorizontal = cast(int)(height/horizontalGap + 1);
		this.numVertical   = cast(int)(width/verticalGap + 1);
		this.dataChanged = true;
		return this;
	}
	auto withVerticalLines(float verticalGap) {
		this.hasVerticalLines = true;
		this.verticalGap = verticalGap;
		this.numVertical = cast(int)(width/verticalGap + 1);
		this.dataChanged = true;
		return this;
	}
	auto withHorizontalLines(float horizontalGap) {
		this.hasHorizontalLines = true;
		this.horizontalGap = horizontalGap;
		this.numHorizontal = cast(int)(height/horizontalGap + 1);
		this.dataChanged = true;
		return this;
	}
	auto withHighlightModulus(int m) {
		prog.use();
		prog.setUniform("MODULUS", m);
		return this;
	}
	override void render() {
		vao.bind();
		prog.use();
		populateVbo(); 
		
		if(hasVerticalLines) {
			prog.setUniform("DELTA", Vector4(0,height,0,0));
			verticalVbo.bind();
			vao.enableAttrib(0, 4);
			glDrawArrays(GL_POINTS, 0, numVertical);
		}
		if(hasHorizontalLines) {
			prog.setUniform("DELTA", Vector4(width,0,0,0));
			horizontalVbo.bind();
			vao.enableAttrib(0, 4);
			glDrawArrays(GL_POINTS, 0, numHorizontal);
		}
	}
protected:
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("GridRenderer-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("GridRenderer-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("GridRenderer-fs", fs, GL_FRAGMENT_SHADER)
		); 
	}
	override void populateVbo() {
		if(!dataChanged) return;

		if(hasVerticalLines) {
			verticalVbo = VBO.array(numVertical*Vector4.sizeof);
			Vector4[] verts = new Vector4[numVertical];
			float x = this.x;
			float y = this.y;
			for(auto i=0;i<verts.length;i++) {
				verts[i] = Vector4(x, y, i, 0);
				x += verticalGap;
			}
			verticalVbo.addData(verts);
		}
		if(hasHorizontalLines) { 
			horizontalVbo = VBO.array(numHorizontal*Vector4.sizeof);
			Vector4[] verts = new Vector4[numHorizontal];
			float x = this.x;
			float y = this.y;
			for(auto i=0;i<verts.length;i++) {
				verts[i] = Vector4(x, y, i, 0);
				y += horizontalGap;
			}
			horizontalVbo.addData(verts);
		}
		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec4 posIndex;	// xy, index, 0
		uniform mat4 VP;

		out VS_OUT {
			float index;
		} vs_out;

		void main() {	
			gl_Position	 = VP * vec4(posIndex.xy, 0, 1);
			vs_out.index = posIndex.z;
		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(line_strip, max_vertices = 2) out;

		uniform vec4 DELTA;
		uniform mat4 VP;

		in VS_OUT {
			float index;
		} gs_in[];

		out GS_OUT {
			float index;
		} gs_out;

		void main() {
			gl_Position  = gl_in[0].gl_Position;
			gs_out.index = gs_in[0].index;
			EmitVertex();

			gl_Position  = gl_in[0].gl_Position + (VP * DELTA);
			gs_out.index = gs_in[0].index;
			EmitVertex();

			EndPrimitive();
		}";
	string fs = "#version 330 core
		out vec4 color;
		uniform vec4 COLOUR;
		uniform int MODULUS = 10;

		in GS_OUT {
			float index;
		} fs_in;

		void main() {
			float factor = 1;
			if((int(fs_in.index)%MODULUS)==0) factor = 1.3; 
			color = COLOUR * factor;
		}";
}