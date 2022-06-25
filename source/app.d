import std.stdio : stderr, writeln;
import std.process : execute;
import mir.deser.json : deserializeJson, serdeKeys, serdeIgnoreUnexpectedKeys;
import std.algorithm : find;
import std.range : appender;
import std.file : mkdirRecurse, write, append, exists, readText;
import std.conv : to;
import std.string : format;

@serdeIgnoreUnexpectedKeys struct RootPackage
{
    Package[] packages;
}

@serdeIgnoreUnexpectedKeys struct Package
{
    string name;
    @serdeKeys("version")
    string semVer;
    string license;
    bool active;
}

int main(string[] args)
{
    auto outDir = "out/generated/packageinfo";
    outDir.mkdirRecurse;
    auto outFile = outDir ~ "/package.d";
    auto output = ["dub", "describe"].execute;
    auto result = appender!string;
    if (output.status == 0)
    {
        result.put("module packageinfo;\n");
        result.put("struct PackageInfo\n{\n    string name;\n    string semVer;\n    string license;\n}\n");
        result.put("auto getPackages()\n{\n");
        result.put("    return [\n");
        auto rootPackage = deserializeJson!(RootPackage)(output.output.find("{"));
        foreach (p; rootPackage.packages)
        {
            if (p.active)
            {
                result.put("        PackageInfo(\"" ~ p.name ~ "\", \"" ~ p.semVer ~ "\", \"" ~ p.license ~ "\"),\n");
            }
        }
        result.put("    ];\n");
        result.put("}\n");
        if (outFile.exists) {
            auto currentContent = outFile.readText;
            if (currentContent == result.data) {
                stderr.writeln("%s is already up2date".format(outFile));
                return 0;
            }
        }
        write(outFile, result.data);
        stderr.writeln("Packageinfo has been written to %s".format(outFile));
        return 0;
    }
    return output.status;
}
