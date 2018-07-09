module gl.ui.label;

import gl.all;

final class Label : UIElement {
    SDFFontRenderer textRenderer;
    Font font;

    // setters


    // events
    override void create(UI ui) {
        font = ui.gl.getFont("roboto-bold");
        textRenderer = new SDFFontRenderer(ui.gl, font, true);
        textRenderer.appendText("Button");
        textRenderer.appendText("Button");
        textRenderer.setVP(ui.camera.VP);
    }
    override void destroy() {
        super.destroy();
        textRenderer.destroy();
    }
    override void render() {
//        textRenderer.textChunks[0].colour = RGBA(0,0,0,0.4);
//        textRenderer.textChunks[0].x -= 1;
//        textRenderer.textChunks[0].y -= 1;
//        textRenderer.dataChanged = true;
//        textRenderer.render();
//        textRenderer.textChunks[0].colour = RGBA(1,1,1,1);
//        textRenderer.textChunks[0].x += 1;
//        textRenderer.textChunks[0].y += 1;
//        textRenderer.dataChanged = true;
//        textRenderer.render();
        super.render();
    }
}

