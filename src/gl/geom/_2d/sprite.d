module gl.geom._2d.sprite;

import gl.all;
/**
	This class is designed to be used with the SpriteRenderer which uses
	a single texture. This means that all sprites rendered by it need to use the same texture.
	eg. new SpriteRenderer(gl).withSprites(sprites).render();
*/

final class BitmapSprite : Sprite {
	Vector4 uv = Vector4(0,0,1,1);
	auto withUV(Vector4 uv) {
		this.uv = uv;
		return this;
	}
}

class Sprite {
	Vector2 pos   = Vector2(0,0);
	Vector2 up    = Vector2(0,-1);	// assumes top-left is (0,0) in screen space
	Vector2 size  = Vector2(1,1);
	RGBA colour   = WHITE;

	auto move(float x, float y) {
		this.pos += Vector2(x,y);
		return this;
	}
	auto move(Vector2 p) {
		this.pos += p;
		return this;
	}
	auto scale(float s) {	
		this.size = Vector2(s,s);
		return this;
	}
	auto scale(float w, float h) {	
		this.size = Vector2(w,h);
		return this;
	}
	auto rotate(float degs) {
		this.up.rotate(degs.degrees);
		return this;
	}
	auto withColour(RGBA c) {
		this.colour = c;
		return this;
	}
}
