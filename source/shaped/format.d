/**
 * Structures described by the ESRI Shapefile file format.
 * Note: given their rarity, three-dimensional shapefiles and those with the 'M' shape type are not currently supported.
 */
module shaped.format;

import std.typetuple;

struct lengthOf
{
	string memberName;
}

struct BoundingBox
{
	double xmin,
			ymin,
			xmax,
			ymax;
}

struct BoundingBoxM
{
	BoundingBox base;
	alias base this;
	double mmin, mmax;
}

struct BoundingBoxZ
{
	BoundingBox base;
	alias base this;
	double zmin, zmax;
	double mmin, mmax;
}

enum ShapeType : int
{
	Null       = 0,
	Point      = 1,
	PolyLine   = 3,
	Polygon    = 5,
	MultiPoint = 8,
	PointZ     = 11,
	PolyLineZ  = 13,
	PolygonZ   = 15,
	MultiPointZ = 18,
	PointM     = 21,
	PolyLineM  = 23,
	PolygonM   = 25,
	MultiPointM = 28,
	MultiPatch = 31
}

/**
 * A tagged union of all the shape types.
 */
struct Shape
{
	ShapeType type;
	union {
		Point _point;
		PointM _pointm;
		PointZ _pointz;

		MultiPoint _multipoint;
		MultiPointM _multipointm;
		MultiPointZ _multipointz;

		PolyLine _polyline;
		PolyLineM _polylinem;
		PolyLineZ _polylinez;

		Polygon _polygon;
		PolygonM _polygonm;
		PolygonZ _polygonz;

		MultiPatch _multipatch;
	}
}

alias ShapeTypes = TypeTuple!(Point, PointM, PointZ,
                              MultiPoint, MultiPointM, MultiPointZ,
							  PolyLine, PolyLineM, PolyLineZ,
							  Polygon, PolygonM, PolygonZ,
							  MultiPatch);
alias BoundingBoxTypes = TypeTuple!(BoundingBox, BoundingBoxM, BoundingBoxZ);

struct Point
{
	double x, y;
}
static assert(Point.sizeof == 16);

struct PointM
{
	double x, y, m;
}

struct PointZ
{
	double x, y, z, m;
}


struct MultiPoint
{
	BoundingBox bounds;
	int numPoints;
	@lengthOf(`numPoints`) Point[] points;
}

struct MultiPointM
{
	BoundingBoxM bounds;
	int numPoints;
	@lengthOf(`numPoints`) PointM[] points;
}

struct MultiPointZ
{
	BoundingBoxZ bounds;
	int numPoints;
	@lengthOf(`numPoints`) PointZ[] points;
}

struct PolyLine
{
	BoundingBox bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numPoints`) Point[] points;
}

struct PolyLineM
{
	BoundingBoxM bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numPoints`) PointM[] points;
}

struct PolyLineZ
{
	BoundingBoxZ bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numPoints`) PointZ[] points;
}

struct Polygon
{
	BoundingBox bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numPoints`) Point[] points;
}

struct PolygonM
{
	BoundingBoxM bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numPoints`) PointM[] points;
}

struct PolygonZ
{
	BoundingBoxZ bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numPoints`) PointZ[] points;
}

enum PatchType : int
{
	TriangleStrip = 0,
	TriangleFan   = 1,
	OuterRing     = 2,
	InnerRing     = 3,
	FirstRing     = 4,
	Ring          = 5
}

struct MultiPatch
{
	BoundingBox bounds;
	int numParts;
	int numPoints;
	@lengthOf(`numParts`) int[] partStarts;
	@lengthOf(`numParts`) int[] partTypes;
	@lengthOf(`numPoints`) Point[] points;

	double[2] zRange;
	@lengthOf(`numPoints`) double[] zArray;

	double[2] mRange;
	@lengthOf(`numPoints`) double[] mArray;
}

