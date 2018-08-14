module gl;

version(Win64) {} else { pragma(msg,"Windows 64 bit required"); static assert(false); }

public:

import fonts.sdf;

import derelict.opengl;
import derelict.glfw3;

import gl.buffers;
import gl.opengl;
import gl.program;
import gl.skybox;
import gl.shader;
import gl.types;

import gl.camera.camera3d_extras;

import gl.renderers.all;

import gl.textures.texture_2d;
import gl.textures.texture_cube;
import gl.textures.textures;

import gl.util.dds_loader;
import gl.util.debugging;
import gl.util.obj_loader;
import gl.util.pixelbuffer;
import gl.util.shader_code_reader;
import gl.util.util;

// some extra AMD specific constants
enum : uint {
    VBO_FREE_MEMORY_ATI           = 0x87FB,
    TEXTURE_FREE_MEMORY_ATI       = 0x87FC,
    RENDERBUFFER_FREE_MEMORY_ATI  = 0x87FD
}

// these are not in derelict_gl for some reason
enum : uint {
    GL_STACK_OVERFLOW   = 0x0503,
    GL_STACK_UNDERFLOW  = 0x0504,
}