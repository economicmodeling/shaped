
import std.stdio,
	std.algorithm,
	std.conv,
	std.encoding,
	std.getopt;
import shaped.xbase.reader;

void main(string[] args)
{
	bool includedDeleted = false;

	args.getopt(
		"include-deleted|d", &includedDeleted
	);

	auto rawdata = File(args[1], "rb").byChunk(4096).joiner;
	auto database = xBaseRecords(rawdata);
	database.columns.map!(c => c.name).joiner("\t").writeln;
	database.filter!(r => !r.isDeleted || includedDeleted)
			.map!(r => r.fields.joiner("\t"))
			.joiner("\n")
			.copy(stdout.lockingTextWriter());
}
