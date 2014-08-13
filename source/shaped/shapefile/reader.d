/**
 * Provides a lazy, controlled-allocation interface over a raw shapefile.
 * Allocation is minimized by providing lazy ranges over the data: allocations
 *   only occur when they are needed to support requested records, and the user
 *   may deallocate any records which are no longer needed.
 * Iff the supplied input range is a ForwardRange and the associated ShapefileIndexReader
 *  is supplied, the ShapefileReader will also allow random access to records.
 */
module shaped.shapefile.reader;

import std.bitmanip, std.exception, std.system;
import std.range, std.traits;
import shaped.format;

class ShapeReadException : Exception
{
	long recordNumber = -1;
	this(string msg)
	{
		super(msg);
	}

	this(long n, string msg)
	{
		import std.string :format;
		recordNumber = n;
		super("record %s: ".format(n)~msg);
	}
}

ShapeRangeReader!R shapeRangeReader(R)(R input)
	if (isInputRange!(R) && is(ElementType!R : ubyte))
{
	return ShapeRangeReader!R(input);
}


struct ShapefileHeader
{
	int fileCode = 9994;
	int[5] unused;
	int fileLength;

	int versionNumber = 1000;
	ShapeType shapeType;
	BoundingBoxZ bounds;
}
//static assert(ShapefileHeader.sizeof == 100);

struct RecordHeader
{
	int recordNumber;
	int contentLength;	// Measured in 16-bit words

	long contentLengthInBytes() @property const
	{
		return contentLength * 2;
	}
}
//static assert(RecordHeader.sizeof == 8);

alias IndexHeader = ShapefileHeader;

struct IndexRecord
{
	int offset;
	int contentLength;
}
static assert(IndexRecord.sizeof == 8);

/**
 *
 */
