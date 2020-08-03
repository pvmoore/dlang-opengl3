module main;

import gl.all;
import tests.all;
import core.sys.windows.windows : HINSTANCE, LPSTR, MessageBoxA, MB_OK, MB_ICONEXCLAMATION;

__gshared HINSTANCE hInstance;

extern(Windows)
int WinMain(HINSTANCE theHInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
	int result = 0;
	hInstance = theHInstance;
	MyApplication app;
	try{
		Runtime.initialize();

		app = new MyApplication();
		app.run();

	}catch(Throwable e) {
		log("exception: %s", e.msg);
		MessageBoxA(null, e.toString().toStringz, "Error", MB_OK | MB_ICONEXCLAMATION);
		result = -1;
	}finally{
		flushLog();
		app.destroy();
		Runtime.terminate();
	}
	flushLog();
	return result;
}

final class MyApplication : ApplicationListener {
	OpenGL gl;
	bool[256] keys;
	Test test;

	this() {
		//gl = new OpenGL(this, "OpenGL Testing", 1920, 1080, false);
		//gl = new OpenGL(this, "OpenGL Testing", 1024, 768, true);

		//gl.setMouseCursorVisible(false);

		wstring[] args = getCommandLineArgs();
		log("command line args = %s", args);
		wstring testNum = args.length>1 ? args[1] : "1";
		log("executing test program %s", testNum);

		testNum = "1";

		auto glVer = [3,3];
		if(testNum=="7") glVer = [4,3];

		bool ui = testNum=="6";

		gl = new OpenGL(this, (h) {
            h.width    = 1024;
            h.height   = 768;
            h.windowed = true;
            h.title    = "OpenGL Testing";
            h.ui       = ui;
            h.glVersionMaj = glVer[0];
            h.glVersionMin = glVer[1];
        });

		final switch(testNum) {
			case "1" : test = new Test2D(gl); break;
			case "2" : test = new CubeTest(gl); break;
			case "3" : test = new TexturedCubeTest(gl); break;
			case "4" : test = new ObjLoadAndDisplayTest(gl); break;
			case "5" : test = new TestFonts(gl); break;
			case "6" : test = new TestUI(gl); break;
			case "7" : test = new TestCompute(gl); break;
			case "8" : test = new TestSDFFonts(gl); break;
			case "9" : test = new TestSkyBox(gl); break;
		}
		test.setup();
	}
	void destroy() {
		log("destroying MyApplication");
		test.destroy();
		gl.destroy();
	}
	void run() {
		gl.enterMainLoop();
	}
	void keyPress(uint keyCode, uint scanCode, bool down, uint mods) {
		//log("keyCode %s scanCode %s down? %s mods %s", keyCode, scanCode, down, mods);
		//keys[scanCode] = true;
	}
	void mouseButton(uint button, float x, float y, bool down, uint mods) {
		// bool shift = (mods & KeyMod.SHIFT) != 0;
		if(down) {
			test.mouseClicked(x,y);
		}
		final switch(button) {
			case MouseButton.LEFT:
			case MouseButton.MIDDLE:
			case MouseButton.RIGHT:
				log("button %s %s,%s %s %s", button, x, y, down, mods);
				break;
		}
	}
	void mouseMoved(float x, float y) {
		//log("mouse moved to (%s,%s)", x,y);
	}
	void mouseWheel(float xdelta, float ydelta, float x, float y) {
		//log("mouse wheel delta %s mouse (%s,%s)", ydelta, x, y);
	}
	void render(long actualFrameNumber, long normalisedFrameNumber, float timeDelta) {
		test.render(actualFrameNumber, normalisedFrameNumber, timeDelta);
	}
}
