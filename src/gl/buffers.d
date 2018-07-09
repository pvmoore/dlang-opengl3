module gl.buffers;
/**
	Interesting optimisation advice:
		https://www.opengl.org/wiki/Vertex_Specification_Best_Practices
*/
import gl.all;

final class VAO {
	uint id;
	int numAttribsEnabled;

	this() {
		glGenVertexArrays(1, &id);
	}
	void destroy() {
		unbind();
		glDeleteVertexArrays(1, &id); id = 0;
	}
	void bind() {
		glBindVertexArray(id);
	}
	void unbind() {
		glBindVertexArray(0);
	}
	/// assume vbo.bind() has been called
	void enableAttrib(uint index, int elementSize, uint elementType=GL_FLOAT, 
					  bool normalise=false, int stride=0, long offset=0) 
	{
		glEnableVertexAttribArray(index);
		glVertexAttribPointer(index, elementSize, elementType, normalise?GL_TRUE:GL_FALSE, stride, cast(void*)offset);
		numAttribsEnabled++;
	}
	void disableAttribs() {
		if(numAttribsEnabled==0) return;
		for(auto i=0; i<numAttribsEnabled; i++) {
			glDisableVertexAttribArray(i);
		}
		numAttribsEnabled = 0;
	}
}
// ---------------------------------------------------------------------------------------
final class VBO {
	uint id;
	uint type;
	long sizeBytes;
	VBOMemoryManager memoryManager;

	private this(uint type, long sizeBytes, uint usage) {
		this.type = type;
		this.sizeBytes = sizeBytes;
		glGenBuffers(1, &id);
		bind();
		glBufferData(type, sizeBytes, null, usage);
	}
	static VBO array(long sizeBytes, uint usage=GL_STATIC_DRAW) {
		return new VBO(GL_ARRAY_BUFFER, sizeBytes, usage);
	}
	static VBO elements(long sizeBytes, uint usage=GL_STATIC_DRAW) {
		return new VBO(GL_ELEMENT_ARRAY_BUFFER, sizeBytes, usage);
	}
	static VBO uniforms(long sizeBytes, uint usage=GL_STATIC_DRAW) {
		return new VBO(GL_UNIFORM_BUFFER, sizeBytes, usage);
	}
	static VBO shaderStorage(long sizeBytes, uint usage=GL_STATIC_DRAW) {
        return new VBO(GL_SHADER_STORAGE_BUFFER, sizeBytes, usage);
	}
	void destroy() {
		glDeleteBuffers(1, &id); 
	}
	VBOMemoryManager getMemoryManager() {
	    if(!memoryManager) memoryManager = new VBOMemoryManager(this);
	    return memoryManager;
	}
	/// assume bind() has been called
	auto realloc(long sizeBytes, uint usage=GL_STATIC_DRAW) {
		this.sizeBytes = sizeBytes;
		glBufferData(type, sizeBytes, null, usage);
		return this;
	}
	auto bind() {
		glBindBuffer(type, id);
		return this;
	}
	/// assume bind() has been called
	auto setData(T)(T[] src, uint usage) {
        //glBufferData(type, src.length*T.sizeof, src.ptr, usage);

        // this seems to be more consistent than the above
        import core.stdc.string : memcpy;
        void* p = glMapBuffer(type, GL_WRITE_ONLY);
        memcpy(p, src.ptr, src.length);
        glUnmapBuffer(type);
        return this;
	}
	/// assume bind() has been called
	auto addData(T)(T[] src, ulong offsetBytes=0) {
		glBufferSubData(type, offsetBytes, src.length*T.sizeof, src.ptr);
		return this;
	}
	void getData(T)(T[] dest, ulong offsetBytes=0, ulong len=0) {
	    ulong size = len>0?len:sizeBytes;
	    glGetBufferSubData(type, offsetBytes, size, dest.ptr);
	}
	/// Requires Opengl 4.3
	void clearData() {
	    // test this
	    glClearBufferData(type, GL_R8UI, GL_R8UI, GL_R8UI, null);
	}
}
// -----------------------------------------------------------
// Manage VBO memory by keeping track of free and used memory.
// -----------------------------------------------------------
final class VBOMemoryManager {
private:
    VBO vbo;
    Allocator tracker;

    final class Transaction(T) {
//        VBOMemoryManager manager;
//        this(VBOMemoryManager manager) {
//            this.manager = manager;
//        }
        uint start = uint.max;
        uint end   = 0;
        Appender!(uint[]) offsetsBuf;
        Appender!(T[][]) dataBuf;
        int write(T[] data) {
            uint size  = cast(uint)(data.length*T.sizeof);
            int offset = tracker.alloc(size);
            offsetsBuf ~= offset;
            dataBuf ~= data;
            if(offset<start) start = offset;
            if(offset+size>end) end = offset+size;
            return offset;
        }
        void commit() {
            auto offsets = offsetsBuf.data;
            auto data    = dataBuf.data;
            //writefln("mapping buffer range %s to %s", start,end);

            void* ptr = glMapBufferRange(
                vbo.type,
                start,
                end-start,
                GL_MAP_WRITE_BIT
                //| GL_MAP_FLUSH_EXPLICIT_BIT
            );
            if(ptr) {
                import core.stdc.string : memcpy;

                //StopWatch w; w.start();
                foreach(i, src; data) {
                    auto offset = offsets[i]-start;
                    auto length = src.length*T.sizeof;

                    memcpy(ptr+offset, src.ptr, length);
                    //glFlushMappedBufferRange(vbo.type, offset, length);
                }
                glUnmapBuffer(vbo.type);
                //w.stop();
                //writefln("took %s millis", w.peek().nsecs/1000000.0);
            } else {
                 CheckGLErrors("addData");
            }
        }
    }
public:
    this(VBO vbo) {
        this.vbo     = vbo;
        this.tracker = new Allocator(vbo.sizeBytes);
    }
    ulong numBytesFree() { return tracker.numBytesFree; }
    ulong numBytesUsed() { return tracker.numBytesUsed; }
    ulong length() { return tracker.length; }
    // call this before writing any data
    void bind() {
        vbo.bind();
    }
    /**
     * Write data to the smallest available region.
     * Return the offset of the region used or -1 if no
     * region with enough space is available.
     *
     * Assumes bind() has already been called on the VBO.
     */
    long write(T)(T[] data, uint alignment=1) {
        uint requiredSize = cast(uint)(data.length*T.sizeof);
        long offset = tracker.alloc(requiredSize, alignment);
        if(offset==-1) {
            // Make the VBO larger
            // NB. Resizing a VBO will probably delete all the
            // existing data so if you really want to do this
            // then a mechanism for copying existing data to the
            // new VBO is required.
            return -1;
        }
        vbo.addData(data, offset);
        return offset;
    }
    /// Release a range
    void free(ulong offset, ulong size) {
        tracker.free(offset, size);
    }
    auto beginTransaction(T)() {
        return new Transaction!T();
    }
}

