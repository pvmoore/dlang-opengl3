module tests.all;

import gl.all;

public:

import tests._1_2d;
import tests._2_cube;
import tests._3_textured_cube;
import tests._4_obj_load_and_display;
import tests._5_fonts;
import tests._6_ui;
import tests._7_compute;
import tests._8_sdffonts;
import tests._9_skybox;

interface Test {
	void setup();
	void destroy();
	void render(ulong frameNumber, float seconds, float perSecond);
	void mouseClicked(float x, float y) nothrow;
}
