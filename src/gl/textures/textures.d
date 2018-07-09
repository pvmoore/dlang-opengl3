module gl.textures.textures;

import gl.all;

interface Texture {
    void destroy();
    void bind(uint unit);
}

final class Textures {
private:
	Texture[string] textures;
	string directory = ".";
public:
    uint numTextures() { return cast(uint)textures.length; }

	void destroy() {
        foreach(string name, Texture t; textures) {
            t.destroy();
        }
        log("destroyed %s textures", textures.length);
        textures = null;
    }

    auto setDirectory(string d) { this.directory = d; return this; }

    Texture get(string filename) {
        return get(directory, filename);
    }
	Texture get(string directory, string filename) {
	    string path = directory ~ "\\" ~ filename;

		Texture* t  = (path in textures);
		if(t !is null) return *t;

		auto texture = loadTexture(path);

		return texture;
	}
	override string toString() {
	    return "[Textures (%s)\n".format(numTextures) ~
	        textures.values.map!(it=>"\t%s".format(it)).join("\n")
	        ~ "]";
	}
private:
	Texture loadTexture(string path) {
	    import std.path : extension;
	    Texture texture;
	    string ext = extension(path).toLower;

        if(".dds"==ext) {
            texture = loadDDS(path, true);
        } else if(".bmp"==ext) {
            texture = loadBMP(path);
        } else {
            throw new Error("Texture %s not supported".format(path));
        }

        textures[path] = texture;

        return texture;
	}
	Texture loadBMP(string path) {
	    auto bmp = BMP.read(path);

        bool hasMipMaps = false;
        uint textureID;
        glGenTextures(1, &textureID);
        // "Bind" the newly created texture : all future texture functions will modify this texture
        glBindTexture(GL_TEXTURE_2D, textureID);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        if(hasMipMaps) {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        } else {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        }

        uint format = bmp.bytesPerPixel == 3 ? GL_RGB : GL_RGBA;
        glTexImage2D(
            GL_TEXTURE_2D, 0, format,
            bmp.width, bmp.height,
            0, format,
            GL_UNSIGNED_BYTE,
            bmp.data.ptr
        );
        return new Texture2D(path, textureID, Dimension(bmp.width, bmp.height), 0, format);
	}
}


