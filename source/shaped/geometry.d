module shaped.geometry;

import shaped.format;

/**
 */
bool isValidRing(const Point[] points)
{
	return points.length > 1 &&
			points[0] == points[$-1];	// must be closed
}

/**
 *
 */
enum hasRings(T) = is(typeof(T.numParts) == int)
                   && is(typeof(T.numPoints) == int)
                   && is(typeof(T.partStarts) == int[])
                   && is(typeof(T.points));

/**
 *
 */
auto rings(S)(const S shape) if (hasRings!S)
{
	struct RingTraverser
	{
		private const S s;
		private int partIndex = 0;
		private int pointIndex = 0;

		bool empty() @property const
		{
			return partIndex > s.numParts;
		}

		void popFront()
		{
			assert(!empty);
			if (++partIndex < s.numParts)
				pointIndex = s.partStarts[partIndex];
		}

		auto front() @property const
		{
			return s.points[pointIndex .. nextPointIndex];
		}

		auto length() @property const
		{
			return cast(size_t)s.numParts;
		}

		auto save() @property
		{
			return this;
		}

		private int nextPointIndex() @property const
		{
			return (s.numParts > partIndex + 1) ? s.partStarts[partIndex + 1] : s.numPoints;
		}
	}
	return RingTraverser(shape);
}

///
bool isPointType(const ShapeType type) pure nothrow
{
	return type % 10 == 1;
}
static assert(ShapeType.Point.isPointType);
static assert(ShapeType.PointZ.isPointType);
static assert(ShapeType.PointM.isPointType);

///
bool isPolyLineType(const ShapeType type) pure nothrow
{
	return type % 10 == 3;
}
static assert(ShapeType.PolyLine.isPolyLineType);
static assert(ShapeType.PolyLineZ.isPolyLineType);
static assert(ShapeType.PolyLineM.isPolyLineType);

///
bool isPolygonType(const ShapeType type) pure nothrow
{
	return type % 10 == 5;
}
static assert(ShapeType.Polygon.isPolygonType);
static assert(ShapeType.PolygonZ.isPolygonType);
static assert(ShapeType.PolygonM.isPolygonType);

///
bool isMultiPointType(const ShapeType type) pure nothrow
{
	return type % 10 == 8;
}
static assert(ShapeType.MultiPoint.isMultiPointType);
static assert(ShapeType.MultiPointZ.isMultiPointType);
static assert(ShapeType.MultiPointM.isMultiPointType);
