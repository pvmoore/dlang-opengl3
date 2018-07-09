module gl.camera.camera3d_extras;
/**
 *  OpenGL specific Camera3D functionality.
 *  Standard Camera3D lives in the maths project.
 */
import gl.all;

/// origin is top-left
Vector3 screenToWorld(Camera3D camera, int screenX, int screenY) {
    float depthZ;
    int invScreenY = cast(int)(camera.windowSize.height - screenY);
    // glReadPixels origin is bottom-left
    glReadPixels(screenX, invScreenY,
                 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &depthZ);

    return camera.screenToWorld(screenX, screenY, depthZ);
}


