module gl.opengl;
/**
	Read these optimisation and best practices articles:
    https://www.opengl.org/wiki/Category:Best_Practices
    https://www.opengl.org/wiki/GLSL_:_common_mistakes
    https://www.opengl.org/wiki/GLSL_:_recommendations
    https://www.opengl.org/wiki/Vertex_Specification_Best_Practices
    https://www.opengl.org/wiki/GLSL_Optimizations
*/
import gl.all;
import core.sys.windows.windows : HDC, HGLRC;

pragma(lib, "gdi32.lib");
pragma(lib, "user32.lib");
version = NanovgGL3;

enum MouseButton : uint { LEFT, MIDDLE, RIGHT }
enum KeyMod : uint { NONE=0, SHIFT=GLFW_MOD_SHIFT, CONTROL=GLFW_MOD_CONTROL, ALT=GLFW_MOD_ALT }

interface ApplicationListener {
	void keyPress(uint keyCode, uint scanCode, bool down, uint mods) nothrow;
	void mouseButton(uint button, float x, float y, bool down, uint mods) nothrow;
	void mouseMoved(float x, float y) nothrow;
	void mouseWheel(float xdelta, float ydelta, float x, float y) nothrow;
	void render(long actualFrameNumber, long normalisedFrameNumber, float timeDelta);
}
class ApplicationListenerAdapter : ApplicationListener {
	void keyPress(uint keyCode, uint scanCode, bool down, uint mods) nothrow {}
	void mouseButton(uint button, float x, float y, bool down, uint mods) nothrow {}
	void mouseMoved(float x, float y) nothrow {}
	void mouseWheel(float xdelta, float ydelta, float x, float y) nothrow {}
	void render(long actualFrameNumber, long normalisedFrameNumber, float timeDelta) {}
}
final struct MouseState {
	Vector2 pos;
	int button = -1;
	float wheel = 0;
	Vector2 dragStart;
	Vector2 dragEnd;
	bool isDragging;
	string toString() {
		return "pos:%s button:%s wheel:%s dragging:%s dragStart:%s dragEnd:%s"
			.format(pos, button, wheel, isDragging, dragStart, dragEnd);
	}
}
final class Hints {
	int width         = 800;
	int height        = 800;
	bool windowed     = true;
	bool decorated    = true;
	bool resizable    = false;
	bool autoIconify  = false;
	bool vsync		  = false;
	int samples       = 8;
	bool showWindow   = true;
	string title	  = "OpenGL";
	bool ui           = false;
	uint glVersionMaj = 3;
	uint glVersionMin = 3;
	string fontDirectory = "/pvmoore/_assets/fonts/hiero/";
}
final class Font {
    string name;
    SDFFont sdf;
    uint textureId;
}

__gshared ApplicationListener listener;	
__gshared MouseState g_mouseState;

// -----------------------------------------------------------------------------
final class OpenGL {
private:
	GLFWwindow* window;
	Hints hints = new Hints();
	bool flipAfterRender = true;
	Shader[string] shaders;
	Program[] programs;
	Renderer[] renderers;
	uint targetFPS = 60;
	ulong targetFrameTimeNsecs = 1_000_000_000/60;
    ulong frameNumber;
    float currentFPS = 0;
    Font[string] fonts;
public:
    Textures textures;
    UI ui;

	/// new OpenGL(this, (h) { h.width = x; h.height = y; });
	this(ApplicationListener theListener, void delegate(Hints h) call) {
		listener = theListener;
		call(hints);
		init();
	}
	this(ApplicationListener theListener, string title, uint width, uint height, bool windowed) {
		listener = theListener;

		hints.width = width;
		hints.height = height;
		hints.windowed = windowed;
		hints.title = title;

		init();
	}
	void destroy() {
		log("Destroying OpenGL");

		foreach(f; fonts.values) {
            glDeleteTextures(1, &f.textureId);
		}
		log("destroyed %s fonts", fonts.length);
        fonts = null;
		foreach(s; shaders.values) {
			s.destroy();
		}
		log("destroyed %s shaders", shaders.length);
		shaders = null;

		foreach(p; programs) {
			p.destroy();
		}
		log("destroyed %s programs", programs.length);
		programs = null;

		foreach(r; renderers) {
			r.destroy();
		}
		log("destroyed %s Renderers", renderers.length);
		renderers = null;

		textures.destroy();

        if(ui) {
            ui.destroy();
        }
		glfwTerminate();
		DerelictGLFW3.unload();
		DerelictGL3.unload();
	}
	
