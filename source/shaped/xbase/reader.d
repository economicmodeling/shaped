module shaped.xbase.reader;

import std.algorithm,
	std.exception,
	std.range,
	std.encoding;

///
enum xBaseDataType : char {
    Binary 		    = 'B',
	Character       = 'C',
	Date 	        = 'D',
	Numeric	        = 'N',
	Logical	        = 'L',
	Memo 	        = 'M',
	Timestamp       = '@',
	Long 	        = 'l',
	Autoincrement   = '+',
	Float	        = 'F',
	Double	        = 'O',
	OLE             = 'G'
}

/**
 * The header structure begins every xBase database.
 */
align(1) struct xBaseHeader {
	align(1):
    ubyte versionNumber;		// 0
	ubyte[3] modifiedDate;		// 1 	YYMMDD
	uint numRecords;			// 4
	ushort headerLength;		// 8
	ushort recordLength;		// 10

	ubyte[2] reserved1;			// 12
	ubyte incompleteTransactionFlag;	// 14
	ubyte encryptionFlag;		// 15
	uint freeRecordThread;		// 16

	ubyte[8] reserved2;			// 20-27
	ubyte mdxFlag;				// 28
	ubyte languageDriver;		// 29
	ubyte[2] reserved3;			// 30-31
}
static assert(xBaseHeader.sizeof == 32);

/**
 * Field descriptors specify the columns in the database.
 */
align(1) struct xBaseFieldDescriptor {
	align(1):
    Latin1Char[11] _name;		// 0-10
	xBaseDataType type;		// 11
	uint dataAddress;	// 12-15
	ubyte length;		// 16
	ubyte decimalCount;	// 17
	ubyte[2] reserved1;	// 18-19
	ubyte workAreaID;	// 20
	ubyte[2] reserved2;	// 21-22
	ubyte setFieldsFlag;// 23
	ubyte[7] reserved3;	// 24-30
	ubyte indexFlag;	// 31

	string name() @property const
	{
		string ret;
		transcode(cast(Latin1String)_name, ret);
		return ret;
	}

    /**
     * Ensures that a value will fit the field, padding or truncating when
     *  necessary.
     */
	string formatValue(string v)
	{
		import std.string : leftJustify;
		if (v.length > length)
			return v[0..this.length];   // too long, truncate

		if (v.length < length)
			return v.leftJustify(length);   // too short, pad

		return v;
	}
}
static assert(xBaseFieldDescriptor.sizeof == 32);

/**
 * 
 */
struct xBaseRow
{
	private xBaseFieldDescriptor[] _columns;
	private ushort[] _offsets;
	Latin1String _slice;

	private ubyte i = 0;

	///
	bool isDeleted() @property const
	{
		return _slice[0] == '*';
	}

	auto fields() @property
	{
		static struct FieldTraverser
		{
			private xBaseRow parent;
			private ushort i = 0;
			
			bool empty() @property const
			{
				return i >= parent._columns.length;
			}

			auto front() @property const
			{
				assert(!empty);
				return value(i);
			}

			void popFront()
			{
				assert(!empty);
				++i;
			}

			auto save() @property
			{
				return this;
			}

			auto opIndex(size_t i) @property const
			{
				return value(i);
			}

			private string value(size_t index) @property const
			{
				string ret;
				auto o = parent._offsets[index];
				transcode(parent._slice[o .. o + parent._columns[index].length], ret);
				return ret;
			}
		}
		return FieldTraverser(this);
	}
	alias fields this;
}

/**
 *
 */
auto xBaseRecords(R)(R input)
{
	return xBaseRangeReader!R(input);
}


/**
 * 
 */
struct xBaseRangeReader(R)
{
	private {
		R _input;
		xBaseRow _front;

		xBaseHeader _header;
		xBaseFieldDescriptor[] _columns;
		ushort[] _fieldOffsets;

		bool _empty = false;
		size_t curRecordI = 0;
	}
	bool ignoreDeleted = true;	///

	///
	xBaseHeader header() @property const
	{
		return _header;
	}

	const(xBaseFieldDescriptor[]) columns() @property const
	{
		return _columns;
	}

	this(R)(R input)
	{
		_input = input;

		readHeader();

		if (_input.empty)
			_empty = true;
		else
			popFront();	// prime _front
	}

	bool empty() @property// const
	{
		return _empty;
	}

	xBaseRow front() @property// const
	{
		assert(!empty);
		return _front;
	}

	void popFront()
	{
		assert(!empty);
		if (_input.empty || _input.front == 0x1a || curRecordI >= _header.numRecords)
		{
			_empty = true;
			return;
		}

		/* static if (hasSlicing!R) */
		/* 	_front = xBaseRow( _columns, _fieldOffsets, _input[0 .. _header.recordLength].dup); */
		/* else { */
			static Latin1Char[] rowBuf;
			if (!rowBuf)
				rowBuf = new Latin1Char[](_header.recordLength);
			foreach (ref el; rowBuf)
			{
				assert(!_input.empty);
				el = cast(Latin1Char)_input.front;
				_input.popFront();
			}
			_front = xBaseRow( _columns, _fieldOffsets, rowBuf[0 .. _header.recordLength].idup);
			++curRecordI;
		/* } */
	}

	auto length() @property const
	{
		return _header.numRecords;
	}

	static if (isForwardRange!R)
		auto save() @property
		{
			return this;
		}


	private:
	void readHeader()
	{
		ubyte[32] buf;
		void fillBuf()
		{
			foreach (ref el; buf)
			{
				enforce( !_input.empty, "Insufficient input" );
				el = _input.front;
				_input.popFront();
			}
		}

		// Read header
		fillBuf();
		_header = *(cast(xBaseHeader*)buf.ptr);

		// Calculate number of columns from the remaining header length
		_columns.length = cast(ubyte)((_header.headerLength - 33) / 32);
		_fieldOffsets.length = _columns.length;

		// Read field descriptors in
		ushort offset = 1;
		foreach (i, ref col; _columns)
		{
			fillBuf();
			col = *(cast(xBaseFieldDescriptor*)buf.ptr);
			_fieldOffsets[i] = offset;
			offset += col.length;
		}

		// Ensure that the terminator properly delimits the header
		enforce(!_input.empty && _input.front == '\r', "Insufficient input");

		// We should now be at the records proper
		_input.popFront();
	}
}

