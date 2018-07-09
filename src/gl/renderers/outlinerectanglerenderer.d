module gl.renderers.outlinerectanglerenderer;

import gl.all;

final struct OutlineRectangleData { 
	Vector2 v1,v2,v3,v4;
	RGBA colour;
	float thickness;
}

final class OutlineRectangleRenderer : Renderer {
	LineRenderer lineRenderer;

	this(OpenGL gl) {
		super(gl);
		this.lineRenderer = new LineRenderer(gl);
	}
	override void destroy() {
		lineRenderer.destroy();
	}
	override Renderer setVP(Matrix4 viewProj) {
		lineRenderer.setVP(viewProj);
		return this;
	}
	auto withRectangles(OutlineRectangleData[] data...) {
		LineData[] lines;
		lines.reserve(data.length*4);
		lines.assumeSafeAppend();
		foreach(ref d; data) {
			lines ~= LineData(d.v1, d.v2, d.colour, d.colour, d.thickness);
			lines ~= LineData(d.v2, d.v3, d.colour, d.colour, d.thickness);
			lines ~= LineData(d.v3, d.v4, d.colour, d.colour, d.thickness);
			lines ~= LineData(d.v4, d.v1, d.colour, d.colour, d.thickness);
		}
		lineRenderer.withLines(lines);
		return this;
	}
	auto addRectangles(OutlineRectangleData[] data...) {
		foreach(d; data) {
			lineRenderer.addLines(
				LineData(d.v1, d.v2, d.colour, d.colour, d.thickness),
				LineData(d.v2, d.v3, d.colour, d.colour, d.thickness),
				LineData(d.v3, d.v4, d.colour, d.colour, d.thickness),
				LineData(d.v4, d.v1, d.colour, d.colour, d.thickness)
			);
		}
		return this;
	}
	override void render() {
		lineRenderer.render();
	}
}