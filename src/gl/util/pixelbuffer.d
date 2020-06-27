module gl.util.pixelbuffer;

import gl.all;
import core.stdc.string : memset;

final struct Pixel {
    ubyte r,g,b;
    this(ubyte rr, ubyte gg, ubyte bb) @nogc pure nothrow {
        r = rr; g = gg; b = bb;
    }
    this(float rr, float gg, float bb) @nogc pure nothrow {
        r = cast(ubyte)(rr*255f);
        g = cast(ubyte)(gg*255f);
        b = cast(ubyte)(bb*255f);
    }
}
static assert(Pixel.sizeof==3);

final class PixelBuffer {
    Pixel[] pixels;
    uint[] lineOffsets;
    OpenGL gl;
    Vector2 screenPos;
    uint width, height;
    uint textureID;
    SpriteRenderer quadRenderer;
    
    ubyte[] getRGBData() {
        return cast(ubyte[])pixels;
    }

    this(OpenGL gl, Vector2 screenPos, uint w, uint h) {
        import std.range : iota;
        this.screenPos = screenPos;
        this.width  = w;
        this.height = h;
        this.gl     = gl;
        this.pixels = new Pixel[width*height];
        this.lineOffsets = iota(0, height).map!(it=>it*width).array;
        clear();
        init();
    }
    void destroy() {
        if(quadRenderer) quadRenderer.destroy();
        if(textureID) glDeleteTextures(1, &textureID);
    }
    void clear() {
        memset(pixels.ptr, 0, pixels.length*3);
    }
    void blitToScreen() {
        writePixelsToTexture();
        quadRenderer.render();
    }
    pragma(inline,true)
    void setPixel(uint x, uint y, ubyte r, ubyte g, ubyte b) {
        pixels[lineOffsets[y]+x] = Pixel(r,g,b);
    }
    pragma(inline,true)
    void setPixel(uint x, uint y, float r, float g, float b) {
        pixels[lineOffsets[y]+x] = Pixel(r,g,b);
    }
private:
    void init() {
        glGenTextures(1, &textureID);

        glBindTexture(GL_TEXTURE_2D, textureID);
        glActiveTexture(GL_TEXTURE0 + 0);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height,
                     0, GL_RGB, GL_UNSIGNED_BYTE, null);

        quadRenderer = new SpriteRenderer(gl, false);
        quadRenderer
            .setVP(new Camera2D(gl.windowSize).VP);
        quadRenderer
            .withTexture(new Texture2D(textureID, Dimension(width, height)))
            .addSprites([
                cast(BitmapSprite)new BitmapSprite()
                    .move(screenPos)
                    .scale(width, height)
            ]);
    }
    void writePixelsToTexture() {
        glBindTexture(GL_TEXTURE_2D, textureID);
        glActiveTexture(GL_TEXTURE0 + 0);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height,
                     0, GL_RGB, GL_UNSIGNED_BYTE, pixels.ptr);
    }
}




