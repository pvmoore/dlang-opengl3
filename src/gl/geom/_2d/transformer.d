module gl.geom._2d.transformer;

import gl.all;

final class Transformer {
private:
	Vector2 trans = Vector2(0,0);
	float angle  = 0;
	Vector2 size = Vector2(1,1);
	Vector2[] untransformed;
	Vector2[] transformed;
public:
	Vector2 opIndex(long i) { return transformed[i]; }
	auto translate(float x, float y) {
		this.trans = Vector2(x,y);
		return this;
	}
	auto translate(Vector2 t) {
		this.trans = t;
		return this;
	}
	auto rotate(float degrees) {
		this.angle = degrees;
		return this;
	}
	auto scale(float s) {
		this.size = Vector2(s,s);
		return this;
	}
	auto scale(float x, float y) {
		this.size = Vector2(x,y);
		return this;
	}
	auto scale(Vector2 s) {
		this.size = s;
		return this;
	}
	auto verts(Vector2[] verts...) {
		this.untransformed = verts;
		return this;
	}
	auto apply() {
		Matrix4 R = Matrix4.rotateZ(angle.radians);
		Matrix4 S = Matrix4.scale(Vector3(size,0));
		Matrix4 T = Matrix4.translate(Vector3(trans, 0));
		Matrix4 M = T * R * S;
		
		transformed = new Vector2[untransformed.length];
		for(auto i=0;i<untransformed.length;i++) {
			Vector4 v = M * Vector4(untransformed[i], 0, 1);
			transformed[i] = Vector2(v.x, v.y);
		}
		return this;
	}
}