module gl.geom._2d.fpscounter;

import gl.all;

final class FpsCounter {
	OpenGL gl;
	SDFFontRenderer fontRenderer;
	RGBA colour = RGBA(1,1,0.7,1);
	float avgFps;
	float x,y;
	bool ready;

	this(OpenGL gl, float x=-1, float y=-1) {
		this.gl = gl;
		if(x==-1 || y==-1) {
			Dimension winSize = gl.windowSize;
			x = winSize.width-142;
			y = 5;
		}
		this.x = x;
		this.y = y;
	}
	void destroy() {
	    if(fontRenderer) fontRenderer.destroy(); fontRenderer = null;
	}
	void update() {
	    avgFps = gl.FPS;
	}
	void render() {
		if(!ready) setup();
		update();

        fontRenderer.replaceText(to!string(avgFps) ~ " fps")
                    .render();
	}
private:
	void setup() {
		Dimension winSize = gl.windowSize;

		auto view2d = Matrix4.lookAt(
			Vector3(0,0,1), // camera position in World Space
			Vector3(0,0,0), // look at the origin
			Vector3(0,1,0)  // head is up 
		);
		auto proj2d = Matrix4.ortho(
			0f,			    winSize.width,
			winSize.height,	0,			// swap the y so that (0,0) is top left
			0.0f,		    100.0f
		);

		fontRenderer = new SDFFontRenderer(gl, gl.getFont("arial"), true)
		    .setColour(colour*1.1)
		    .setSize(26)
		    .appendText("", cast(int)x, cast(int)y);

		fontRenderer.setVP(proj2d*view2d);

		ready = true;
	}
}