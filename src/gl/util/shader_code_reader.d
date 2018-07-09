module gl.util.shader_code_reader;
/**
 * Reads shader code including any #include directives.
 *
 * Includes must be relative to one of the directories
 * provided.
 */
import gl.all;
import std.stdio : File;
import std.array : join;

final class ShaderCodeReader {
private:
    string mainFile;
    string[] directories;
    string[] defines;
    bool[string] filesLoaded;
public:
    this(string mainFile,
         string[] directories,
         string[] defines)
    {
        this.mainFile    = mainFile;
        this.directories = directories.map!( it=>
            buildNormalizedPath(absolutePath(it))
        ).array;
        this.defines = defines;
    }
    string read() {
        return read(mainFile);
    }
private:
    string read(string filename) {
        string key = findFile(filename);
        if(key in filesLoaded) {
            //log("file %s already loaded", key);
            return "";
        }
        filesLoaded[key] = true;

        bool isMainFile = filesLoaded.length==1;
        scope f = File(key, "r");
        auto app = appender!(string[]);

        foreach(line; f.byLineCopy()) {
            line = line.strip();
            if(line.length==0) continue;
            if(line.startsWith("//")) continue;
            if(line.startsWith("#include")) {
                app ~= read(parseInclude(line));
            } else {
                app ~= line;
            }
        }
        string[] data = app.data;
        if(isMainFile &&
           data.length>0 &&
           defines.length>0)
        {
            data = data[0] ~ defines ~ data[1..$];
        }
        string code = data.join("\n");
        if(code.length==0) code=" ";
        return code;
    }
    string findFile(string filename) {
        if(exists(filename)) return filename;
        foreach(inc; directories) {
            auto f = absolutePath(filename, inc);
            //log("f=%s", f);
            if(exists(f)) return f;
        }
        throw new Error("Can't find shader include '%s'".format(filename));
    }
    /// #include "path"
    string parseInclude(string line) {
        auto quote  = line.indexOf("\"");
        auto quote2 = line.indexOf("\"", quote+1);
        return line[quote+1..quote2];
    }
}

