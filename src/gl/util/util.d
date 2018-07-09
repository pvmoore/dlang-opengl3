module gl.util.util;

import gl.all;

int[2] getGLVersion() {
	int major, minor;
	string verStr = cast(string)fromStringz(glGetString(GL_VERSION)); // eg. "3.2.0"

	major = verStr[0] - '0';
	if(major >= 3) {
		// for GL 3.x
		glGetIntegerv(GL_MAJOR_VERSION, &major); 
		glGetIntegerv(GL_MINOR_VERSION, &minor); 
	} else {
		minor = verStr[2] - '0';
	}
	return [major,minor];
}

/// retrieves all past errors and logs the code. this will empty the error buffer
int CheckGLErrors(string prefix="") {
	int errCount = 0;
	for(GLenum currError = glGetError(); currError != GL_NO_ERROR; currError = glGetError()) {
		log("\t%s found gl error: %s", prefix, getGLErrorString(currError));
		++errCount;
	}
	return errCount;
}

string getGLErrorString(uint err) {
	string s;
	switch(err) {
		case GL_NO_ERROR:			s = "GL_NO_ERROR"; break;           
		case GL_INVALID_VALUE:		s = "GL_INVALID_VALUE"; break;  
		case GL_INVALID_ENUM:		s = "GL_INVALID_ENUM"; break;  
		case GL_INVALID_OPERATION:	s = "GL_INVALID_OPERATION"; break;  
		case GL_STACK_OVERFLOW:		s = "GL_STACK_OVERFLOW"; break;  
		case GL_STACK_UNDERFLOW:	s = "GL_STACK_UNDERFLOW"; break;  
		case GL_OUT_OF_MEMORY:		s = "GL_OUT_OF_MEMORY"; break;  
		default: s = "Unkown error code";
	}
	return s ~ " (%x)".format(err);
}

/// convert vertices into:
///		- an indexed vertex array
///		- an index array. 
Tuple!(Vector3[],ushort[]) getIndexedVertices(Vector3[] vertices) {
	ushort[Vector3] hash;
	ushort[] indexes;
	Vector3[] indexedVertices;
	indexes.assumeSafeAppend();
	indexedVertices.assumeSafeAppend();
	long n;

	foreach(long vi, ref v; vertices) {
		ushort* i = (v in hash);
		if(i) {
			indexes ~= *i;
		} else {
			ushort idx = cast(ushort)indexedVertices.length;
			hash[v] = idx;
			indexes ~= idx;
			indexedVertices ~= v;
			log("[%s] = %s", vi, v);
		}
	}
	//log("indexes=%s", indexes);
	//log("indexedVertices=%s", indexedVertices);
	//log("#vertices=%s #indices=%s", vertices.length, hash.length);
	return Tuple!(Vector3[],ushort[])(indexedVertices, indexes);
}
int getGLInteger(uint name) {
	// some of these return more than 1 value. i make space for 4 but it might not be enough
	int param,p2,p3,p4;
	glGetIntegerv(name, &param);
	return param;
}
void logGLInteger(string name, uint e) {
	log("%s = %s", name, getGLInteger(e));
}
void logGlInfo() {
	log("GLFW = %s", glfwGetVersionString().fromStringz);
	log("vendor = %s", fromStringz(glGetString(GL_VENDOR)));
	log("version = %s", fromStringz(glGetString(GL_VERSION)));
	log("glsl version = %s", fromStringz(glGetString(GL_SHADING_LANGUAGE_VERSION)));
	log("renderer = %s", fromStringz(glGetString(GL_RENDERER)));
	logGLInteger("GL_MAX_GEOMETRY_OUTPUT_VERTICES", GL_MAX_GEOMETRY_OUTPUT_VERTICES);
	logGLInteger("GL_MAX_GEOMETRY_OUTPUT_COMPONENTS", GL_MAX_GEOMETRY_OUTPUT_COMPONENTS);
	logGLInteger("GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS", GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS);
	logGLInteger("GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT", GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT);
	logGLInteger("GL_MAX_UNIFORM_BUFFER_BINDINGS", GL_MAX_UNIFORM_BUFFER_BINDINGS);
	logGLInteger("GL_MAX_UNIFORM_BUFFER_BINDINGS", GL_MAX_UNIFORM_BUFFER_BINDINGS);
	logGLInteger("GL_MAX_UNIFORM_BLOCK_SIZE", GL_MAX_UNIFORM_BLOCK_SIZE);
	logGLInteger("GL_MAX_ELEMENTS_VERTICES", GL_MAX_ELEMENTS_VERTICES);
	logGLInteger("GL_MAX_ELEMENTS_INDICES", GL_MAX_ELEMENTS_INDICES);
	logGLInteger("GL_MAX_VERTEX_ATTRIBS", GL_MAX_VERTEX_ATTRIBS);

	logGLInteger("GL_MAX_TEXTURE_SIZE", GL_MAX_TEXTURE_SIZE);
	logGLInteger("GL_MAX_3D_TEXTURE_SIZE", GL_MAX_3D_TEXTURE_SIZE);
	logGLInteger("GL_MAX_CUBE_MAP_TEXTURE_SIZE", GL_MAX_CUBE_MAP_TEXTURE_SIZE);
	logGLInteger("GL_MAX_TEXTURE_IMAGE_UNITS", GL_MAX_TEXTURE_IMAGE_UNITS);
}
void logExtensions() {
	//if(wglGetExtensionsStringARB) {
	//	string extensions = fromStringz(wglGetExtensionsStringARB(hdc));
	//	log("WGL extensions = %s", extensions);
	//}
	logGLInteger("GL_NUM_EXTENSIONS", GL_NUM_EXTENSIONS);
	int numExtensions = getGLInteger(GL_NUM_EXTENSIONS);
	log("GL_EXTENSIONS {");
	for(auto i=0;i<numExtensions;i++) {
		log("\t%s", fromStringz(glGetStringi(GL_EXTENSIONS, i)));	
	}
	log("}");
}

