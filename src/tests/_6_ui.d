module tests._6_ui;

import gl.all;
import tests.all;

final class TestUI : Test {
    OpenGL gl;
    FpsCounter fpsCounter;

    this(OpenGL gl) {
        this.gl = gl;

        gl.setWindowTitle("Test 6: UI");
    }
    void setup() {
        glClearColor(0.2, 0.2, 0.2, 1);

        fpsCounter = new FpsCounter(gl);

        initUI();

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
    void destroy() {
        fpsCounter.destroy();
    }
    void initUI() {

        auto w1 = gl.ui.createWindow(
                            Vector2(50,50),
                            Vector2(300,35));
        //w1.bgColour(RGBA(1,0,0,1));
        //w1.cornerRadius(30);
        auto w2 = gl.ui.createWindow(
                            Vector2(50,90),
                            Vector2(300,500));
    }
    void mouseClicked(float x, float y) nothrow {

    }
    void render(long frameNumber, long normalisedFrameNumber, float speedDelta) {
        glClear(GL_COLOR_BUFFER_BIT);
        fpsCounter.render();
    }
}



