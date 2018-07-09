module gl.shader;

import gl.all;

/**
 * types: GL_VERTEX_SHADER
 * 		  GL_FRAGMENT_SHADER
 *		  GL_GEOMETRY_SHADER
 *		  GL_COMPUTE_SHADER
 */
final class Shader {
	GLenum type;
	uint id;
	string name;

	this(GLenum type) {
		this.type = type;
		this.id = glCreateShader(type); 
	}
	auto fromCode(string name, string code) {
		this.name = name;
		logfine("creating %s shader '%s'", type==GL_VERTEX_SHADER ? "vertex":"fragment", name);
		compile(cast(char[])code);
		return this;
	}
	auto fromFile(string filename) {
		this.name = filename;
		logfine("creating %s shader '%s'", type==GL_VERTEX_SHADER ? "vertex":"fragment", name);
		if(!exists(filename)) throw new Exception("Shader '%s' does not exist".format(filename));	
		compile(load(filename));
		return this;
	}
	void destroy() {
		logfine("destroying %s shader '%s'", type==GL_VERTEX_SHADER ? "vertex":"fragment", name);
		if(id) glDeleteShader(id); id = 0;
	}
private:
	char[] load(string filename) {
		auto file = File(filename, "rb");
		return file.rawRead(new char[file.size]);
	}
	void compile(char[] code) {
		char* ptr  = code.ptr;
		int length = cast(int)code.length;
		glShaderSource(id, 1, &ptr, &length);
		glCompileShader(id);

        auto compileLog = getInfoLog();
		int param;
		glGetShaderiv(id, GL_COMPILE_STATUS, &param);
		if(param != GL_TRUE) {
			throw new Exception(format("Compile shader [%s] failed: %s", name, compileLog));
		}
		if(compileLog.length>0) {
            log("Shader '%s' compile log: %s", name, compileLog);
        }
	}
	string getInfoLog() {
	    int infologLength;
	    int charsWritten;
	    char[] infoLog;
	
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &infologLength);
		if(infologLength==0) return "";

        infoLog.length = infologLength;
        glGetShaderInfoLog(id, infologLength, &charsWritten, infoLog.ptr);
		return strip(cast(string)infoLog.ptr.fromStringz);
	}
}