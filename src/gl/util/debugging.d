module gl.util.debugging;

import gl.all;

void enableGLDebugging() {
	if(isExtensionSupported("GL_KHR_debug")) {
		glEnable(GL_DEBUG_OUTPUT);
		glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);

        // This is an OpenGL 4.3 function
		glDebugMessageCallback(&onOpenglDebugEvent, null);

		uint unusedIds = 0;
		glDebugMessageControl(GL_DONT_CARE,	// source
							  GL_DONT_CARE,	// type
							  GL_DONT_CARE,	// severity
							  0,			// count (ids)
							  &unusedIds,	// ids
							  true);		// enabled
		log("GL_KHR_debug logging enabled");
	} else {
		log("GL_KHR_debug not supported :(");
	}
	CheckGLErrors();
}

extern(Windows) {
void onOpenglDebugEvent(GLenum src, GLenum type, GLuint id, GLenum severity, 
					    GLsizei msgLength, const(char)* msgZ, void* userParam) nothrow
{
	try{
	string srcToString() {
		switch(src) {
			case GL_DEBUG_SOURCE_API: return "API";
			case GL_DEBUG_SOURCE_WINDOW_SYSTEM: return "WINDOW_SYSTEM";
			case GL_DEBUG_SOURCE_SHADER_COMPILER: return "SHADER_COMPILER";
			case GL_DEBUG_SOURCE_THIRD_PARTY: return "3RD_PARTY";
			case GL_DEBUG_SOURCE_APPLICATION: return "APPLICATION";
			default: return "OTHER";
		}
	}
	string typeToString() {
		switch(type) {
			case GL_DEBUG_TYPE_ERROR : return "ERROR";
			case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: return "DEPRECATED_BEHAVIOUR";
			case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR: return "UNDEFINED_BEHAVIOUR";
			case GL_DEBUG_TYPE_PORTABILITY: return "PORTABILITY";
			case GL_DEBUG_TYPE_PERFORMANCE: return "PERFORMANCE";
			case GL_DEBUG_TYPE_MARKER: return "MARKER";	
			case GL_DEBUG_TYPE_PUSH_GROUP: return "PUSH_GROUP";
			case GL_DEBUG_TYPE_POP_GROUP: return "POP_GROUP";
			default: return "OTHER"; 
		}
	}
	string severityToString() {
		switch(severity) {
			case GL_DEBUG_SEVERITY_LOW: return "LOW";
			case GL_DEBUG_SEVERITY_MEDIUM: return "MEDIUM";
			case GL_DEBUG_SEVERITY_HIGH: return "HIGH";
			case GL_DEBUG_SEVERITY_NOTIFICATION : return "NOTIFICATION"; 
			default: return "UNKNOWN_SEVERITY";
		}
	}
	string message = cast(string)msgZ[0..msgLength]; 
	log("[gl_debug] [%s-%s-%s] [ID:%s] %s", typeToString(), severityToString(), srcToString(), id, message);
	}catch(Exception e) {
		log("onOpenglDebugEvent: exception thrown %s", e.msg);
	}
}
}
