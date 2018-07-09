module gl.textures.texture_2d;
/**
 *
 */
import gl.all;

final class Texture2D : Texture {
	uint id;
	string filename;
	Dimension size;
	int numMipmaps;
	uint format;

	this(uint id, Dimension size) {
		this.id			= id;
		this.size		= size;
	}
	this(string filename, uint id, Dimension size, int numMipmaps, uint format) {
		this(id, size);
		this.filename	= filename;
		this.numMipmaps	= numMipmaps;
		this.format     = format;
		log("loaded texture '%s' (id:%s, [%s,%s], mipmaps:%s)", filename, id, size.width, size.height, numMipmaps);
	}
	@Implements("Texture")
	void destroy() {
        log("destroying texture '%s' (id:%s)", filename, id);
        if(id) glDeleteTextures(1, &id); id = 0;
    }
    @Implements("Texture")
	void bind(uint unit) {
		glActiveTexture(GL_TEXTURE0 + unit);
		glBindTexture(GL_TEXTURE_2D, id);
	}
    override string toString() {
        import std.path : baseName;
        string name = filename is null ? "" : filename.baseName;
        string fmt  = format == GL_RGB ? "RGB" :
                      format == GL_RGBA ? "RGBA" : to!string(format);
        return "[Texture '%s' id:%s %s %s]".format(name, id, size, fmt);
    }
}

