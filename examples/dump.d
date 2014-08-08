
import std.stdio,	
	std.algorithm;
import shaped;

void main(string[] args)
{
	bool includeDBF = true;

	args.getopt(
		"no-db", { includeDBF = false; }
	);

	auto shapes = Shapefile(File(args[1], "rb").byChunk(4096).joiner);
	
	foreach (shape; shapes)
	{
		
	}
}
