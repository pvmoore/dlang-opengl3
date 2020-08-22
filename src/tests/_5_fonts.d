module tests._5_fonts;

import gl.all;
import tests.all;

final class TestFonts : Test {
	OpenGL gl;
	VAO vao;
	Font[] sdfFonts;
	FpsCounter fpsCounter;
	Renderer[] fontRenderers;
	Renderer[] outlineRectangleRenderers;
	Renderer[] filledRectangleRenderers;
	StopWatch watch;
	long numFrames;

	this(OpenGL gl) {
		this.gl = gl;
		this.vao = new VAO();

		gl.setWindowTitle("Test 5: Fonts");
	}
	void setup() {
		vao.bind();

		glClearColor (0, 0, 0, 0);

		auto View = Matrix4.lookAt(
			Vector3(0,0,1), // camera position in World Space
			Vector3(0,0,0), // look at the origin
			Vector3(0,1,0)  // head is up
		);

		Dimension winSize = gl.windowSize;
		auto Projection = Matrix4.ortho(
			0f,			    winSize.width,
			winSize.height,	0,			// swap the y so that (0,0) is top left
			0.0f,		    100.0f
		);
		auto MVP = Projection * View;

		auto trans = new Transformer()
			.verts(Vector2(0, 0),
				   Vector2(0, 1),
				   Vector2(1, 1),
				   Vector2(1, 0))
			.translate(7, 97)
			.scale(1000,100)
			.apply();

		filledRectangleRenderers ~= new FilledRectangleRenderer(gl)
			.addRectangles(FilledRectangleData(trans[0],trans[1],trans[2],trans[3], RGBA(1,0.8,0.3,1)*0.5))
			.setVP(MVP);

		int size = 30;

		fpsCounter = new FpsCounter(gl);

        sdfFonts ~= gl.getFont("segoeprint");
        sdfFonts ~= gl.getFont("opensans-regular");
        sdfFonts ~= gl.getFont("gabriola");
        sdfFonts ~= gl.getFont("hack-regular");
        sdfFonts ~= gl.getFont("arial");

		// drop shadow
        fontRenderers ~= new SDFFontRenderer(gl, sdfFonts[0], true)
            .setSize(30)
            .setColour(WHITE)
            .setDropShadowColour(RGBA(0,0,0,1))
            .setDropShadowOffset(Vector2(-0.004,-0.004))
            .appendText("Eddie Newton, 44: Played for Chelsea's Quorum between 1990 and 1999.", 10, 92)
            .setVP(Projection*View);

        fontRenderers ~= new SDFFontRenderer(gl, sdfFonts[1], false)
            .setSize(30)
            .setColour(YELLOW)
            .appendText("His name was Bob Fagin; and I took the liberty of using his name", 10, 100+size)
            .setVP(Projection*View);

        fontRenderers ~= new SDFFontRenderer(gl, sdfFonts[2], false)
            .setSize(30)
			.setColour(GREEN)
			.appendText("It was the mildest December night for several decades Quorum", 10, 100+size+5)
			.appendText("An input range of elements in the joined range.", 10, 125+size+5)
			.setVP(Projection*View);


		Rect r = sdfFonts[1].sdf.getRect("I am some text", 30);

		trans.translate(50+r.x, 300+r.y)
			 .scale(r.width, r.height)
			 .apply();
		outlineRectangleRenderers ~= new OutlineRectangleRenderer(gl)
			.addRectangles(
				OutlineRectangleData(trans[0],trans[1],trans[2],trans[3],
								WHITE*0.7, 1)
			)
			.setVP(MVP);

        fontRenderers ~= new SDFFontRenderer(gl, sdfFonts[1], false)
            .setSize(30)
            .appendText("I am some text", 50, 300)
            .setVP(Projection*View);

        fontRenderers ~= new SDFFontRenderer(gl, sdfFonts[4], false)
            .setSize(24)
            .setColour(WHITE)
            .appendText("Fifa president Sepp Blatter",	620, 300)
            .appendText("and Uefa boss Michel Platini", 620, 300+28)
            .appendText("have been suspended for",		620, 300+28*2)
            .appendText("eight years from all",			620, 300+28*3)
            .appendText("football-related activities",	620, 300+28*4)
            .appendText("following an ethics",			620, 300+28*5)
            .appendText("investigation. They were",		620, 300+28*6)
            .appendText("found guilty of breaches",		620, 300+28*7)
            .appendText("surrounding a £1.3m ($2m)",	620, 300+28*8)
            .appendText("\"disloyal payment\" made to", 620, 300+28*9)
            .appendText("Platini in 2011.",				620, 300+28*10)
            .setVP(Projection*View);

        fontRenderers ~= new SDFFontRenderer(gl,sdfFonts[4], false)
            .setSize(24)
            .setColour(YELLOW)
        	.setVP(Projection*View);

        auto para = new SDFParagraph(
            Rect(300,300,300,300),
            /* callback */
            (int x, int y, string text) {
                (cast(SDFFontRenderer)fontRenderers[$-1])
                    .appendText(text,x,y);
            },
            sdfFonts[4].sdf, 24, 2, 0
        );

		para.justified("Fifa president Sepp Blatter and Uefa boss Michel Platini have been "~
					   "suspended for eight years from all football-related activities following "~
					   "an ethics investigation. "~
					   "They were found guilty of breaches surrounding a £1.3m ($2m) \"disloyal payment\" "~
					   "made to Platini in 2011.");

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	}
	void destroy() {
		if(fpsCounter) fpsCounter.destroy(); fpsCounter=null;
		fontRenderers.each!(it=>it.destroy());
		filledRectangleRenderers.each!(it=>it.destroy());
		outlineRectangleRenderers.each!(it=>it.destroy());
		if(vao) vao.destroy();
	}
	void mouseClicked(float x, float y) {
	}
	void render(ulong frameNumber, float seconds, float perSecond) {
		glClear(GL_COLOR_BUFFER_BIT);

		watch.start();
		// draw rectangles first
		filledRectangleRenderers.each!(it=>it.render());
		outlineRectangleRenderers.each!(it=>it.render());

		fontRenderers.each!(it=>it.render());

		fpsCounter.render();

		watch.stop();
		numFrames++;
		if((numFrames&0xff)==0) {
			double nsecs = watch.peek().total!"nsecs";
			log("_5_fonts: %s nsecs per frame", nsecs/numFrames);
		}
	}
}
