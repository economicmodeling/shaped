
import std.stdio,
	std.algorithm,
	std.array,
	std.range;
import shaped;

enum Kilobyte = 2 ^^ 10;
enum FP = "%.8f";

void main(string[] args)
{
	auto data = File(args[1], "rb").byChunk(4 * Kilobyte).joiner();
	auto shapefile = shapeRangeReader(data);
	writefln("Version: %s", shapefile.versionNumber);
	writefln("Shape Type: %s", shapefile.shapeType);
	writefln("Bounds (x): "~FP~" "~FP, shapefile.bounds.xmin, shapefile.bounds.xmax);
	writefln("Bounds (y): "~FP~" "~FP, shapefile.bounds.ymin, shapefile.bounds.ymax);
	writefln("Bounds (z): "~FP~" "~FP, shapefile.bounds.zmin, shapefile.bounds.zmax);
	writefln("Bounds (m): "~FP~" "~FP, shapefile.bounds.mmin, shapefile.bounds.mmax);
	writefln("Number of records: %s", shapefile.walkLength);
}
