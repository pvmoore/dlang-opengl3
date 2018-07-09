module gl.geom._3d.cube;

import gl.all;

final class Cube : Geometry3D {	
	Program program;
	Texture _texture;
	int numIndices;
	VBO[3] vbos; // 0=vertices,1=colours,2=uvs
	bool ownedVao;

	this(OpenGL gl) {
		this(gl, new VAO());
		this.ownedVao = true;
	}
	this(OpenGL gl, VAO vao) {
		super(gl, vao);
		setupVertices();
		setupColours();
		program = gl.getProgram(
			gl.getShaderFromCode("Cube-vs-rgba", rgbaVertexShader, GL_VERTEX_SHADER), 
			gl.getShaderFromCode("Cube-fs-rgba", rgbaFragmentShader, GL_FRAGMENT_SHADER)
		);
	}
	override void destroy() {
		vbos[0].destroy();
		vbos[1].destroy();
		if(vbos[2]) vbos[2].destroy();
		if(ownedVao) vao.destroy();
		super.destroy();
	}
	auto texture(Texture t) {
		this._texture = t;
		this.program = gl.getProgram(
			gl.getShaderFromCode("Cube-vs-rgba-uv", textureRgbaVertexShader, GL_VERTEX_SHADER),
			gl.getShaderFromCode("Cube-fs-rgba-uv", textureRgbaFragmentShader, GL_FRAGMENT_SHADER)
		);
		setupTexture();
		return this;
	}
	override void render() {
		vao.bind();
		program.use();
		program.setUniform("MVP", mvp);

		// bind vertices to vertex shader location 0
		vbos[0].bind();
		vao.enableAttrib(0, 3/*xyz*/); 

		// bind colours to vertex shader location 1
		vbos[1].bind();
		vao.enableAttrib(1, 4/*rgba*/);

		if(_texture) {
			_texture.bind(0);
			program.setUniform("textureSampler0",0);

			vbos[2].bind();
			vao.enableAttrib(2, 2/*uv*/);
		}
		
		// output the arrays as triangles
		glDrawArrays(GL_TRIANGLES, 0, 12*3);

		// output indexed elements
		//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIds[3]);
		//glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, null);

		//vao.disableAttribs();
		//program.unuse();
	}
private:
	void setupVertices() {
		Vector3[] vertices = [
			Vector3(1,  1, -1),
			Vector3(1, -1, -1),
		    Vector3(-1, -1, -1),
			Vector3(1,  1, -1),
		    Vector3(-1, -1, -1),
		    Vector3(-1,  1, -1),

			Vector3(-1, -1, 1),
			Vector3(-1, 1, 1),
			Vector3(-1, 1, -1),
			Vector3(-1, -1, 1),
			Vector3(-1, 1, -1),
			Vector3(-1, -1, -1),

			Vector3(1, -1, 1),
			Vector3(1, 1, 1),
			Vector3(-1, -1, 1),
			Vector3(1, 1, 1),
			Vector3(-1, 1, 1),
			Vector3(-1, -1, 1),

			Vector3(1, -1, -1),
			Vector3(1, 1, -1),
			Vector3(1, -1, 1),
			Vector3(1, 1, -1),
			Vector3(1, 1, 1),
			Vector3(1, -1, 1),

			Vector3(1, 1, -1),
			Vector3(-1, 1, -1),
			Vector3(1, 1, 1),
			Vector3(-1, 1, -1),
			Vector3(-1, 1, 1),
			Vector3(1, 1, 1),

			Vector3(1, -1, -1),
			Vector3(1, -1, 1),
			Vector3(-1, -1, 1),
			Vector3(1, -1, -1),
			Vector3(-1, -1, 1),
			Vector3(-1, -1, -1)
		];
		// this works but it doesn't take into account
		// vertices with multiple uv or colour
		//Tuple!(Vector3[],ushort[]) indexedVerts = getIndexedVertices(vertices);
		//numIndices = cast(int)indexedVerts[1].length;

		vbos[0] = VBO.array(vertices.length*Vector3.sizeof).addData(vertices);

		////glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboIds[3]);
		////glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexedVerts[1].length * ushort.sizeof, indexedVerts[1].ptr, GL_STATIC_DRAW);
	}
	void setupColours() {
		RGBA[] cols = [
			WHITE, 
			WHITE, 
			WHITE, 
			WHITE, 
			WHITE, 
			WHITE, 

			YELLOW, 
			YELLOW, 
			YELLOW, 
			YELLOW, 
			YELLOW, 
			YELLOW, 

			GREEN, 
			GREEN, 
			GREEN, 
			GREEN, 
			GREEN, 
			GREEN, 

			RED, 
			RED, 
			RED, 
			RED, 
			RED, 
			RED, 

			MAGENTA, 
			MAGENTA, 
			MAGENTA, 
			MAGENTA, 
			MAGENTA, 
			MAGENTA, 

			BLUE, 
			BLUE, 
			BLUE, 
			BLUE, 
			BLUE, 
			BLUE, 
		];
		vbos[1] = VBO.array(cols.length*RGBA.sizeof).addData(cols);
	}
	void setupTexture() {
		/* Opengl uses top-down UV coords (DX is bottom up)
		(0,0)-(1,0)
		|     |
		(0,1)-(1,1)  */
		float[] uv = [
			1, 0,	//	
			1, 1,  //
			0, 1,  //
			1, 0,
			0, 1,
			0, 0, //

			1, 0, //
			1, 1,//
			0, 1,
			1, 0,
			0, 1,
			0, 0,

			1, 0,//
			1, 1,//
			0, 1,
			1, 0,
			0, 1,
			0, 0,

			1, 0,
			1, 1,
			0, 1,
			1, 0,
			0, 1,
			0, 0,

			1, 0,
			1, 1,
			0, 1,
			1, 0,
			0, 1,
			0, 0,

			1, 0,
			1, 1,
			0, 1,
			1, 0,
			0, 1,
			0, 0,
		];
		vbos[2] = VBO.array(uv.length*float.sizeof).addData(uv);
	}
	string rgbaVertexShader = "#version 330 core
		layout(location = 0) in vec3 vertexPosition_modelspace;
		layout(location = 1) in vec4 vertexColor;

		out vec4 vColor;

		uniform mat4 MVP;

		void main() {	
			gl_Position	= MVP * vec4(vertexPosition_modelspace, 1);
			vColor		= vertexColor;
		}";
	string textureRgbaVertexShader = "#version 330 core
		layout(location = 0) in vec3 vertexPosition_modelspace;
		layout(location = 1) in vec4 vertexColor;
		layout(location = 2) in vec2 vertexUV;

		out vec4 vColor;
		out vec2 UV;

		uniform mat4 MVP;

		void main() {
			gl_Position = MVP * vec4(vertexPosition_modelspace, 1);
			vColor		= vertexColor;
			UV			= vertexUV;
		}";
	string rgbaFragmentShader = "#version 330 core
		in vec4 vColor;

		out vec4 color;

		void main() {
			color = vColor;
		}";
	string textureRgbaFragmentShader = "#version 330 core
		in vec4 vColor;
		in vec2 UV;

		out vec4 color;

		uniform sampler2D textureSampler0;

		void main() {
			color = texture(textureSampler0, UV) * vColor;
		}
		";
}