	void enterMainLoop() {
		StopWatch watch;
		ulong lastFrameTotalNsecs = 0;
		double currentSpeedDelta = 1;
		double normalisedFrameNumber = 1;
		uint actualFpsCounter;
		double normalisedFpsCounter = 0;
        double totalFPS = 0;
		watch.start();
		while(!glfwWindowShouldClose(window)) {

			listener.render(++frameNumber, 
							cast(long)normalisedFrameNumber, 
							cast(float)currentSpeedDelta);

			if(ui) ui.render();

			if(flipAfterRender) {
				flip();
			}
			glfwPollEvents();

			// update timing information
			long totalNsecs = watch.peek().total!"nsecs";
			//double seconds = totalNsecs/1_000_000_000.0;
			long frameNsecs = totalNsecs - lastFrameTotalNsecs;
			lastFrameTotalNsecs = totalNsecs;

			currentSpeedDelta = cast(double)frameNsecs/targetFrameTimeNsecs;
			normalisedFrameNumber += currentSpeedDelta;

            double fps = targetFPS/currentSpeedDelta;

            totalFPS += fps;
            actualFpsCounter++;
            normalisedFpsCounter += currentSpeedDelta;

			if(normalisedFpsCounter>targetFPS) {
                currentFPS = cast(float)(totalFPS/actualFpsCounter);
                actualFpsCounter = 0;
                normalisedFpsCounter = 0;
                totalFPS   = 0;
            }

			//log("speedDelta %s totalSpeedDelta %s seconds %s frameNsecs %s totalNsecs %s", 
			//	currentSpeedDelta, totalSpeedDelta, seconds, frameNsecs, totalNsecs);
		}
	}
	void flip() {
		glfwSwapBuffers(window);
	}
	void showWindow(bool show) {
        if(show) glfwShowWindow(window);
        else glfwHideWindow(window);
	}

	float FPS() { return currentFPS; }

