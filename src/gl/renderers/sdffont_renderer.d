module gl.renderers.sdffont_renderer;
/**
 *  Renders a signed distance field font (SDFFont (from fonts library)
 */
import gl.all;

final class SDFFontRenderer : Renderer {
private:
    Font font;
    int numTextCharacters;
    TextChunk[] textChunks;
    float size;
    RGBA colour = WHITE;
    bool dropShadow;
    Program dropShadowProgram;

    static struct TextChunk {
        string text;
        RGBA colour;
        float size;
        int x, y;
    }
public:
    this(OpenGL gl, Font font, bool dropShadow) {
        super(gl);
        this.font = font;
        this.size = font.sdf.size;
        this.dropShadow = dropShadow;
        this.textChunks.assumeSafeAppend();
        this.textChunks.reserve(8);
        setupDropShadow();
        prog.use();
        prog.setUniform("SAMPLER0", 0);
    }
    override void destroy() {
        super.destroy();
    }
    override Renderer setVP(Matrix4 viewProj) {
        if(dropShadow) {
            dropShadowProgram.use();
            dropShadowProgram.setUniform("VP", viewProj);
        }
        return super.setVP(viewProj);
    }
    auto setColour(RGBA colour) {
        this.colour = colour;
        return this;
    }
    auto setDropShadowColour(RGBA c) {
        dropShadowProgram.use();
        dropShadowProgram.setUniform("DROPSHADOW_COLOUR", c);
        return this;
    }
    auto setDropShadowOffset(Vector2 o) {
        dropShadowProgram.use();
        dropShadowProgram.setUniform("DROPSHADOW_OFFSET", o);
        return this;
    }
    auto setSize(float size) {
        this.size = size;
        return this;
    }
    auto appendText(string text, uint x=0, uint y=0) {
        TextChunk chunk;
        chunk.text = text;
        chunk.colour = colour;
        chunk.size = size;
        chunk.x = x;
        chunk.y = y;
        textChunks ~= chunk;
        numTextCharacters += cast(int)text.length;
        dataChanged = true;
        return this;
    }
    auto replaceText(int chunk, string text, int x=int.max, int y=int.max) {
        // check to see if the text has actually changed.
        // if not then we can ignore this change
        TextChunk* c = &textChunks[chunk];
        if((x==int.max || x==c.x) && (y==int.max || y==c.y) && c.text == text) {
            return this;
        }
        c.text = text;
        if(x!=int.max) c.x = x;
        if(y!=int.max) c.y = y;
        numTextCharacters = countCharacters();
        dataChanged = true;
        return this;
    }
    auto replaceText(string text) {
        return replaceText(0, text);
    }
    auto clearText() {
        textChunks.length = 0;
        numTextCharacters = 0;
        dataChanged = true;
        return this;
    }
    override void render() {
        vao.bind();
        populateVbo();

        glActiveTexture(GL_TEXTURE0 + 0);
        glBindTexture(GL_TEXTURE_2D, font.textureId);

        if(dropShadow) {
            dropShadowProgram.use();
            glDrawArrays(GL_POINTS, 0, numTextCharacters);
        }
        prog.use();
        glDrawArrays(GL_POINTS, 0, numTextCharacters);
    }
protected:
	override ulong numPoints() { return numTextCharacters; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("SDFFontRenderer-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("SDFFontRenderer-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("SDFFontRenderer-fs", fs, GL_FRAGMENT_SHADER)
		);
	}
    override void populateVbo() {
        if(!dataChanged) return;

        const ELEMENT_SIZE = 3*Vector4.sizeof + float.sizeof;

        long bytesRequired = numTextCharacters*ELEMENT_SIZE;

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

        ubyte* ptr  = buf.ptr;
        foreach(ref c; textChunks) {
            auto maxY = c.size;
            float X = c.x;
            float Y = c.y;
            foreach(i, ch; c.text) {
                auto g = font.sdf.getChar(ch);
                float ratio = (c.size/cast(float)font.sdf.size);

                float x = X + g.xoffset * ratio;
                float y = Y + g.yoffset * ratio;
                float w = g.width * ratio;
                float h = g.height * ratio;

                *(cast(Vector4*)ptr) = Vector4(x, y, w, h);
                ptr += Vector4.sizeof;

                *(cast(Vector4*)ptr) = Vector4(g.u, g.v, g.u2, g.v2);
                ptr += Vector4.sizeof;

                *(cast(Vector4*)ptr) = c.colour;
                ptr += Vector4.sizeof;

                *(cast(float*)ptr) = c.size;
                ptr += float.sizeof;

                int kerning = 0;
                if(i<c.text.length-1) {
                    kerning = font.sdf.getKerning(ch, c.text[i+1]);
                }

                X += (g.xadvance + kerning) * ratio;
            }
        }
        vbo.addData(buf[0..bytesRequired]);
        vao.enableAttrib(0, 4, GL_FLOAT, false, ELEMENT_SIZE, 0);
        vao.enableAttrib(1, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof);
        vao.enableAttrib(2, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof*2);
        vao.enableAttrib(3, 1, GL_FLOAT, false, ELEMENT_SIZE, Vector4.sizeof*3);
        dataChanged = false;
    }
private:
    void setupDropShadow() {
        if(!dropShadow) return;
        dropShadowProgram = gl.getProgram(
            gl.getShaderFromCode("SDFFontRenderer-vs", vs, GL_VERTEX_SHADER),
            gl.getShaderFromCode("SDFFontRenderer-gs", gs, GL_GEOMETRY_SHADER),
            gl.getShaderFromCode("SDFFontRenderer-dsfs", dropShadowfs, GL_FRAGMENT_SHADER)
        );
        dropShadowProgram.use();
        dropShadowProgram.setUniform("SAMPLER0", 0);
    }
    int countCharacters() {
		long total = 0;
		foreach(ref c; textChunks) {
			total += c.text.length;
		}
		return cast(int)total;
	}
    string vs = "#version 330 core
		layout(location = 0) in vec4 pos;	// x,y,w,h
		layout(location = 1) in vec4 uvs;
		layout(location = 2) in vec4 colour;
		layout(location = 3) in float size;