// TODO - cache the results of this
bool isExtensionSupported(string extension) {
	return glfwExtensionSupported(extension.toStringz) == GL_TRUE;
}

/+
uint loadTexture(string filename) {
	IFImage img = read_image(filename);
	log("loaded image '%s' (%s,%s) %s %s bytes", filename, img.w, img.h, 
		(img.c==ColFmt.RGB ? "RGB" : img.c==ColFmt.RGBA ? "RGBA" : "Unknown" ),
		img.pixels.length);

	uint imageFormat = img.c==ColFmt.RGB ? GL_RGB : GL_RGBA;
	uint textureID;
	glGenTextures(1, &textureID);
	glBindTexture(GL_TEXTURE_2D, textureID);

	// Give the image to OpenGL
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, cast(uint)img.w, cast(uint)img.h, 
				 0, GL_BGR, GL_UNSIGNED_BYTE, img.pixels.ptr);
	uint err  = glGetError();
	if(err) {
		log("glTexImage2D(filename %s) returned error %s", filename, getGLErrorString(err));
	} else {
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // GL_LINEAR_MIPMAP_LINEAR
		//glGenerateMipmap(GL_TEXTURE_2D); // crashes

		/* // this crashes
		// Nice trilinear filtering.
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glGenerateMipmap(GL_TEXTURE_2D);
		*/

		log("texture '%s' successfully loaded into OpenGL as id %s", filename, textureID);
	}
	return textureID;
}
+/

/**
 * Gets AMD specific video memory info. Note that this
 * seems to always return the same info and
 * gives a debug warning when used. Possibly not worth using.
 *
 * Call with one of:
 *      VBO_FREE_MEMORY_ATI
 *      TEXTURE_FREE_MEMORY_ATI
 *      RENDERBUFFER_FREE_MEMORY_ATI
 *
 * param[0] - total memory free in the pool (KB)
 * param[1] - largest available free block in the pool (KB)
 * param[2] - total auxiliary memory free (KB)
 * param[3] - largest auxiliary free block (KB)
 */
int[4] getAMDMemInfo(uint e) {
    int[4] i;
    glGetIntegerv(e, i.ptr);
    CheckGLErrors();
    return i;
}