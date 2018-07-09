module gl.geom._3d.geometry;

import gl.all;

abstract class Geometry3D {
	struct { // model transformations
		float rotateXAngle	= 0;
		float rotateYAngle	= 0;
		float rotateZAngle	= 0;
		Vector3 scaleFactor	= Vector3(1,1,1);
		Vector3 pos			= Vector3(0,0,0);
	}
	struct { 
		Matrix4 model		= Matrix4.identity;
		Matrix4 view		= Matrix4.identity;
		Matrix4 projection	= Matrix4.identity;
		Matrix4 mvp			= Matrix4.identity;
	}
	VAO vao;
	OpenGL gl;
	Vector3 lightPos;

	this(OpenGL gl, VAO vao) {
		this.gl = gl;
		this.vao = vao;
	}
	void destroy() {
	}
	auto setLightPos(ref Vector3 lp) { 
		this.lightPos = lp; 
		return this;
	}
	auto setVP(ref Matrix4 v, ref Matrix4 p) { 
		this.view       = v;
		this.projection = p;
		updateMVP();
		return this;
	}
	auto rotation(float x, float y, float z) {
		this.rotateXAngle = x;
		this.rotateYAngle = y;
		this.rotateZAngle = z;
		updateMVP();
		return this;
	}
	auto position(Vector3 p) {
		this.pos = p;
		updateMVP();
		return this;
	}
	auto scale(Vector3 s) {
		this.scaleFactor = s;
		updateMVP();
		return this;
	}
	abstract void render();
protected:
	void updateMVP() {
		// TODO - optimise this. no need to do translations which are identity
		auto t1 = Matrix4.translate(pos);
		auto t2 = Matrix4.rotate(Vector3(1,0,0), rotateXAngle.radians);
		auto t3 = Matrix4.rotate(Vector3(0,1,0), rotateYAngle.radians);
		auto t4 = Matrix4.rotate(Vector3(0,0,1), rotateZAngle.radians);
		auto t5 = Matrix4.scale(scaleFactor);
		model = t1 * t2 * t3 * t4 * t5;
		//model =  Matrix4.translate(pos) * 
		//		 Matrix4.rotate(Vector3(1,0,0), rotateXAngle) *
		//		 Matrix4.rotate(Vector3(0,1,0), rotateYAngle) *
		//		 Matrix4.rotate(Vector3(0,0,1), rotateZAngle) *
		//		 Matrix4.scale(scaleFactor);
		this.mvp = projection*view*model;
	}
}