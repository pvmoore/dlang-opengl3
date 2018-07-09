module gl.textures.texture_cube;
/**
 *
 */
import gl.all;

final class CubeMapTexture : Texture {
    uint id;

    @Implements("Texture")
    void destroy() {
        if(id) glDeleteTextures(1, &id); id = 0;
    }
    @Implements("Texture")
    void bind(uint unit) {
        glActiveTexture(GL_TEXTURE0 + unit);
        glBindTexture(GL_TEXTURE_CUBE_MAP, id);
    }

    /**
     *  Loads a skybox from a specified directory.
     *  Assumes 6 images are named:
     *  front, back, left, right, top, bottom (.png)
     */
    static auto load(string directory) {
        auto texture = new CubeMapTexture();
        glGenTextures(1, &texture.id);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, texture.id);
        const filenames = [
            "/right.png",
            "/left.png",
            "/top.png",
            "/bottom.png",
            "/back.png",
            "/front.png",
        ];

        foreach(uint i, filename; filenames) {
            loadFace(i, directory~filename);
        }
        return texture;
    }
private:
    static void loadFace(uint target, string filename) {

        auto png = PNG.read(filename);

        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        uint format = png.bytesPerPixel == 3 ? GL_RGB : GL_RGBA;
        glTexImage2D(
            GL_TEXTURE_CUBE_MAP_POSITIVE_X + target,
            0,
            GL_RGBA,
            png.width,
            png.height,
            0,
            format,
            GL_UNSIGNED_BYTE,
            png.data.ptr
        );
    }
}

