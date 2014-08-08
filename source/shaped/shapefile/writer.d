module shaped.shapefile.writer;

import std.typecons;
import shaped.format;

//TODO ShapeFileWriter: if the file allows rewind() we can dispense with writing
//      the header and body separately.

struct ShapeRangeWriter(R, RH, RI, RIH)
{
	enum WithIndex = is(RI) && is(RIH);
	private {
		R _recordOutput;
		RH _headerOutput;
		ShapefileHeader _header;

		static if (WithIndex)
		{
			RI _indexOutput;
			RIH _indexHeaderOutput;
			IndexHeader _header;
		}
	}

	/**
	 * The file header is written to headerOutput while the records are written
	 *  to recordOutput.
	 */
	this(RH, R)(ref RH header, ref R records)
		if (isOutputRange!(RH, ubyte) && isOutputRange!(R, ubyte))
	{
		_headerOutput = header;
		_recordOutput = records;
	}

	template isOutputRangeOfUbyte(T)
	{
		enum isOutputRangeOfUbyte = isOutputRange!(T, ubyte);
	}

	/**
	 * Similar to above constructor, also writes an index file (.shx) in two parts:
	 *  header and records.
	 */
	this(RH, R, RI, RIH)(ref RH header, ref R records, ref RIH indexHeader, ref RI indexRecords)
		if (allSatisfy!(isOutputRangeOfUbyte, RH, R, RI, RIH))
	{
		this(header, records);
		_indexHeaderOutput = indexHeader;
		_indexOutput = indexRecords;
	}

	/**
	 * 
	 */
	void put(const Shape shp)
	{
		// Output the shape data

		// Update the header

		static if (WithIndex)
		{
			// Output an index record

			// Update the index header
		}
	}
}