	HGLRC getGLContext() {
		*(cast(void**)&wglGetCurrentContext) = glfwGetProcAddress("wglGetCurrentContext");
		return wglGetCurrentContext();
	}
	HDC getDC() {
		*(cast(void**)&wglGetCurrentDC) = glfwGetProcAddress("wglGetCurrentDC");
		return wglGetCurrentDC();
	}
	Dimension windowSize() {
		int w, h;
		glfwGetWindowSize(window, &w, &h);
		return Dimension(w,h);
	}
 	Dimension frameBufferSize() {
		int w, h;
		glfwGetFramebufferSize(window, &w, &h);
		return Dimension(w,h);
	}
	Tuple!(float,float) mousePos() {
		double x,y;
		glfwGetCursorPos(window, &x, &y);
		return Tuple!(float,float)(cast(float)x, cast(float)y); 
	}
	MouseState mouseState() {
        MouseState state = g_mouseState;
        g_mouseState.wheel = 0;
        return state;
    }
	/// http://www.glfw.org/docs/3.0/group__keys.html
	bool isKeyPressed(uint key) {
		return glfwGetKey(window, key) == GLFW_PRESS;
	}
	bool isMouseButtonPressed(int button) {
		return glfwGetMouseButton(window, button) == GLFW_PRESS;
	}
	void setTargetFPS(int fps) {
	    targetFPS = fps;
		targetFrameTimeNsecs = 1_000_000_000/fps;
	}
	void setWindowTitle(string title) {
		hints.title = title;
		glfwSetWindowTitle(window, title.toStringz);
	}
	void setWindowIcon() {
		// TODO
	}
	void setMouseCursorVisible(bool visible) {
		glfwSetInputMode(window, GLFW_CURSOR, visible? GLFW_CURSOR_NORMAL : GLFW_CURSOR_HIDDEN); 
	}
	auto getLineRenderer() {
		auto l = new LineRenderer(this);
		renderers ~= l;
		return l;
	}
	auto getCircleRenderer() {
		auto r = new CircleRenderer(this);
		renderers ~= r;
		return r;
	}
	auto getGridRenderer(float x, float y, float w, float h, RGBA colour=WHITE) {
		auto r = new GridRenderer(this,x,y,w,h,colour);
		renderers ~= r;
		return r;
	}
	auto getSpriteRenderer() {
		auto r = new SpriteRenderer(this);
		renderers ~= r;
		return r;
	}
	auto getOutlineRectangleRenderer() {
		auto r = new OutlineRectangleRenderer(this);
		renderers ~= r;
		return r;
	}
	auto getFilledRectangleRenderer() {
		auto r = new FilledRectangleRenderer(this);
		renderers ~= r;
		return r;
	}
	/// reads and parses a unified .shader file
	Program getProgramFromFile(string filename) {
		auto p = new Program().fromFile(filename);
		programs ~= p;
		return p;
	}
	Program getProgram(Shader[] shaders...) {
		Program program = new Program();
		program.attach(shaders);
		program.link();
		program.detach(shaders);
		programs ~= program;
		return program;
	}
	Shader getShaderFromCode(string name, string code, uint type) {
		Shader* s = (name in shaders);
		if(s) return *s;
		Shader shader = new Shader(type).fromCode(name, code);
		shaders[name] = shader;
		return shader;
	}
	Shader getShaderFromFile(string filename, uint type) {
		Shader* s = (filename in shaders);
		if(s) return *s;
		Shader shader = new Shader(type).fromFile(filename);
		shaders[filename] = shader;
		return shader;
	}
	Font getFont(string name) {
	    auto p = name in fonts;
	    if(p) return *p;

	    Font f = new Font;
	    f.name = name;
	    f.sdf  = new SDFFont(hints.fontDirectory, name);

        glGenTextures(1, &f.textureId);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, f.textureId);

        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED,
                     f.sdf.width, f.sdf.height,
                     0,  GL_RED, GL_UNSIGNED_BYTE,
                     f.sdf.getData().ptr);
        uint err = glGetError();
        if(err) {
            log("getFont: error %s", err); flushLog();
            throw new Error("getFont: Unable to create font texture %s".format(err));
        }
        fonts[name] = f;
        return f;
	}
