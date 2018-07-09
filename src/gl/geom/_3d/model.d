module gl.geom._3d.model;

import gl.all;

abstract class Model : Geometry3D {
	this(OpenGL gl, VAO vao) {
		super(gl, vao);
	}
}

final class OBJModel : Model {
	Vector3[] vertices;
	UV[] uvs;
	Vector3[] normals;
	Program program;
	VBO[2] vbos; // 0=vertices,1=normals
	//uint textureId;

	this(OpenGL gl, VAO vao, Vector3[] vertices, UV[] uvs, Vector3[] normals) {
		super(gl, vao);
		this.vertices = vertices;
		this.uvs = uvs;
		this.normals = normals;
		this.program = gl.getProgram(
			//gl.getShaderFromFile("shaders/vert/xyz_n_lighting.vert", GL_VERTEX_SHADER), 
			//gl.getShaderFromFile("shaders/frag/lighting.frag", GL_FRAGMENT_SHADER)
			//gl.getShaderFromFile("shaders/vert/diffuse_lighting.vert", GL_VERTEX_SHADER), 
			//gl.getShaderFromFile("shaders/frag/diffuse_lighting.frag", GL_FRAGMENT_SHADER)
			gl.getShaderFromFile("shaders/vert/specular_lighting.vert", GL_VERTEX_SHADER), 
			gl.getShaderFromFile("shaders/frag/specular_lighting.frag", GL_FRAGMENT_SHADER)
		);
		setupVertices();
		setupNormals();
		//setupColours();
		//setupTextures();
	}
	override void destroy() {
		vbos[0].destroy();
		vbos[1].destroy();
		super.destroy();
	}
	override string toString() {
		return "OBJModel[%s verts, %s normals, %s uvs]"
			.format(vertices.length, normals.length, uvs.length);
	}
	override void render() {
		program.use();
		program.setUniform("M", model);
		program.setUniform("V", view);
		program.setUniform("MVP", mvp);
		program.setUniform("LightPosition_worldspace", lightPos);
		program.setUniform("diffuseColour", RGB(1, 0.7, 0.2));
		program.setUniform("specularColour", WHITE.rgb);
		program.setUniform("shineDamping", 10f);
		program.setUniform("reflectivity", 1f);

		// vertices (attrib 0)
		vbos[0].bind();
		vao.enableAttrib(0, 3/*xyz*/); 

		// normals (attrib 1)
		vbos[1].bind();
		vao.enableAttrib(1, 3/*xyz*/); 

		// output the arrays as triangles
		glDrawArrays(GL_TRIANGLES, 0, cast(int)vertices.length);

		vao.disableAttribs();
		program.unuse();
	}
private:
	void setupVertices() {
		vbos[0] = VBO.array(vertices.length*Vector3.sizeof).addData(vertices);
	}
	void setupNormals() {
		log("#normals=%s", normals.length);
		if(normals.length==0) {
			// TODO - create the normals using the vertex faces
			return;
		}
		vbos[1] = VBO.array(normals.length*Vector3.sizeof).addData(normals);
	}
	void setupColours() {

	}
	void setupTextures() {

	}
}
