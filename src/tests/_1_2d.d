module tests._1_2d;

import gl.all;
import tests.all;

final class Test2D : Test {
	enum Page : int {
		RECTANGLES=0, CIRCLES, TRIANGLES,
		GRIDRENDERER, SPRITERENDERER, TEXTRENDERER, LINES
	}
	Page page = Page.CIRCLES;
	OpenGL gl;
	Renderer tabTitle;
	FpsCounter fpsCounter;
	Renderer[] grids;
	Renderer spriteRenderer;
	Renderer[] textRenderers;
	Renderer[] lineRenderers;
	Renderer[] outlineRectangleRenderers;
	Renderer[] filledRectangleRenderers;
	Renderer circleRenderer;
	Renderer menuShapes;

	Font hackRegular, segoePrint;
	Camera2D camera;
	StopWatch watch;
	long numFrames;

	this(OpenGL gl) {
		this.gl = gl;

		gl.setWindowTitle("Test 1: 2D");
	}
	void setup() {
		glClearColor (0, 0, 0, 0);

		camera = new Camera2D(gl.windowSize);
		log("camera.VP = %s", camera.VP);

		hackRegular = gl.getFont("hack-regular");
        segoePrint  = gl.getFont("segoeprint");

		menuShapes = new CircleRenderer(gl).setVP(camera.VP);

		with(cast(CircleRenderer)menuShapes) {
			addFilled(Vector2(20,20), 15, WHITE);
			addFilled(Vector2(50,20), 15, WHITE*0.5);
			addFilled(Vector2(80,20), 15, WHITE*0.5);
			addFilled(Vector2(110,20), 15, WHITE*0.5);
			addFilled(Vector2(140,20), 15, WHITE*0.5);
			addFilled(Vector2(170,20), 15, WHITE*0.5);
			addFilled(Vector2(200,20), 15, WHITE*0.5);
		}

        tabTitle = new SDFFontRenderer(gl, hackRegular, false)
            .setSize(26)
            .appendText(to!string(page), 250, 5)
            .setVP(camera.VP);

		setupRectanglesTab();
		setupCirclesTab();
		setupTriangles();
		setupGridRenderer();
		setupSpriteRenderer();
		setupTextRendererTab();
		setupLineRendererTab();

		fpsCounter = new FpsCounter(gl);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glDisable(GL_DEPTH_TEST);
		glDisable(GL_CULL_FACE);
		//glEnable(GL_CULL_FACE);
	}
	void setupCirclesTab() {
		circleRenderer = new CircleRenderer(gl).setVP(camera.VP);

		with(cast(CircleRenderer)circleRenderer) {
			addFilledOutlined(Vector2(120,150), 100, RED, YELLOW, 1);

			for(auto i=1;i<=20;i++) {
				addFilled(Vector2(450,220), 210-i*10, randomRGBA());
				addOutlined(Vector2(750,500), 210-i*10, randomRGBA(), 1);
			}

			addFilled(Vector2(450,220), 5, randomRGBA());
			addOutlined(Vector2(750,500), 5, randomRGBA(), 1);

			addFilled(Vector2(450,220), 2, randomRGBA());
			addOutlined(Vector2(750,500), 2, randomRGBA(), 1);

			addOutlined(Vector2(150,500), 10, randomRGBA(), 1);
			addOutlined(Vector2(150,500), 30, randomRGBA(), 2);
			addOutlined(Vector2(150,500), 50, randomRGBA(), 4);
			addOutlined(Vector2(150,500), 80, randomRGBA(), 10);
			addOutlined(Vector2(150,500), 120, randomRGBA(), 15);
			addOutlined(Vector2(150,500), 160, randomRGBA(), 30);
		}
	}
	void setupRectanglesTab() {
		Transformer trans = new Transformer();
		OutlineRectangleData[] outline;
		FilledRectangleData[] filled;
		FilledRectangleData[] textureFilled;

		trans.verts(
				Vector2(-1, -1),
				Vector2(-1, 1),
				Vector2(1, 1),
				Vector2(1, -1),
			);

		for(auto i=1;i<14;i++) {
			trans.translate(50+i*i*5, 100)
				 .rotate(uniform(0,360))
				 .scale(i*5)
				 .apply();
			outline ~= OutlineRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE, 1);

			trans.translate(50+i*i*5, 250)
				 .rotate(uniform(0,360))
				 .scale(i*5)
				 .apply();
			filled ~= FilledRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE*0.5);

