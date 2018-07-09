module tests._9_skybox;
/**
 *
 */
import gl.all;
import tests.all;
import std.stdio : writefln;

final class TestSkyBox : Test {
    OpenGL gl;
    VAO vao;
    Camera3D camera;
    FpsCounter fpsCounter;
    SDFFontRenderer fonts;
    SkyBox skybox;

    this(OpenGL gl) {
        this.gl  = gl;
        this.vao = new VAO();

        gl.setWindowTitle("Test 9: SkyBox");
    }
    void setup() {
        glClearColor(0.2, 0.2, 0.3, 1);
        vao.bind();

        camera = Camera3D.forGL(gl.windowSize,
            Vector3(4096.00, 2047.72, 7649.85),
            Vector3(4096.00, 2047.72, 7649.85)+Vector3(0.00, -0.28, -0.96));
        camera.fovNearFar(60.degrees, 10, 100000);


        writefln("camera = %s", camera);

        fpsCounter = new FpsCounter(gl);

        auto font = gl.getFont("arial");
        fonts = new SDFFontRenderer(gl, font, true);
        fonts.setVP(new Camera2D(gl.windowSize).VP);
        fonts.setSize(40)
             .setColour(RED*0.8)
             .appendText("Use arrow keys to look around", 20, 20);

        skybox = new SkyBox(gl, "../../../_assets/images/skyboxes/skybox1");
        skybox.setVP(camera);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glEnable(GL_TEXTURE_CUBE_MAP_SEAMLESS);

        //glFrontFace(GL_CCW);
		//glEnable(GL_CULL_FACE);

//		glEnable(GL_DEPTH_TEST);
//		glDepthFunc(GL_LESS);
		CheckGLErrors();
    }
    void destroy() {
        if(fonts) fonts.destroy();
        if(skybox) skybox.destroy();
        if(fpsCounter) fpsCounter.destroy();
        if(vao) vao.destroy();
    }
    void mouseClicked(float x, float y) {
    }
    void render(long frameNumber, long normalisedFrameNumber, float speedDelta) {
        glClear(GL_COLOR_BUFFER_BIT);

        skybox.render();
        fpsCounter.render();
        fonts.render();

        if(gl.isKeyPressed(GLFW_KEY_LEFT)) {
            camera.yaw(-0.001);
            skybox.setVP(camera);
        } else if(gl.isKeyPressed(GLFW_KEY_RIGHT)) {
            camera.yaw(0.001);
            skybox.setVP(camera);
        } else if(gl.isKeyPressed(GLFW_KEY_UP)) {
            camera.pitch(-0.001);
            skybox.setVP(camera);
        } else if(gl.isKeyPressed(GLFW_KEY_DOWN)) {
            camera.pitch(0.001);
            skybox.setVP(camera);
//        } else if(gl.isKeyPressed(GLFW_KEY_SPACE)) {
//             camera.moveForward(0.001);
//             skybox.setVP(camera);
        }
    }
}