private:
	void init() {
		this.textures = new Textures();

		DerelictGL3.load();
		DerelictGLFW3.load();

		if(!glfwInit()) {
			glfwTerminate();
			throw new Exception("glfwInit failed");
		}

		glfwSetErrorCallback(&errorCallback);

		GLFWmonitor* monitor = glfwGetPrimaryMonitor();
		auto vidmode = glfwGetVideoMode(monitor);
		if(hints.windowed) {
			monitor = null;
			if(hints.width==0 || hints.height==0) {
			    hints.width  = vidmode.width;
                hints.height = vidmode.height;
			}
			glfwWindowHint(GLFW_VISIBLE, GL_FALSE);
            glfwWindowHint(GLFW_RESIZABLE, hints.resizable ? GL_TRUE : GL_FALSE);
            glfwWindowHint(GLFW_DECORATED, hints.decorated ? GL_TRUE : GL_FALSE);
		} else {
			//glfwWindowHint(GLFW_REFRESH_RATE, 60);
			hints.width  = vidmode.width;
            hints.height = vidmode.height;
		}

		// OpenGL hints
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, hints.glVersionMaj);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, hints.glVersionMin);
		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
		glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

		// other window hints
		glfwWindowHint(GLFW_DOUBLEBUFFER, GL_TRUE);
		if(hints.samples > 0) {
            glfwWindowHint(GLFW_SAMPLES, hints.samples);
        }
		glfwWindowHint(GLFW_AUTO_ICONIFY, hints.autoIconify ? GL_TRUE : GL_FALSE);

		// create window and enable OpenGL context
		window = glfwCreateWindow(hints.width, hints.height, hints.title.toStringz, monitor, null);
		if(!window) {
			glfwTerminate();
			throw new Exception("glfwCreateWindow failed");
		}
		glfwMakeContextCurrent(window);

		if(hints.vsync) {
			glfwSwapInterval(1);
		} else {
			glfwSwapInterval(0);
		}

		glfwSetKeyCallback(window, &onKeyEvent);
		glfwSetWindowFocusCallback(window, &onWindowFocusEvent);
		glfwSetMouseButtonCallback(window, &onMouseClickEvent);
		glfwSetScrollCallback(window, &onScrollEvent);
		glfwSetCursorPosCallback(window, &onMouseMoveEvent);
		glfwSetCursorEnterCallback(window, &onMouseEnterEvent);
		glfwSetWindowIconifyCallback(window, &onIconifyEvent);

		//glfwSetWindowRefreshCallback(window, &refreshWindow);
		//glfwSetWindowSizeCallback(window, &resizeWindow);
		//glfwSetWindowCloseCallback(window, &onWindowCloseEvent);
		//glfwSetDropCallback(window, &onDropEvent);

		//glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);

        log("Reloading GL3"); flushLog();

		DerelictGL3.reload();

		log("GL3 reloaded successfully"); flushLog();

		if(hints.ui) {
            ui = new UI(this, Rect(0,0,hints.width, hints.height));
        }

		if(hints.windowed) {
			glfwSetWindowPos(
				window,
				((cast(int)vidmode.width - hints.width) / 2),
				((cast(int)vidmode.height - hints.height) / 2)
			);
		}

        if(hints.glVersionMaj>=4 && hints.glVersionMin>=3) {
		    enableGLDebugging();
		}
		logGlInfo();
		debug logExtensions();

		if(hints.showWindow) {
            showWindow(true);
        }
	}
}
// --------------------------------------------------------------------------------------------
extern(Windows) {
__gshared HGLRC function() wglGetCurrentContext;
__gshared HDC function() wglGetCurrentDC;
}
extern(C) {
void errorCallback(int error, const(char)* description) nothrow {
    log("glfw error: %s %s", error, description);
}
void onKeyEvent(GLFWwindow* window, int key, int scancode, int state, int mods) nothrow {
	if(key == GLFW_KEY_ESCAPE && state == GLFW_PRESS) {
		glfwSetWindowShouldClose(window, true);
		return;
	}
	bool pressed	= (state == GLFW_PRESS);
	//bool release	= (state == GLFW_RELEASE);
	//bool repeat		= (state == GLFW_REPEAT);
	//bool shiftClick = (mods & GLFW_MOD_SHIFT) != 0;
	//bool ctrlClick	= (mods & GLFW_MOD_CONTROL) != 0;
	//bool altClick	= (mods & GLFW_MOD_ALT ) != 0;
	listener.keyPress(key, scancode, pressed, mods);
}
void onWindowFocusEvent(GLFWwindow* window, int focussed) nothrow {
	//log("window focus changed to %s FOCUS", focussed?"GAINED":"LOST");
}
void onIconifyEvent(GLFWwindow* window, int iconified) nothrow {
	//log("window %s", iconified ? "iconified":"non iconified");
}
void onMouseClickEvent(GLFWwindow* window, int button, int action, int mods) nothrow {
	bool pressed = (action == 1);
	double x,y;
	glfwGetCursorPos(window, &x, &y);
	listener.mouseButton(button, cast(float)x, cast(float)y, pressed, mods);

	if(pressed) {
		g_mouseState.button = button;
	} else {
		g_mouseState.button = -1;
		if(g_mouseState.isDragging) {
			g_mouseState.isDragging = false;
			g_mouseState.dragEnd = Vector2(x,y);
		}
	}
}
void onMouseMoveEvent(GLFWwindow* window, double x, double y) nothrow {
	//log("mouse move %s %s", x, y);
	listener.mouseMoved(cast(float)x, cast(float)y);
	g_mouseState.pos = Vector2(x,y); 
	if(!g_mouseState.isDragging && g_mouseState.button >= 0) {
		g_mouseState.isDragging = true;
		g_mouseState.dragStart = Vector2(x,y);
	}
}
void onScrollEvent(GLFWwindow* window, double xoffset, double yoffset) nothrow {
	//log("scroll event: %s %s", xoffset, yoffset);
	double x,y;
	glfwGetCursorPos(window, &x, &y);
	listener.mouseWheel(cast(float)xoffset, cast(float)yoffset, cast(float)x, cast(float)y);
	g_mouseState.wheel += yoffset;
}
void onMouseEnterEvent(GLFWwindow* window, int enterred) nothrow {
	//log("mouse %s", enterred ? "enterred" : "exited");
}
}

