module gl.renderers.renderer;

import gl.all;

abstract class Renderer {
	OpenGL gl;
	VAO vao;
	VBO vbo;
	Program prog;
	ubyte[] buf;
	bool dataChanged = true;
public:
    @property Program program() { return prog; }

	this(OpenGL gl) {
		this.gl = gl;
		this.vao  = new VAO();
		this.prog = createProgram();
	}
	void destroy() {
		if(vbo) vbo.destroy();
		if(vao) vao.destroy();
	}
	Renderer setVP(Matrix4 viewProj) {
		prog.use();
		prog.setUniform("VP", viewProj);
		return this;
	}
	void render() {
		if(numPoints==0) return;
		vao.bind();
		prog.use();
		populateVbo();

		glDrawArrays(GL_POINTS, 0, cast(uint)numPoints);
	}
protected:
	@property ulong numPoints() { return 0; }
	Program createProgram() { return null; }
	void populateVbo() {}
}

