module tests._8_sdffonts;
/**
 *
 */
import gl.all;
import tests.all;
import std.stdio : writefln;

final class TestSDFFonts : Test {
    OpenGL gl;
    VAO vao;
    Camera2D camera;
    SDFFontRenderer renderer;
    FpsCounter fpsCounter;
    Renderer box;

    this(OpenGL gl) {
        this.gl  = gl;
        this.vao = new VAO();

        gl.setWindowTitle("Test 8: SDF Fonts");
    }
    void setup() {
        glClearColor(0.2, 0.2, 0.3, 1);
        vao.bind();

        camera = new Camera2D(gl.windowSize);

        auto font = gl.getFont("georgia");
        writefln("font=%s",font);

        renderer = new SDFFontRenderer(gl, font, true);
        renderer.setVP(camera.VP);

        renderer.setColour(WHITE*1.1);
        renderer.setDropShadowColour(RGBA(0,0,0,0.75));
        renderer.setDropShadowOffset(Vector2(-0.0025,0.0025));

        Rect r = font.sdf.getRect("96 Hello there, PeteY,", 96);
        auto trans = new Transformer()
            .verts(Vector2(0, 0),
                   Vector2(0, 1),
                   Vector2(1, 1),
                   Vector2(1, 0))
            .translate(50+r.x, 250+r.y)
            .scale(r.width, r.height)
            .apply();

        box = new OutlineRectangleRenderer(gl)
            .withRectangles(OutlineRectangleData(
                trans[0],trans[1],trans[2],trans[3],
                WHITE, 1f
            ))
            .setVP(camera.VP);

        renderer.setSize(16)
                .appendText("16 Hello there, PeteY,", 50, 10);
        renderer.setSize(20)
                .appendText("20 Hello there, PeteY,", 50, 50);
        renderer.setSize(32)
                .appendText("32 Hello there, PeteY,", 50, 100);
        renderer.setSize(64)
                .appendText("64 Hello there, PeteY,", 50, 150);
        renderer.setSize(96)
                .appendText("96 Hello there, PeteY,", 50, 250);
        renderer.setSize(128)
                .appendText("128 Hello there, PeteY,", 50, 400);
        renderer.setSize(160)
               .appendText("160 PeteY, To 12", 50, 560);

        fpsCounter = new FpsCounter(gl);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }
    void destroy() {
        if(box) box.destroy();
        if(fpsCounter) fpsCounter.destroy();
        if(renderer) renderer.destroy();
        if(vao) vao.destroy();
    }
    void mouseClicked(float x, float y) nothrow {
    }
    void render(ulong frameNumber, float seconds, float perSecond) {
        glClear(GL_COLOR_BUFFER_BIT);

        box.render();
        renderer.render();
        fpsCounter.render();
    }
}

