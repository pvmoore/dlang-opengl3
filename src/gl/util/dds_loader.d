module gl.util.dds_loader;

import gl.all;
import std.stdio : File;
import std.file  : exists, getSize;
/*
	https://en.wikipedia.org/wiki/DirectDraw_Surface
	https://msdn.microsoft.com/en-us/library/bb943991.aspx#File_Layout1
	https://msdn.microsoft.com/en-us/library/windows/desktop/bb943991%28v=vs.85%29.aspx
	https://msdn.microsoft.com/en-us/library/windows/desktop/bb943992%28v=vs.85%29.aspx
*/

// derelict-gl3 does not contain these:
enum : uint {
    GL_COMPRESSED_RGB_S3TC_DXT1_EXT     = 0x83F0,
    GL_COMPRESSED_RGBA_S3TC_DXT1_EXT    = 0x83F1,
    GL_COMPRESSED_RGBA_S3TC_DXT3_EXT    = 0x83F2,
    GL_COMPRESSED_RGBA_S3TC_DXT5_EXT    = 0x83F3
}

align(1):
struct DDS_HEADER {
	uint			dwSize;
	uint			dwFlags;
	uint			dwHeight;
	uint			dwWidth;
	uint			dwPitchOrLinearSize;
	uint			dwDepth;
	uint			dwMipMapCount;
	uint[11]		dwReserved1;
	DDS_PIXELFORMAT ddspf;
	uint			dwCaps;
	uint			dwCaps2;
	uint			dwCaps3;
	uint			dwCaps4;
	uint			dwReserved2;
}
/*struct DDS_HEADER_DXT10 {
	DXGI_FORMAT              dxgiFormat;
	D3D10_RESOURCE_DIMENSION resourceDimension;
	UINT                     miscFlag;
	UINT                     arraySize;
	UINT                     miscFlags2;
}*/
struct DDS_PIXELFORMAT {
	uint dwSize;
	uint dwFlags;
	uint dwFourCC;
	uint dwRGBBitCount;
	uint dwRBitMask;
	uint dwGBitMask;
	uint dwBBitMask;
	uint dwABitMask;
}

