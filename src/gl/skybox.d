module gl.skybox;
/**
 *  Note that I had to rotate the top image 90 degrees
 *  counter-clockwise to make it look right.
 */
import gl.all;

final class SkyBox {
    OpenGL gl;
    VAO vao;
    VBO vbo;
    Program prog;
    Texture texture;

    this(OpenGL gl, string directory) {
        this.gl     = gl;
        this.vao    = new VAO();
        this.prog   = gl.getProgram(
            gl.getShaderFromCode("SkyBox-vs", vs, GL_VERTEX_SHADER),
            gl.getShaderFromCode("SkyBox-fs", fs, GL_FRAGMENT_SHADER)
        );
        this.texture = CubeMapTexture.load(directory);
        prog.use();
        prog.setUniform("SAMPLER0", 0);
        populateVbo();
    }
    void destroy() {
        if(texture) texture.destroy();
        if(vbo) vbo.destroy();
        vao.destroy();
    }
    SkyBox setVP(Camera3D camera) {
        prog.use();
        prog.setUniform("V", camera.V);
        prog.setUniform("P", camera.P);
        return this;
    }
    void render() {
        vao.bind();
        prog.use();

        texture.bind(0);

		glDrawArrays(GL_TRIANGLES, 0, 6*2*3);
    }
private:
    void populateVbo() {
        vao.bind();

        const float s = 100.0;

        Vector3[] vertices = [
            // left
            Vector3(-s, -s,  s),
            Vector3(-s, -s, -s),
            Vector3(-s,  s, -s),
            Vector3(-s,  s, -s),
            Vector3(-s,  s,  s),
            Vector3(-s, -s,  s),
            // back
            Vector3(-s,  s, -s),
            Vector3(-s, -s, -s),
            Vector3( s, -s, -s),
            Vector3( s, -s, -s),
            Vector3( s,  s, -s),
            Vector3(-s,  s, -s),
            // right
            Vector3( s, -s, -s),
            Vector3( s, -s,  s),
            Vector3( s,  s,  s),
            Vector3( s,  s,  s),
            Vector3( s,  s, -s),
            Vector3( s, -s, -s),
            // front
            Vector3(-s, -s,  s),
            Vector3(-s,  s,  s),
            Vector3( s,  s,  s),
            Vector3( s,  s,  s),
            Vector3( s, -s,  s),
            Vector3(-s, -s,  s),
            // top
            Vector3( s,  s,  s),
            Vector3(-s,  s,  s),
            Vector3(-s,  s, -s),
            Vector3(-s,  s, -s),
            Vector3( s,  s, -s),
            Vector3( s,  s,  s),
            // bottom
            Vector3(-s, -s, -s),
            Vector3(-s, -s,  s),
            Vector3( s, -s, -s),
            Vector3( s, -s, -s),
            Vector3(-s, -s,  s),
            Vector3( s, -s,  s)
        ];

        vbo = VBO.array(vertices.length*Vector3.sizeof, GL_STATIC_DRAW);
        vbo.addData(vertices);

        vao.enableAttrib(0, 3, GL_FLOAT, false, Vector3.sizeof, 0);
    }
    string vs = "#version 330 core
        layout(location = 0) in vec3 position;

        uniform mat4 V;
        uniform mat4 P;

        out VS_OUT {
            vec3 uvs;
        } vs_out;

        mat4 translatedToOrigin(mat4 m) {
            mat4 m2 = m;
            m2[3].x = 0;
            m2[3].y = 0;
            m2[3].z = 0;
            return m2;
        }

        void main() {
            mat4 view   = translatedToOrigin(V);
            gl_Position	= P * view * vec4(position, 1);
            vs_out.uvs  = position;
        }";
    string fs = "#version 330 core
        in VS_OUT {
            vec3 uvs;
        } fs_in;

        out vec4 color;
        uniform samplerCube SAMPLER0;

        void main() {
            color = texture(SAMPLER0, fs_in.uvs * 0.01);
        }";
}