struct ShapeRangeReader(R)
	if (isInputRange!(R) && is(ElementType!R : ubyte))
{
	private {
		R _input;
		Shape _front;
		size_t _bytesRead = 0;
		bool _empty = false;

		ShapefileHeader _header;

		static if (isForwardRange!R)
		{
			bool _useIndex = false;
			//ShapeIndexReader _index;
			R _recordStart;	// save point immediately after the main header, allows random access
		}
	}

	/**
	 * 
	 */
	ShapefileHeader header() @property const
	{
		return _header;
	}

	/**
	 * 
	 */
	int versionNumber() @property const
	{
		return _header.versionNumber;
	}

	/**
	 * 
	 */
	long fileLength() @property const
	{
		// measured in 16-bit words, so double for byte length
		return _header.fileLength * 2;
	}

	/**
	 * All shape records in this file will be of this type or of type Null.
	 */
	ShapeType shapeType() @property const
	{
		return _header.shapeType;
	}

	/**
	 * 
	 */
	BoundingBoxZ bounds() @property const
	{
		return _header.bounds;
	}

	/**
	 * Read a shapefile from input.  R must be an input range of ubytes.
	 */
	this(R)(R input)
	{
		_input = input;
		readHeader();

		if (input.empty)
			_empty = true;
		else
			popFront(); // prime _front
	}

	private struct FrontInfo
	{
		int recordNumber;
		int contentLength;
		Shape shape;

		long recordLength() @property const
		{
			return contentLength * 2 + 8;
		}
	}

	///
	const(Shape) front() @property const
	{
		assert(!empty);
		return _front;
	}

	///
	bool empty() @property const
	{
		return _empty;
	}

	///
	void popFront()
	{
		assert(!empty);
		if (_bytesRead >= fileLength)
		{
			_empty = true;
			return;
		}

		auto info = readRecord();
		_front = info.shape;
		_bytesRead += info.recordLength;
	}

	static if (isForwardRange!R)
	{
		///
		auto save() @property const
		{
			return this;
		}
	}

	/*
	 * Reads the main file header from _input
	 */
	private void readHeader()
	{
		import std.conv;
		_header.fileCode = _input.read!(int, Endian.bigEndian);
		//TODO enforce that fileCode == 9994?

		// Skip the twenty unused bytes
		enforce( 20 == _input.popFrontN(20), new ShapeReadException("Insufficient data") );

		_header.fileLength = _input.read!(int, Endian.bigEndian);

		_header.versionNumber = _input.read!(int, Endian.littleEndian);
		_header.shapeType = _input.read!(int, Endian.littleEndian).to!ShapeType;
		_header.bounds = _input.readShape!BoundingBoxZ();

		_bytesRead += 100;
	}

	private FrontInfo readRecord()
	{
		import std.conv;
		FrontInfo info;

		static size_t i;
		try {
			info.recordNumber = _input.read!(int, Endian.bigEndian);
			info.contentLength = _input.read!(int, Endian.bigEndian);

			// Read the type and check that it matches the file shape type
			info.shape.type = _input.read!(int, Endian.littleEndian).to!ShapeType;
			enforce( info.shape.type == _header.shapeType ||
					 info.shape.type == ShapeType.Null,
					new Exception("Mismatched shape type"));


			// Read the actual shape data
		 	final switch (info.shape.type)
			{
				case ShapeType.Null: break;
				case ShapeType.Point:
					info.shape._point = readShape!Point(_input);
					break;
				case ShapeType.PointZ:
					info.shape._pointz = readShape!PointZ(_input);
					break;
				case ShapeType.PointM:
					info.shape._pointm = readShape!PointM(_input);
					break;

				case ShapeType.MultiPoint:
					info.shape._multipoint = readShape!MultiPoint(_input);
					break;
				case ShapeType.MultiPointZ:
					info.shape._multipointz = readShape!MultiPointZ(_input);
					break;
				case ShapeType.MultiPointM:
					info.shape._multipointm = readShape!MultiPointM(_input);
					break;

				case ShapeType.PolyLine:
					info.shape._polyline = readShape!PolyLine(_input);
					break;
				case ShapeType.PolyLineZ:
					info.shape._polylinez = readShape!PolyLineZ(_input);
					break;
				case ShapeType.PolyLineM:
					info.shape._polylinem = readShape!PolyLineM(_input);
					break;

				case ShapeType.Polygon:
					info.shape._polygon = readShape!Polygon(_input);
					break;
				case ShapeType.PolygonZ:
					info.shape._polygonz = readShape!PolygonZ(_input);
					break;
				case ShapeType.PolygonM:
					info.shape._polygonm = readShape!PolygonM(_input);
					break;

				case ShapeType.MultiPatch:
					info.shape._multipatch = readShape!MultiPatch(_input);
					break;
			}
		
		} catch (Exception ex) {
			// Rethrow with the record number information
			throw new ShapeReadException(info.recordNumber, ex.msg);
		}
		return info;
	}
}

private import std.typetuple : staticIndexOf;
public static T readShape(T, R)(ref R input)
	if (isInputRange!R && is(ElementType!R : ubyte) &&
		(staticIndexOf!(T, ShapeTypes, BoundingBoxTypes) != -1))
{
	T ret;
	
	foreach (I, ref field; ret.tupleof)
	{
		alias FT = typeof(field);
		static if (isNumeric!FT)
		{
			field = input.read!(FT, Endian.littleEndian);
		}

		else static if (isArray!FT)
		{
			static if (!isStaticArray!FT)
			{
				// is the length field indicated?
				static assert(__traits(getAttributes, ret.tupleof[I]).length > 0,
								"Missing lengthOf member");
				enum lengthMemberName = __traits(getAttributes, ret.tupleof[I])[0].memberName;

				field.length = mixin(`ret.`~lengthMemberName);
			}

			alias E = ElementType!FT;
			foreach (ref el; field)
			{
				static if (isNumeric!E)
					el = input.read!(E, Endian.littleEndian);
				else
					el = readShape!E(input);
			}
		}

		else static if (is(FT == struct))
		{
			// Recursively build the child structure
			field = readShape!FT(input);
		}
		else
			static assert(false, "Cannot handle field of type "~FT.stringof);

	}

	return ret;
}

