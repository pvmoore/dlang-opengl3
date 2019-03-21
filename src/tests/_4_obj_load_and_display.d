module tests._4_obj_load_and_display;

import gl.all;
import tests.all;

final class ObjLoadAndDisplayTest : Test {
	OpenGL gl;
	VAO vao;

	FpsCounter[] fpsCounters;
	Model model;
	float xangle = 0;
	float yangle = 0;
	float zangle = 0;
	float scaleAmt = 0;

	this(OpenGL gl) {
		this.gl = gl;
		this.vao = new VAO();

		gl.setWindowTitle("Test 4: OBJ load and display");
	}
	void setup() {
		vao.bind();
		glClearColor (0, 0, 0, 0);

		Dimension winSize = gl.windowSize;

		Matrix4 View = Matrix4.lookAt(
			Vector3(3,3,3), // Camera is at (4,3,3), in World Space
			Vector3(0,0,0), // and looks at the origin
			Vector3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
		);
		Matrix4 Projection = Matrix4.perspective(60.degrees, 4.0f / 3.0f, 0.1f, 500.0f);

		//model = loadOBJ(gl, vao, "models\\cube.obj_model");
		model = loadOBJ(gl, vao, "models\\suzanne.obj.txt");
		//model = loadOBJ(gl, vao, "models\\icosahedron.obj_model");
		//model = loadOBJ(gl, vao, "models\\teapot.obj_model");
		log("model = %s", model);
		log("uvs=%s", (cast(OBJModel)model).uvs);

		//model.position(Vector3(-70,-20,-170));

		model.setVP(View, Projection);
		
		Vector3 lightPos = Vector3(30,200,300); // in world space
		model.setLightPos(lightPos);

		fpsCounters ~= new FpsCounter(gl);
		fpsCounters ~= new FpsCounter(gl, winSize.width-100, 25);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glEnable(GL_CULL_FACE);
		glCullFace(GL_BACK);

		glEnable(GL_DEPTH_TEST);
		glDepthFunc(GL_LESS);
		glDepthRange(1f, 0f);	// this is reversed because of the proj matrix i think :)
		CheckGLErrors();
	}
	void destroy() {
		fpsCounters.each!(it=>it.destroy());
		if(model) model.destroy();
		if(vao) vao.destroy();
	}
	void update(float speedDelta) {
		float scaleFactor = 1+cos(scaleAmt)*0.9f;

		model.scale(Vector3(scaleFactor,scaleFactor,scaleFactor));
		model.rotation(xangle, yangle, zangle);

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
		model.render();
		fpsCounters.each!(it=>it.render());
	}
}