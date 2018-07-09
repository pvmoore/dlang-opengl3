module gl.renderers.sphererenderer3d;

import gl.all;

final struct SphereData {
	Vector3 centre;
	float radius;
	RGBA colour;
}

final class SphereRenderer3D : Renderer {
	SphereData[] points;

	this(OpenGL gl) {
		super(gl);
	}
	auto cameraUpdate(Camera3D cam) {
	    super.setVP(cam.VP);
	    prog.setUniform("CAMERA_UP", cam.up);
	    prog.setUniform("CAMERA_RIGHT", cam.right);
	    prog.setUniform("ASPECT_RATIO", cam.aspectRatio);
	    return this;
	}
	override Renderer setVP(Matrix4 viewProj) {
        throw new Error("Use cameraUpdate(Camera3D)");
	}
	auto clear() {
		this.points.length = 0;
		dataChanged = true;
		return this;
	}
	auto updateSpherePos(int index, Vector3 pos) {
		points[index].centre = pos;
		dataChanged = true;
		return this;
	}
	auto addSphere(Vector3 pos, float radius, RGBA colour) {
		return addSpheres(SphereData(
			pos, radius, colour)
		);
	}
	auto addSpheres(SphereData[] points...) {
		this.points ~= points;
		dataChanged = true;
		return this;
	}
protected:
	@property override ulong numPoints() { return points.length; }
	override Program createProgram() {
		return gl.getProgram(
			gl.getShaderFromCode("SphereRenderer3D-vs", vs, GL_VERTEX_SHADER),
			gl.getShaderFromCode("SphereRenderer3D-gs", gs, GL_GEOMETRY_SHADER),
			gl.getShaderFromCode("SphereRenderer3D-fs", fs, GL_FRAGMENT_SHADER)
		);
	}
	override void populateVbo() {
		if(!dataChanged) return;

		const int ELEMENT_SIZE =
		    Vector3.sizeof +
		    Vector4.sizeof +
		    float.sizeof;

		long bytesRequired = points.length*ELEMENT_SIZE;

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

		ubyte* ptr = buf.ptr;
		foreach(p; points) {
			*(cast(Vector3*)ptr) = p.centre;
			ptr += Vector3.sizeof;

			*(cast(Vector4*)ptr) = p.colour;
			ptr += Vector4.sizeof;

			*(cast(float*)ptr) = p.radius;
			ptr += float.sizeof;
		}
		vbo.addData(buf[0..bytesRequired]);
		vao.enableAttrib(0, 3, GL_FLOAT, false, ELEMENT_SIZE, 0);
		vao.enableAttrib(1, 4, GL_FLOAT, false, ELEMENT_SIZE, Vector3.sizeof);
		vao.enableAttrib(2, 1, GL_FLOAT, false, ELEMENT_SIZE, Vector3.sizeof+Vector4.sizeof);

		dataChanged = false;
	}
private:
	string vs = "#version 330 core
		layout(location = 0) in vec3 pos;
		layout(location = 1) in vec4 colour;
		layout(location = 2) in float radius;

		out VS_OUT {
			vec3 pos;
			vec4 colour;
			float radius;
		} vs_out;

		void main() {
			vs_out.pos			 = pos;
			vs_out.colour	     = colour;
			vs_out.radius		 = radius;
		}";
	string gs = "#version 330 core
		layout(points) in;
		layout(triangle_strip, max_vertices = 4) out;

		uniform mat4 VP;
		uniform vec3 CAMERA_UP;
		uniform vec3 CAMERA_RIGHT;

		in VS_OUT {
            vec3 pos;
            vec4 colour;
            float radius;
        } gs_in[];

		out GS_OUT {
			vec2 pos;
			vec4 colour;
			float radius;
		} gs_out;

		void main() {
		    float r   = gs_in[0].radius;
		    vec3 pos  = gs_in[0].pos;
		    vec3 w    = CAMERA_RIGHT*r;
		    vec3 h    = CAMERA_UP*r;

			vec4 pos0    = VP * vec4(pos-w+h, 1);
			vec4 pos2    = VP * vec4(pos+w-h, 1);
			vec4 pos1    = VP * vec4(pos+w+h, 1);
			vec4 pos3    = VP * vec4(pos-w-h, 1);

            vec4 mid = VP * vec4(pos, 1);
			float r2 = pos2.x-mid.x;

			gl_Position		 = pos0;
			gs_out.pos		 = pos0.xy-mid.xy;
			gs_out.colour    = gs_in[0].colour;
			gs_out.radius	 = r2;
			EmitVertex();

			gl_Position		 = pos1;
			gs_out.pos		 = pos1.xy-mid.xy;
			gs_out.colour    = gs_in[0].colour;
            gs_out.radius	 = r2;
			EmitVertex();

			gl_Position		 = pos3;
			gs_out.pos		 = pos3.xy-mid.xy;
            gs_out.colour    = gs_in[0].colour;
			gs_out.radius	 = r2;
			EmitVertex();

			gl_Position		 = pos2;
			gs_out.pos	     = pos2.xy-mid.xy;
            gs_out.colour    = gs_in[0].colour;
			gs_out.radius	 = r2;
			EmitVertex();

			EndPrimitive();
		}";
	string fs = "#version 330 core
		out vec4 color;

		uniform float ASPECT_RATIO;
		vec2 lengthMul = vec2(1, 1/ASPECT_RATIO);

		in GS_OUT {
			vec2 pos;
			vec4 colour;
			float radius;
		} fs_in;

		void main() {
			float dist = length(fs_in.pos*lengthMul);
			if(dist > fs_in.radius) {
			    discard;
			} else {
				color = fs_in.colour;
			}
		}";
}