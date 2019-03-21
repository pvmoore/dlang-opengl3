module gl.util.obj_loader;

import gl.all;
import std.stdio : File;

OBJModel loadOBJ(OpenGL gl, VAO vao, string filename, bool verbose=true) {
	Vector3[] vertices;
	UV[] uvs;
	Vector3[] normals;

	Vector3[] vFace;
	UV[] uvFace;
	Vector3[] nFace;

	auto file = File(filename, "rb");
	if(!file.isOpen) {
		log("loadOBJ: can't open file '%s'", filename); return null;
	}

	void parseVertex(string[] tokens) {
		vertices ~= Vector3(tokens[1].to!float, tokens[2].to!float, tokens[3].to!float);
		if(verbose) log("vertex[%s] = %s", vertices.length-1, vertices[$-1]);
	}
	void parseFace(string[] tokens) {
		// f v/uv/n 
		if(tokens[1].canFind("/")) {
			for(auto i=0; i<3; i++) {
				string[] ele = tokens[i+1].split("/");
				log("ele=%s", ele); flushLog();

				int v  = ele[0].to!int-1;
				int uv = ele[1].length>0 ? ele[1].to!int-1 : -1;	// may not be present
				int n  = ele[2].length>0 ? ele[2].to!int-1 : -1;	// may not be present

				vFace ~= vertices[v];

				if(uv>=0) {
					uvFace ~= uvs[uv];
				}
				if(n>=0) {
					nFace ~= normals[n];
				}

				if(verbose) log("face v:%s uv:%s n:%s", v,uv,n);
				if(verbose) flushLog();
			}
		} else if(tokens.length==4) {
			// assume f 0 1 2 format
			int v1 = tokens[1].to!int-1;
			int v2 = tokens[2].to!int-1;
			int v3 = tokens[3].to!int-1;
			vFace ~= vertices[v1];
			vFace ~= vertices[v3];
			vFace ~= vertices[v2];
			if(normals.length==vertices.length) {
				nFace ~= normals[v1];
				nFace ~= normals[v3];
				nFace ~= normals[v2];
			}
			if(verbose) log("face v:%s v:%s v:%s", v1, v2, v3);
			if(verbose) flushLog();
		} else {
			// probably f 0 1 2 3 4 5 ... format
			throw new Exception("Unable to load this format yet");
		}
	}
	void parseUV(string[] tokens) {
		uvs ~= UV(tokens[1].to!float, tokens[2].to!float);
		if(verbose) log("uv[%s] = %s", uvs.length-1, uvs[$-1]);
	}
	void parseNormal(string[] tokens) {
		normals ~= Vector3(tokens[1].to!float, tokens[2].to!float, tokens[3].to!float);
		if(verbose) log("normal[%s] = %s", normals.length-1, normals[$-1]);
	}
	void parseMaterial(string[] tokens) {

	}

	foreach(line; file.byLine) {
		line = line.strip();
		if(line.startsWith("#") || line.length==0) continue;
		auto tokens = cast(string[])line.split();
		if(verbose) { log("%s", tokens); flushLog(); }
		switch(tokens[0]) {
			case "v": parseVertex(tokens); break;
			case "vt": parseUV(tokens); break;
			case "vn": parseNormal(tokens); break;
			case "usemtl": parseMaterial(tokens); break;
			//case "mtllib": break;
			case "f": parseFace(tokens); break;
			//case "s": break;
			default: log("unhandled token '%s'", tokens[0]); break;
		}
	}
	return new OBJModel(gl, vao, vFace, uvFace, nFace);
}