			trans.translate(50+i*i*5, 400)
				.rotate(uniform(0,360))
				.scale(i*5)
				.apply();
			outline ~= OutlineRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE, 1);
			filled ~= FilledRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE*0.5);

			trans.translate(50+i*i*5, 550)
				.rotate(uniform(0,360))
				.scale(i*5)
				.apply();
			outline ~= OutlineRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE, 0.5+i/2);
			textureFilled ~= FilledRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE*0.7);
		}

		trans.translate(70, 650)
			.rotate(0)
			.scale(50)
			.apply();
		outline ~= OutlineRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE, 1);
		textureFilled ~= FilledRectangleData(trans[0], trans[1], trans[2], trans[3], WHITE, Vector4(0,0,1,1));

		outlineRectangleRenderers ~= new OutlineRectangleRenderer(gl)
			.withRectangles(outline)
			.setVP(camera.VP);
		filledRectangleRenderers ~= new FilledRectangleRenderer(gl)
			.withRectangles(filled)
			.setVP(camera.VP);
		filledRectangleRenderers ~= new FilledRectangleRenderer(gl)
			.withTexture(gl.textures.get("images", "sunol_front_mipmap.dds"))
			.withRectangles(textureFilled)
			.setVP(camera.VP);
	}
	void setupTriangles() {

	}
	void setupGridRenderer() {
		grids ~= new GridRenderer(gl, 100, 100, 500, 500, WHITE*0.8)
			.withVerticalLines(5)
			.withHorizontalLines(5)
			.withHighlightModulus(20)
			.setVP(camera.VP);
		grids ~= new GridRenderer(gl, 650, 100, 200, 200, WHITE*0.8)
			.withVerticalLines(10)
			.withHorizontalLines(10)
			.setVP(camera.VP);
		grids ~= new GridRenderer(gl, 650, 400, 200, 200, RED*0.8)
			.withVerticalLines(20)
			.withHorizontalLines(20)
			.setVP(camera.VP);
	}
	void setupSpriteRenderer() {
		BitmapSprite[] sprites = [
			cast(BitmapSprite)new BitmapSprite()
				.scale(100)
				.move(100, 100)
		];
		for(auto y=0;y<16;y++) for(auto i=0;i<30;i++) {
			sprites ~= cast(BitmapSprite)new BitmapSprite()
				.withColour(randomColour())
				.scale(25)
				.move(10+i*30, 220+y*30)
				.rotate(uniform(0,360));
		}
		spriteRenderer = new SpriteRenderer(gl)
			.withSprites(sprites)
			.withTexture(gl.textures.get("images", "sunol_front_mipmap.dds"))
			.setVP(camera.VP);
	}
	void setupTextRendererTab() {
		textRenderers ~= new SDFFontRenderer(gl, segoePrint, false)
			.setColour(WHITE*0.8)
			.setSize(32)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+0)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*2)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*3)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*4)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*5)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*6)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*7)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*8)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*9)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*10)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 50+28*11)
			.setVP(camera.VP);

		textRenderers ~= new SDFFontRenderer(gl, segoePrint, false)
			.setColour(RED*0.8)
			.setSize(32)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+0)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*2)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*3)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*4)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*5)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*6)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*7)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*8)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*9)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*10)
			.appendText("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ", 5, 391+28*11)
			.setVP(camera.VP);
	}
	void setupLineRendererTab() {
		LineData[] lines;
		for(auto x=0; x<18; x++) {
			lines ~= LineData(Vector2(50+x*50, 260),
						  Vector2(100+x*50, 440),
						  MAGENTA,
						  WHITE,
						  x+1);
		}
		lineRenderers ~= new LineRenderer(gl)
			.withLines(lines)
			.setVP(camera.VP);
	}
	RGBA randomColour() {
		RGBA[] cols = [
			WHITE, RED, GREEN, BLUE, randomRGBA()
		];
		return cols[uniform(0, cols.length)];
	}
	string randomTexture() {
		static string[] filenames = [
			"images\\wood.dds",
			"images\\seafloor.dds",
			"images\\sunol_back_mipmap.dds",
			"images\\tree0.dds",
			"images\\wall.dds",
			"images\\brick.dds",
			"images\\ccTerrainMap.dds"
		];
		return filenames[uniform(0, filenames.length)];
	}
	void destroy() {
		if(fpsCounter) fpsCounter.destroy();
		grids.each!(it=>it.destroy());
		spriteRenderer.destroy();
		textRenderers.each!(it=>it.destroy());
		lineRenderers.each!(it=>it.destroy());
		outlineRectangleRenderers.each!(it=>it.destroy());
		filledRectangleRenderers.each!(it=>it.destroy());
		menuShapes.destroy();
		circleRenderer.destroy();
		tabTitle.destroy();
	}
	void mouseClicked(float x, float y) {
		try{
			float maxX = 200+15;
			if((10 < y && y < 30) && (10 < x && x < maxX)) {
				page = cast(Page)((x-10)/30);

				with(cast(CircleRenderer)menuShapes) {
					points.each!((ref CircleData it)=>it.fillColour = WHITE*0.5);
					points[page].fillColour = WHITE;
					dataChanged = true;
				}
				with(cast(SDFFontRenderer)tabTitle) {
					replaceText("%s".format(page));
				}
				watch.reset();
				numFrames = 0;
			}
		}catch(Exception e) {}
	}
	void update(float perSecond) {
		//camera.zoomIn(speedDelta*0.01);
		//camera.rotateBy(speedDelta);

		//spriteRenderer.setVP(camera.VP);

		//pointRenderers.each!(it=>it.setVP(camera.VP));

		//lineRenderers.each!(it=>it.setVP(camera.VP));

		//filledRectangleRenderers.each!(it=>it.setVP(camera.VP));
		//outlineRectangleRenderers.each!(it=>it.setVP(camera.VP));
	}
	void render(ulong frameNumber, float seconds, float perSecond) {
		update(perSecond);

		glClear(GL_COLOR_BUFFER_BIT);

		watch.start();
		with(Page) switch(page) {
			case CIRCLES :
				circleRenderer.render();
				break;
			case RECTANGLES:
				filledRectangleRenderers.each!(it=>it.render());
				outlineRectangleRenderers.each!(it=>it.render());
				break;
			case TRIANGLES:
				break;
			case GRIDRENDERER:
				grids.each!(it=>it.render());
				break;
			case SPRITERENDERER:
				with(cast(SpriteRenderer)spriteRenderer) {
					sprites.each!(it=>it.rotate(perSecond*10));
					render();
				}
				break;
			case TEXTRENDERER:
				string r = to!string(frameNumber);
				with(cast(SDFFontRenderer)textRenderers[1]) {
					replaceText(0, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(1, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(2, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(3, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(4, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(5, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(6, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(7, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(8, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(9, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(10, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
					replaceText(11, r~"abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ");
				}
				textRenderers.each!(it=>it.render());
				break;
			case LINES:
				lineRenderers.each!(it=>it.render());
				break;
			default:
				log("who you?");
				break;
		}

		menuShapes.render();
		tabTitle.render();

		fpsCounter.render();

		watch.stop();
		numFrames++;
		// if((numFrames&0xff)==0) {
		// 	double nsecs = watch.peek().total!"nsecs";
		// 	log("_1_2d: [%s] %s nsecs per frame", "%s".format(page), nsecs/numFrames);
		// }
	}
}