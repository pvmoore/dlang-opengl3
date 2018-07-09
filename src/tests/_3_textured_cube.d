module tests._3_textured_cube;

import gl.all;
import tests.all;

final class TexturedCubeTest : Test {
	OpenGL gl;
	VAO vao;

	Cube cube;
	FpsCounter fpsCounter;
	float xangle = 0;
	float yangle = 0;
	float zangle = 0;
	float scaleAmt = 0;

	this(OpenGL gl) {
		this.gl = gl;
		this.vao = new VAO();

		gl.setWindowTitle("Test 3: Textured Cube");
	}
	void setup() {
		vao.bind();

		glClearColor (0, 0, 0, 0);

		auto View = Matrix4.lookAt(
			Vector3(4,3,3), // Camera is at (4,3,3), in World Space
			Vector3(0,0,0), // and looks at the origin
			Vector3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
		);

		auto Projection = Matrix4.perspective(60.degrees, 4.0f / 3.0f, 0.1f, 100.0f);

		cube = new Cube(gl, vao);
		cube.setVP(View, Projection);
		cube.texture(gl.textures.get("images", "wood.dds"));

		fpsCounter = new FpsCounter(gl);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glEnable(GL_CULL_FACE);

		glEnable(GL_DEPTH_TEST);
		glDepthFunc(GL_LESS);	// GL_LESS is the default
		CheckGLErrors();
	}
	void destroy() {
		if(fpsCounter) fpsCounter.destroy();
		if(cube) cube.destroy();
		if(vao) vao.destroy();
	}
	void update(float speedDelta) {
		float scaleFactor = 1+cos(scaleAmt)*0.9f;

		cube.scale(Vector3(scaleFactor,scaleFactor,scaleFactor));
		cube.rotation(xangle, yangle, zangle);

		float add = 0.015 * speedDelta;
		xangle += add;
		yangle += add;
		zangle += add;
		scaleAmt += add;
	}
	void mouseClicked(float x, float y) {
	}
	void render(long frameNumber, long normalisedFrameNumber, float speedDelta) {
		update(speedDelta);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT/* | GL_STENCIL_BUFFER_BIT*/);
		cube.render();
		fpsCounter.render();
	}
}