enum : uint {	// possible flags in DDS_HEADER.dwFlags 
	DDSD_CAPS			= 0x00000001,
	DDSD_HEIGHT			= 0x00000002,
	DDSD_WIDTH			= 0x00000004,
	DDSD_PITCH			= 0x00000008,
	DDSD_PIXELFORMAT	= 0x00001000,
	DDSD_MIPMAPCOUNT	= 0x00020000,
	DDSD_LINEARSIZE		= 0x00080000,
	DDSD_DEPTH			= 0x00800000
}
enum : uint {	// possible flags in DDS_HEADER.dwCaps 
	DDSCAPS_COMPLEX	= 0x00000008,	
	DDSCAPS_TEXTURE	= 0x00001000,
	DDSCAPS_MIPMAP	= 0x00400000
}
enum : uint {	// possible flags in DDS_HEADER.dwCaps2 
	DDSCAPS2_CUBEMAP			= 0x00000200,
	DDSCAPS2_CUBEMAP_POSITIVEX	= 0x00000400,
	DDSCAPS2_CUBEMAP_NEGATIVEX	= 0x00000800,
	DDSCAPS2_CUBEMAP_POSITIVEY	= 0x00001000,
	DDSCAPS2_CUBEMAP_NEGATIVEY	= 0x00002000,
	DDSCAPS2_CUBEMAP_POSITIVEZ	= 0x00004000,
	DDSCAPS2_CUBEMAP_NEGATIVEZ	= 0x00008000,
	DDSCAPS2_VOLUME				= 0x00200000
}
enum : uint {	// possible flags in DDS_HEADER.DDS_PIXELFORMAT.dwFlags
	DDPF_ALPHAPIXELS	= 0x00000001,
	DDPF_ALPHA			= 0x00000002,
	DDPF_FOURCC			= 0x00000004,
	DDPF_RGB			= 0x00000040,
	DDPF_YUV			= 0x00000200,
	DDPF_LUMINANCE		= 0x00020000
}
enum : uint {	// possible values of DDS_HEADER.DDS_PIXELFORMAT.dwFourCC
	FOURCC_DXT1 = 0x31545844, // "DXT1" in ASCII
	FOURCC_DXT3 = 0x33545844, // "DXT3" in ASCII
	FOURCC_DXT5 = 0x35545844, // "DXT5" in ASCII
	FOURCC_DX10 = 0x30315844  // "DX10" in ASCII
}
// -----------------------------------------------------------------------------------
Texture loadDDS(string filename, bool verbose=false) {
	if(!exists(filename)) {
		log("loadDDS: file '%s' does not exist", filename); return null;
	}
	long fileSize = getSize(filename);
	if(verbose) log("loading DDS file '%s' size:%s", filename, fileSize);
	auto file = File(filename, "rb");

	char[] dwMagic = file.rawRead(new char[4]);
	if(dwMagic != "DDS ") {
		log("loadDDS: file '%s' is not a valid DDS file", filename); return null;
	}

	DDS_HEADER header = *cast(DDS_HEADER*)file.rawRead(new ubyte[DDS_HEADER.sizeof]).ptr;
	
	if(header.dwSize!=124) {
		log("loadDDS: DDS_HEADER header size is expected to be 124 bytes"); return null;
	}
	if(header.ddspf.dwSize!=32) {
		log("loadDDS: DDS_PIXELFORMAT header size is expected to be 32 bytes"); return null;
	}
	
	if(verbose) {
		logDDSDFlags(header.dwFlags);
		logPixelFormats(header.ddspf.dwFlags);
		logCaps(header.dwCaps);
		logCaps2(header.dwCaps2);
	}

	if(header.ddspf.dwFourCC==FOURCC_DX10) {
		log("loadDDS: DX10 DDS files are not yet supported"); return null;
	}
	if((header.dwCaps & DDSCAPS_TEXTURE)==0) {
		log("loadDDS: required DDSCAPS_TEXTURE cap is missing"); return null;
	}

	bool compressed = (header.ddspf.dwFlags & DDPF_FOURCC) == DDPF_FOURCC;
	bool cubemap	= (header.dwCaps2 & DDSCAPS2_CUBEMAP) == DDSCAPS2_CUBEMAP;
	bool hasMipMaps = (header.dwCaps & DDSCAPS_MIPMAP) && (header.dwMipMapCount > 1);

	if(verbose) {
		log("width = %s", header.dwWidth);
		log("height = %s", header.dwHeight);
		log("dwPitchOrLinearSize = %s", header.dwPitchOrLinearSize);
		log("depth = %s", header.dwDepth);
		log("mipMapCount = %s", header.dwMipMapCount);
		log("compressed = %s", compressed);
		log("cubemap = %s", cubemap);
		log("hasMipMaps = %s", hasMipMaps);
		log("fourCC = %s", (cast(char*)&(header.ddspf.dwFourCC))[0..4]);
	}

	if(!compressed) {
		log("loadDDS: can only handle compressed DDS files at the moment"); return null;
	}
	if(cubemap) {
		log("loadDDS: can not handle cubemap DDS files at the moment"); return null;
	}

	uint format;
	uint blockSize	= 16;

	switch(header.ddspf.dwFourCC) { 
		case FOURCC_DXT1: 
			format = GL_COMPRESSED_RGBA_S3TC_DXT1_EXT; 
			blockSize = 8;
			break; 
		case FOURCC_DXT3: 
			format = GL_COMPRESSED_RGBA_S3TC_DXT3_EXT; 
			break; 
		case FOURCC_DXT5: 
			format = GL_COMPRESSED_RGBA_S3TC_DXT5_EXT; 
			break; 
		default: 
			log("loadDDS: unable to handle fourCC format (%x)", header.ddspf.dwFourCC);
			return null; 
	}

	uint width			= header.dwWidth;
	uint height			= header.dwHeight;
	uint DDS_main_size	= ((header.dwWidth+3)>>2)*((header.dwHeight+3)>>2)*blockSize;
	uint DDS_full_size	= DDS_main_size;
	int numMipMaps;
	
	if(hasMipMaps) {
		numMipMaps = header.dwMipMapCount - 1;
		int shift_offset = 2;	// compressed
		for(auto i = 1; i <= numMipMaps; ++i) {
			int w, h;
			w = width >> (shift_offset + i);
			h = height >> (shift_offset + i);
			if(w < 1) {
				w = 1;
			}
			if(h < 1) {
				h = 1;
			}
			DDS_full_size += w*h*blockSize;
		}
	}
	if(verbose) {
		log("main size = %s", DDS_main_size);
		log("blockSize = %s", blockSize);
		log("DDS_full_size = %s", DDS_full_size);
	}

	if(DDS_full_size + DDS_HEADER.sizeof + 4 != fileSize) {
		log("loadDDS: expecting DDS_full_size + DDS_HEADER.sizeof + 4 == fileSize"); return null; 
	}

	ubyte[] data = file.rawRead(new ubyte[DDS_full_size]);

	// Create one OpenGL texture
	uint textureID;
	glGenTextures(1, &textureID);
	// "Bind" the newly created texture : all future texture functions will modify this texture
	glBindTexture(GL_TEXTURE_2D, textureID);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);	

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	
	if(hasMipMaps) {
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	} else {
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
	}

	uint offset   = 0;
	int numImages = hasMipMaps ? header.dwMipMapCount : 1;

	// load the mipmaps 
	for(uint level = 0; level < numImages && (width || height); ++level) { 
		uint size = ((width+3)/4)*((height+3)/4)*blockSize; 
		if(verbose) log("[%s] size=%s width=%s height=%s", level, size, width, height); 
		glCompressedTexImage2D(GL_TEXTURE_2D, level, format, width, height,  
							   0, size, data.ptr + offset); 
		uint err = glGetError();
		if(err) {
			log("error: %s", err);
			return null;
		}
		offset += size; 
		width  /= 2; 
		height /= 2; 

		// Deal with Non-Power-Of-Two textures. 
		if(width < 1) width = 1;
		if(height < 1) height = 1;
	} 
	return new Texture2D(
	    filename,
	    textureID,
	    Dimension(header.dwWidth, header.dwHeight),
	    numImages,
	    GL_RGB
    );
}
void logDDSDFlags(uint flags) {
	log("loadDDS: DDSD flags {");
	if(flags&DDSD_CAPS) log("\tDDSD_CAPS");
	if(flags&DDSD_HEIGHT) log("\tDDSD_HEIGHT");
	if(flags&DDSD_WIDTH) log("\tDDSD_WIDTH");
	if(flags&DDSD_PITCH) log("\tDDSD_PITCH");
	if(flags&DDSD_PIXELFORMAT) log("\tDDSD_PIXELFORMAT");
	if(flags&DDSD_MIPMAPCOUNT) log("\tDDSD_MIPMAPCOUNT");
	if(flags&DDSD_LINEARSIZE) log("\tDDSD_LINEARSIZE");
	if(flags&DDSD_DEPTH) log("\tDDSD_DEPTH");
	log("}");
}
void logPixelFormats(uint flags) {
	log("loadDDS: pixel formats {");
	if(flags&DDPF_ALPHAPIXELS) log("\tDDPF_ALPHAPIXELS");
	if(flags&DDPF_ALPHA) log("\tDDPF_ALPHA");
	if(flags&DDPF_FOURCC) log("\tDDPF_FOURCC");
	if(flags&DDPF_RGB) log("\tDDPF_RGB");
	if(flags&DDPF_YUV) log("\tDDPF_YUV");
	if(flags&DDPF_LUMINANCE) log("\tDDPF_LUMINANCE");
	log("}");
}
void logCaps(uint flags) {
	log("loadDDS: caps {");
	if(flags&DDSCAPS_COMPLEX) log("\tDDSCAPS_COMPLEX");
	if(flags&DDSCAPS_TEXTURE) log("\tDDSCAPS_TEXTURE");
	if(flags&DDSCAPS_MIPMAP) log("\tDDSCAPS_MIPMAP");
	log("}");
}
void logCaps2(uint flags) {
	log("loadDDS: caps2 {");
	if(flags&DDSCAPS2_CUBEMAP) log("\tDDSCAPS2_CUBEMAP");
	if(flags&DDSCAPS2_CUBEMAP_POSITIVEX) log("\tDDSCAPS2_CUBEMAP_POSITIVEX");
	if(flags&DDSCAPS2_CUBEMAP_NEGATIVEX) log("\tDDSCAPS2_CUBEMAP_NEGATIVEX");
	if(flags&DDSCAPS2_CUBEMAP_POSITIVEY) log("\tDDSCAPS2_CUBEMAP_POSITIVEY");
	if(flags&DDSCAPS2_CUBEMAP_NEGATIVEY) log("\tDDSCAPS2_CUBEMAP_NEGATIVEY");
	if(flags&DDSCAPS2_CUBEMAP_POSITIVEZ) log("\tDDSCAPS2_CUBEMAP_POSITIVEZ");
	if(flags&DDSCAPS2_CUBEMAP_NEGATIVEZ) log("\tDDSCAPS2_CUBEMAP_NEGATIVEZ");
	if(flags&DDSCAPS2_VOLUME) log("\tDDSCAPS2_VOLUME");
	log("}");
}