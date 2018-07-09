module gl.program;

import gl.all;

final class Program {
	uint id;
	string[] shaderNames;
	int[string] uniformLocations;
	uint uboHandle;	// TODO - allow more than 1 of these
	
	this() {
		this.id = glCreateProgram();
	}
	/// loads a compute shader program
	Program loadCompute(string file,
	                    string[] includes,
	                    string[] defines)
    {
        auto shaderReader = new ShaderCodeReader(
            file, includes, defines
        );
        string code = shaderReader.read();
        //log("code=%s", code);
        auto shader = new Shader(GL_COMPUTE_SHADER);
        shader.fromCode(file, code);
        attach(shader);
		link();
		detach(shader);
		shader.destroy();
		return this;
	}
	/// loads a unified .shader file
	Program fromFile(string filename) {
		auto file = File(filename, "rb");
		string src = cast(string)file.rawRead(new char[file.size]);
		auto vshaderPos = src.indexOf("//VERTEXSHADER");
        auto gshaderPos = src.indexOf("//GEOMETRYSHADER");
        auto fshaderPos = src.indexOf("//FRAGMENTSHADER");

		auto shaders = appender!(Shader[]);
		shaders ~= new Shader(GL_FRAGMENT_SHADER)
					 .fromCode(filename, src[fshaderPos..$]);

        if(gshaderPos != -1) {
			shaders ~= new Shader(GL_GEOMETRY_SHADER)
						.fromCode(filename, src[gshaderPos..fshaderPos]);
        } else {
            gshaderPos = fshaderPos;
        }
		shaders ~= new Shader(GL_VERTEX_SHADER)
					.fromCode(filename, src[vshaderPos..gshaderPos]);

		attach(shaders.data);
		link();
		detach(shaders.data);
		shaders.data.each!(it=>it.destroy());
		return this;
	}
	void destroy() {
		if(id) glDeleteProgram(id); id = 0;
		if(uboHandle) glDeleteBuffers(1, &uboHandle); uboHandle = 0; 
	}
	auto use() {
		glUseProgram(id);
		return this;
	}
	auto unuse() {
		glUseProgram(0);
		return this;
	}
	void link() {
		glLinkProgram(id); 

		int param;
		glGetProgramiv(id, GL_LINK_STATUS, &param);
		if(param != GL_TRUE) {
			throw new Exception("Link failed");
		}	 
	}
	void attach(Shader[] shaders...) {
		foreach(Shader s; shaders) {
			glAttachShader(id, s.id);
			shaderNames ~= s.name;
		}
	}
	void detach(Shader[] shaders...) {
		foreach(Shader s; shaders) {
			glDetachShader(id, s.id);
		}
	}
	void logUniformInfo(string name) {
		int length;
		int size;
		uint type;
		char[] info; info.length=1000;
		glGetActiveUniform(id, getUniformLocation(name), cast(int)info.length, 
						   &length, &size, &type, info.ptr);
		logIfError("glGetActiveUniform(%s)".format(name));
		log("info for uniform '%s': name=%s, type=%x size=%s", name, fromStringz(info.ptr), type, size);
	}
	/**
		Set uniform buffer data.
		eg.
		uniform GlyphData {
			vec4 aa[2];
			float bb;
		};
		setUniformBlockData("GlyphData", ["aa[0]","bb"], [[1,2,3,4,5,6,7,8],[1]);
		Note that arrays are generally assumed to have a 16 byte stride so prefer vec4 if possible.
	*/
	void setUniformBlockData(string blockName, string[] elementNames, ubyte[][] data) {
		uint blockIndex = getUniformBlockIndex(blockName);
		if(blockIndex==-1) {
			logwarn("unable to find uniform block %s", blockName);
			return;
		}
		int blockSize;
		glGetActiveUniformBlockiv(id, blockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &blockSize);
		uint err = glGetError();
		if(err) {
			log("glGetActiveUniformBlockiv(%s) %s".format(blockName, getGLErrorString(err)));
			return;
		}
		log("blockSize = %s", blockSize);
		auto names = elementNames.map!(it=>it.toStringz).array();
		uint[] indices = new uint[elementNames.length];
		glGetUniformIndices(id, cast(int)indices.length, names.ptr, indices.ptr); 
		err = glGetError();
		if(indices.any!(it=>it==-1)) {
			logwarn("one of the uniform buffer indices was not found");
		}
		if(err) {
			log("glGetUniformIndices(%s) %s".format(blockName, getGLErrorString(err)));
			return;
		}
		log("indices=%s", indices);
		int[] offsets = new int[elementNames.length];
		int[] sizes = new int[elementNames.length];
		glGetActiveUniformsiv(id, cast(int)indices.length, indices.ptr, GL_UNIFORM_OFFSET, offsets.ptr);
		glGetActiveUniformsiv(id, cast(int)indices.length, indices.ptr, GL_UNIFORM_SIZE, sizes.ptr);
		err = glGetError();
		if(err) {
			log("glGetActiveUniformsiv(%s) %s".format(blockName, getGLErrorString(err)));
			return;
		}
		log("offsets=%s", offsets);
		log("sizes=%s", sizes);
		ubyte[] block = new ubyte[blockSize];

		foreach(long i, ubyte[] d; data) {
			ubyte* ptr = block.ptr+offsets[i];
			ptr[0..d.length] = d;
		}

		//float* fp = cast(float*)(block.ptr+offsets[0]);
		//fp[0] = 1f;
		//fp[1] = 1f;
		//fp[2] = 1f;
		//fp[3] = 1f;
		//fp[4] = 1f;
		//fp[8] = 1f;

		//fp = cast(float*)(block.ptr+offsets[1]);
		//fp[0] = 1f;

		log("buffer=%s", block);
		glGenBuffers(1, &uboHandle);
		glBindBuffer(GL_UNIFORM_BUFFER, uboHandle);
		glBufferData(GL_UNIFORM_BUFFER, blockSize, block.ptr, GL_DYNAMIC_DRAW);

		glBindBufferBase(GL_UNIFORM_BUFFER, blockIndex, uboHandle);	
	}
	uint getUniformBlockIndex(string blockName) {
		uint index = glGetUniformBlockIndex(id, blockName.toStringz);
		logIfError("glGetUniformBlockIndex(%s)".format(blockName));
		return index;
	}
	int getUniformLocation(string name) {
		int* p = (name in uniformLocations);
		if(p) return *p;
		int location = glGetUniformLocation(id, name.toStringz);
		uint err  = glGetError();
		if(err) {
			log("glGetUniformLocation(name %s) returned error %s (shaders: %s)", 
				name, getGLErrorString(err), shaderNames);
		}
		debug if(location==-1) { 
			logwarn("uniform %s not found in program (shaders:%s)", name, shaderNames);
		}
		uniformLocations[name] = location;
		return location;
	}
	auto setUniform(T)(string name, T value) {
	    //log("setUniform(%s,%s)",name, value);
		setUniform(getUniformLocation(name), value);
		return this;
	}
	auto setUniform(T)(string name, ref T value) {
	    //log("setUniform(%s,%s)",name, value);
		setUniform(getUniformLocation(name), value);
		return this;
	}
private:
	auto setUniform(int id, int value) {
		glUniform1i(id, value);
		logIfError("glUniform1i(%s,%s)".format(id, value));
		return this;
	}
	auto setUniform(int id, ivec2 value) {
        glUniform2i(id, value.x, value.y);
        logIfError("glUniform2i(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, ivec3 value) {
        // NB. glUniform3i is not bound in derelict-gl3
        // so if this suddenly stops working you know why...
        glUniform3i(id, value.x, value.y, value.z);
        logIfError("glUniform3i(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, ivec3[] values) {
        glUniform3iv(id, cast(uint)values.length, cast(int*)values.ptr);
        logIfError("glUniform3iv(%s,%s)".format(id, values));
        return this;
    }
    auto setUniform(int id, ivec4 value) {
        glUniform4i(id, value.x, value.y, value.z, value.w);
        logIfError("glUniform4i(%s,%s)".format(id, value));
        return this;
    }
	auto setUniform(int id, uvec2 value) {
        glUniform2ui(id, value.x, value.y);
        logIfError("glUniform2ui(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, uvec3 value) {
        glUniform3ui(id, value.x, value.y, value.z);
        logIfError("glUniform3ui(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, uvec4 value) {
        glUniform4ui(id, value.x, value.y, value.z, value.w);
        logIfError("glUniform4ui(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, vec2 value) {
        glUniform2f(id, value.x, value.y);
        logIfError("glUniform2f(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, vec3 value) {
        glUniform3f(id, value.x, value.y, value.z);
        logIfError("glUniform3f(%s,%s)".format(id, value));
        return this;
    }
    auto setUniform(int id, vec3[] values) {
        glUniform3fv(id, cast(uint)values.length, cast(float*)values.ptr);
        logIfError("glUniform3fv(%s,%s)".format(id, values));
        return this;
    }
    auto setUniform(int id, vec4 value) {
        glUniform4f(id, value.x, value.y, value.z, value.w);
        logIfError("glUniform4f(%s,%s)".format(id, value));
        return this;
    }
	auto setUniform(int id, float value) {
		glUniform1f(id, value);
		logIfError("glUniform1f(id %s, %s)".format(id, value));
		return this;
	}
	auto setUniform(int id, ref vec2 v) {
		glUniform2f(id, v.x, v.y);
		logIfError("glUniform2f(id %s, Vector2)".format(id));
		return this;
	}
	auto setUniform(int id, ref vec3 v) {
		glUniform3f(id, v.x, v.y, v.z);
		logIfError("glUniform3f(id %s, Vector3)".format(id));
		return this;
	}
	auto setUniform(int id, ref vec4 v) {
		glUniform4f(id, v.x, v.y, v.z, v.w);
		logIfError("glUniform4f(id %s, Vector4)".format(id));
		return this;
	}
	auto setUniform(int id, float[] floats) {
		glUniform1fv(id, cast(int)floats.length, floats.ptr);
		logIfError("glUniform1fv(id %s, float[])".format(id));
		return this;
	}
	auto setUniform(int id, ref Matrix4 m) {
		glUniformMatrix4fv(id, 1, GL_FALSE, m.ptr);
		logIfError("glUniformMatrix4fv(id %s, Matrix4)".format(id));
		return this;
	}
	void logIfError(string func) {
		uint err = glGetError();
		if(err) {
			log("!! %s error %s", func, getGLErrorString(err));
		}
	}
}