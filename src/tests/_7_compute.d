module tests._7_compute;

import gl.all;
import tests.all;
import std.stdio : writefln;

final class TestCompute : Test {
    OpenGL gl;
    Program prog1, prog2;
    VAO vao;
    VBO input1, input2, output1;
    SpriteRenderer spriteRenderer;
    uint[2] textures;
    uint[2] queries;
    uint width = 704, height = 704; // (495,616 pixels)
    ulong N    = 65535*64; //495_616;

    ulong totalTime;
    ulong numFrames;

    this(OpenGL gl) {
        this.gl = gl;
        this.vao = new VAO();

        gl.setWindowTitle("Test 7: Compute");
    }
    void setup() {
        glClearColor(0.2, 0.2, 0.2, 1);
        vao.bind();

        logGLInteger("GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS", GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS);
        logGLInteger("GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS", GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS);
        logGLInteger("GL_MAX_COMPUTE_SHARED_MEMORY_SIZE", GL_MAX_COMPUTE_SHARED_MEMORY_SIZE);
        logGLInteger("GL_MAX_COMPUTE_ATOMIC_COUNTERS", GL_MAX_COMPUTE_ATOMIC_COUNTERS);
        logGLInteger("GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS", GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS);
        logGLInteger("GL_MAX_UNIFORM_BLOCK_SIZE", GL_MAX_UNIFORM_BLOCK_SIZE);
        logGLInteger("GL_MAX_COMPUTE_UNIFORM_BLOCKS", GL_MAX_COMPUTE_UNIFORM_BLOCKS);
        logGLInteger("GL_MAX_COMPUTE_UNIFORM_COMPONENTS", GL_MAX_COMPUTE_UNIFORM_COMPONENTS);

        int[3] work_grp_cnt;
        glGetIntegeri_v(GL_MAX_COMPUTE_WORK_GROUP_COUNT, 0, &work_grp_cnt[0]);
        glGetIntegeri_v(GL_MAX_COMPUTE_WORK_GROUP_COUNT, 1, &work_grp_cnt[1]);
        glGetIntegeri_v(GL_MAX_COMPUTE_WORK_GROUP_COUNT, 2, &work_grp_cnt[2]);
        log("GL_MAX_COMPUTE_WORK_GROUP_COUNT=%s", work_grp_cnt);

        int[3] work_grp_size;
        glGetIntegeri_v(GL_MAX_COMPUTE_WORK_GROUP_SIZE, 0, &work_grp_size[0]);
        glGetIntegeri_v(GL_MAX_COMPUTE_WORK_GROUP_SIZE, 1, &work_grp_size[1]);
        glGetIntegeri_v(GL_MAX_COMPUTE_WORK_GROUP_SIZE, 2, &work_grp_size[2]);
        log("GL_MAX_COMPUTE_WORK_GROUP_SIZE=%s", work_grp_size);

        glGenTextures(textures.length, textures.ptr);
        glGenQueries(queries.length, queries.ptr);

        setupReadWriteBufferExample();
        //setupReadWriteImageExample();

        CheckGLErrors();
    }
    void destroy() {
        if(spriteRenderer) spriteRenderer.destroy();
        if(queries[0]) glDeleteQueries(queries.length, queries.ptr);
        if(textures[0]) glDeleteTextures(textures.length, textures.ptr);
        if(input1) input1.destroy();
        if(output1) output1.destroy();
        if(vao) vao.destroy();
        if(prog1) prog1.destroy();
        if(prog2) prog2.destroy();
    }
    void render(long frameNumber, long normalisedFrameNumber, float updateRatio) {
        glClear(GL_COLOR_BUFFER_BIT);
        runReadWriteBufferExample();
        //runReadWriteImageExample();
    }
    void mouseClicked(float x, float y) nothrow {
    }
private:
    void startTimer(uint query) {
        glBeginQuery(GL_TIME_ELAPSED, query);
    }
    ulong getElapsedTime(uint query) {
        glEndQuery(GL_TIME_ELAPSED);
        ulong time;
        int available;
        while(!available) {
            glGetQueryObjectiv(query, GL_QUERY_RESULT_AVAILABLE, &available);
        }
        glGetQueryObjectui64v(query, GL_QUERY_RESULT, &time);
        return time;
    }
    T[] readBuffer(T)(VBO buf) {
        T[] dest = new T[N];
        buf.getData(dest);
        return dest;
    }
    void setupReadWriteBufferExample() {
        prog1 = new Program()
            .loadCompute(
                "read_write_buffer.comp",
                ["shaders/comp/",
                 "/pvmoore/_assets/shaders/"],
                ["#define PLOP 1"]
            ).use()
            .setUniform("BOUNDS", [vec3(1,2,3),vec3(4,5,6)]);

        input1 = VBO.shaderStorage(N*float.sizeof, GL_STATIC_DRAW);
        input1.bind();

        float[] buf = new float[N];
        for(auto i=0; i<buf.length; i++) {
            buf[i] = i;
        }
        StopWatch w; w.start();
        input1.setData(buf, GL_STATIC_DRAW);
        w.stop();
        log("Took %s millis to upload float data", w.peek().total!"nsecs"/1000000.0);


        input2 = VBO.shaderStorage(N*uint.sizeof, GL_STATIC_DRAW);
        input2.bind();
        uint[] buf2 = new uint[N];
        for(auto i=0; i<buf2.length; i++) {
            buf2[i] = 0x44332211;
        }
        w.reset(); w.start();
        input2.setData(buf2, GL_STATIC_DRAW);
        w.stop();
        log("Took %s millis to upload int data", w.peek().total!"nsecs"/1000000.0);

    //  2.18112
// Took 18.2559 millis to upload float data
// Took 0.12288 millis to upload int data
     // 0.214784

        output1 = VBO.shaderStorage(N*uint.sizeof, GL_DYNAMIC_READ);

        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, input1.id);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, input2.id);
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, output1.id);
    }
    void runReadWriteBufferExample() {
        vao.bind();
        prog1.use();
        StopWatch w; w.start();

        startTimer(queries[0]);

        // these args are required to be at least 65536,65536,65536
        glDispatchCompute(cast(uint)N/64, 1, 1);

        ulong time = getElapsedTime(queries[0]);

        updateAverageTime(time);

        w.stop();

        writefln("[0] time = %s (query time = %s [avg=%.3f])",
            w.peek().total!"nsecs"/1000000.0, time/1000000.0, getAverageTime());

        //

        // 0.091

        uint[] buf = readBuffer!uint(output1);
        //writefln("buf[0..8]=%s", buf[0..8].map!(it=>"%b".format(it)).join(","));
        writefln("buf[0] = %s (%f)", buf[0], cast(double)buf[0]/100000.0);
        //writefln("buf[0]=%04x", buf[0]);
    }
    void updateAverageTime(ulong time) {
        numFrames++;
        if(numFrames>10) {
            totalTime += time;
        }
    }
    double getAverageTime() {
        if(numFrames<11) return 0;
        return (cast(double)totalTime/(numFrames-10))/1000000.0;
    }
    // ------------------------------------------------------
    void setupSpriteRenderer() {
        spriteRenderer = new SpriteRenderer(gl, false);
        spriteRenderer
            .setVP(new Camera2D(gl.windowSize).VP);
        spriteRenderer
            .withTexture(new Texture2D(textures[1], Dimension(width, height)))
            .addSprites([
                cast(BitmapSprite)new BitmapSprite()
                    .move(Vector2(10,10))
                    .scale(width, height)
            ]);
    }
    void createInTexture() {
        glBindTexture(GL_TEXTURE_2D, textures[0]);
        //glActiveTexture(GL_TEXTURE0 + 0);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

        ubyte[] data = new ubyte[4*width*height];
        for(auto i=0; i<data.length; i+=4) {
            data[i+0] = 128;
            data[i+1] = 0;
            data[i+2] = 0;
            data[i+3] = 255;
        }

        StopWatch w; w.start();
        glTexImage2D(GL_TEXTURE_2D,     // target
                     0,                 // level
                     GL_RGBA8UI,        // internal format
                     width, height,     // width,height
                     0,                 // border
                     GL_RGBA_INTEGER,   // format
                     GL_UNSIGNED_BYTE,  // type
                     data.ptr);         // data
        w.stop();
        log("took %s millis to upload image data", w.peek().total!"nsecs"/1000000.0);
    }
    void createOutTexture() {
        glBindTexture(GL_TEXTURE_2D, textures[1]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        glTexStorage2D(
            GL_TEXTURE_2D,  // target
            1,              // levels
            GL_RGBA8,       // internal format
            width,
            height);
    }
    void setupReadWriteImageExample() {
        prog2 = new Program()
            .loadCompute(
                "read_write_image.comp",
                ["shaders/comp/",
                 "/pvmoore/_assets/shaders/"],
                ["#define PLOP2 1",
                 "#define PETER 2"]
            )
            .use();

        createInTexture();
        createOutTexture();

        glBindImageTexture(
            0,              // unit
            textures[0],    // textureID
            0,              // level
            GL_FALSE,       // layered
            0,              // layer
            GL_READ_ONLY,   // usage
            GL_RGBA8UI);    // format

        glBindImageTexture(
            1,
            textures[1],
            0,
            GL_FALSE,
            0,
            GL_WRITE_ONLY,
            GL_RGBA8);

        //prog2.setUniform("imageIn", 0);
        //prog2.setUniform("imageOut", 1);

        setupSpriteRenderer();
    }
    void runReadWriteImageExample() {
        vao.bind();
        prog2.use();
        StopWatch w; w.start();
        startTimer(queries[1]);

        // 704*704 = 495,616 pixels (of 4 components per pixel)
        // so 1,982,464 bytes
        glDispatchCompute(width/8, height/8, 1);

        // blit the outImage to the screen
        glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

        ulong time = getElapsedTime(queries[1]);

        w.stop();
        spriteRenderer.render();

        writefln("[1] time = %s (query time = %s)",
            w.peek().total!"nsecs"/1000000.0, time/1000000.0);

        // 0.02192 millis
    }
}


