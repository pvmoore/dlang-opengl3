module gl.ui.window;

import gl.all;

final class Window : UIElement {
    WindowRenderer renderer;
    RGBA _bgColour = RGBA(0.5,0.5,0.5, 1);
    float _cornerRadius = 10;

    override void create(UI ui) {
        renderer = new WindowRenderer(ui.gl);
        renderer.setVP(ui.camera.VP);
    }
    override void destroy() {
        super.destroy();
        renderer.destroy();
    }
    auto bgColour(RGBA c) {
        _bgColour = c;
        renderer.set(absPos, size, c);
        return this;
    }
    auto cornerRadius(float r) {
        _cornerRadius = r;
        renderer.program.use();
        renderer.program.setUniform("CORNER_RADIUS", r);
        return this;
    }
    override void render() {
        if(dirty) renderer.set(absPos, size, _bgColour);
        renderer.render();
        super.render();
    }
}

final class WindowRenderer : Renderer {
private:
    Vector2 pos;
    Vector2 size;
    RGBA bgColour;
public:
    this(OpenGL gl) {
        super(gl);
    }
    void set(Vector2 pos, Vector2 size, RGBA bgColour) {
        this.pos = pos;
        this.size = size;
        this.bgColour = bgColour;
        dataChanged = true;
    }
protected:
    override Program createProgram() {
        return gl.getProgramFromFile("shaders/ui-rect.shader");
    }
    override ulong numPoints() { return 1; }
    override void populateVbo() {
        if(!dataChanged) return;

        const int ELEMENT_SIZE = Vector4.sizeof +	// pos_size
                                 RGBAb.sizeof;		// colour

        long bytesRequired = 1*ELEMENT_SIZE;

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
        //foreach(p; points) {

            *(cast(Vector4*)ptr) = Vector4(pos, size);
            ptr += Vector4.sizeof;

            *(cast(RGBAb*)ptr) = bgColour.toBytes;
            ptr += RGBAb.sizeof;
        //}
        vbo.addData(buf[0..bytesRequired]);

        vao.enableAttrib(0, 4, GL_FLOAT,		 false, ELEMENT_SIZE, 0);
        vao.enableAttrib(1, 4, GL_UNSIGNED_BYTE, true,  ELEMENT_SIZE, Vector4.sizeof*1);

        dataChanged = false;
    }
}
