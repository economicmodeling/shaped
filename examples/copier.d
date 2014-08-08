/**
 * This program takes a path to a shapefile as an argument, parses it, and builds
 *  a verified copy.  An index file (.shx) is automatically produced for
 *  the copy (which can be renamed to match with the original).
 * The copy is produced in the current directory and named "<original>.copy.shp"
 */
 import shaped;

 void main(string[] args)
 {
	import std.algorithm, std.stdio;
	import std.exception : enforce;
	enforce(args.length == 2, "You must supply a path to a shapefile");

	auto inputPath = args[1];
	auto basename = inputPath.baseName.stripExtension;
	auto outputPathRoot = basename ~ ".copy";

	// Open the file and wrap it in a reader
	auto inputData = File(inputPath, "rb").byChunk(4096).joiner;
	auto reader = ShapeReader(inputData);

	// Open the destination file for writing (binary mode) and file for writing
	//  the index to.
	auto outputData = File(outputPathRoot ~ ".shp", "wb");
	auto indexData = File(outputPathRoot ~ ".shx", "wb");

	auto writer = ShapeWriter(outputData, indexData);

	// Start writing records
	foreach (shape; reader)
		writer.put(shape);

	// Manually close the files to ensure output is flushed before checking results
	outputData.close();
	indexData.close();

	//TODO compare original to copy
 }