		out VS_OUT {
			vec4 posdim;
			vec4 uvs;
			vec4 colour;
			float size;
		} vs_out;

		void main() {
			vs_out.posdim    = pos;
			vs_out.uvs	     = uvs;
			vs_out.colour    = colour;
			vs_out.size      = size;
		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(triangle_strip, max_vertices = 4) out;

		uniform mat4 VP;

		in VS_OUT {
			vec4 posdim;
			vec4 uvs;
			vec4 colour;
			float size;
		} gs_in[];

		out GS_OUT {
			vec2 uvs;
			vec4 colour;
			float size;
		} gs_out;

		mat4 getTranslationMatrix() {
			mat4 m = mat4(1);
			m[3][0] = gs_in[0].posdim.x;
			m[3][1] = gs_in[0].posdim.y;
			return m;
		}
		mat4 getModelMatrix() {
			return getTranslationMatrix();
		}

		void main() {
			float w = gs_in[0].posdim.z;
			float h = gs_in[0].posdim.w;

			vec4 v0 = vec4(0, 0, 0, 1);
			vec4 v1 = vec4(0, h, 0, 1);
			vec4 v2 = vec4(w, h, 0, 1);
			vec4 v3 = vec4(w, 0, 0, 1);

			mat4 MVP = VP * getModelMatrix();
			vec4 v0_transformed = MVP * v0;
			vec4 v1_transformed = MVP * v1;
			vec4 v2_transformed = MVP * v2;
			vec4 v3_transformed = MVP * v3;

			gl_Position = v0_transformed;
			gs_out.uvs = gs_in[0].uvs.xy;
			gs_out.colour = gs_in[0].colour;
			gs_out.size = gs_in[0].size;
			EmitVertex();

			gl_Position = v1_transformed;
			gs_out.uvs = gs_in[0].uvs.xw;
			gs_out.colour = gs_in[0].colour;
			gs_out.size = gs_in[0].size;
			EmitVertex();

			gl_Position = v3_transformed;
			gs_out.uvs = gs_in[0].uvs.zy;
			gs_out.colour = gs_in[0].colour;
			gs_out.size = gs_in[0].size;
			EmitVertex();

			gl_Position = v2_transformed;
			gs_out.uvs = gs_in[0].uvs.zw;
			gs_out.colour = gs_in[0].colour;
			gs_out.size = gs_in[0].size;
			EmitVertex();

			EndPrimitive();
		}";
    string fs = "#version 330 core
		in GS_OUT {
			vec2 uvs;
			vec4 colour;
			float size;
		} fs_in;

		out vec4 color;
		uniform sampler2D SAMPLER0;

		void main() {
            float smoothing = (1.0 / (0.25*fs_in.size));
            float distance  = texture(SAMPLER0, fs_in.uvs).r;
            float alpha     = smoothstep(0.5 - smoothing, 0.5 + smoothing, distance);
            color           = vec4(fs_in.colour.rgb, fs_in.colour.a * alpha);
		}";
    string dropShadowfs = "#version 330 core
        in GS_OUT {
            vec2 uvs;
            vec4 colour;
            float size;
        } fs_in;

        out vec4 color;
        uniform sampler2D SAMPLER0;
        uniform vec4 DROPSHADOW_COLOUR = vec4(0,0,0,0.80);
        uniform vec2 DROPSHADOW_OFFSET = vec2(-0.0025,0.0025);

        void main() {
            vec2 offset     = DROPSHADOW_OFFSET;
            float smoothing = (1.0 / (0.25*fs_in.size)) * fs_in.size/12;
            float distance  = texture(SAMPLER0, fs_in.uvs-offset).r;
            vec4 col        = DROPSHADOW_COLOUR;
            float alpha     = smoothstep(0.5 - smoothing, 0.5 + smoothing, distance);
            color           = vec4(col.rgb, col.a * alpha);
        }";
}

