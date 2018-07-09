module gl.ui.ui;

import gl.all;
import gl.ui.label;
import gl.ui.window;

__gshared uint ids = 0;

abstract class UIElement {
public:
    uint id;
    vec2 _relPos;
    vec2 _size;
    UIElement parent;
    UIElement[] children;
    bool dirty;

    this() {
        id      = ids++;
        _relPos = vec2(0,0);
        _size   = vec2(0,0);
    }

@property {
    // setters
    void relPos(vec2 p) { _relPos = p; dirty = true; }
    void size(vec2 s) { _size = s; dirty = true; }

    // getters
    vec2 relPos() { return _relPos; }
    vec2 size() { return _size; }
    vec2 absPos() {
        return (parent ? parent.absPos : vec2(0,0))
               + _relPos;
    }
    UI ui() {
        auto u = cast(UI)this;
        return u ? u : parent.ui();
    }
}
    void create(UI ui) {}
    void destroy() {
        foreach(c; children) c.destroy();
    }
    void add(UIElement e) {
        children ~= e;
        e.parent = this;
        e.onAdded();
    }
    void remove(UIElement e) {
        children = children.filter!(it=>it.id!=e.id).array;
        e.parent = null;
        e.onRemoved();
    }
    void render() {
        foreach(c; children) c.render();
        dirty = false;
    }
    // events
    void onAdded() {}
    void onRemoved() {}
}

final class UI : UIElement {
    OpenGL gl;
    Camera2D camera;

    this(OpenGL gl, Rect rect) {
        this.gl     = gl;
        this.relPos = Vector2(0,0);
        this.size   = rect.dimension;
        this.camera = new Camera2D(rect.dimension);
    }
    override void destroy() {
        log("Destroying UI");
        super.destroy();
    }
    Window createWindow(vec2 relPos, vec2 size) {
        auto w = new Window();
        w.create(ui);
        add(w);
        w.relPos = relPos;
        w.size = size;
        w.cornerRadius(8);
        w.bgColour(RGBA(0.5,0.5,0.5, 1));
        return w;
    }
}

