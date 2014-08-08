module shaped.geometry;

import shaped.format;

/**
 */
bool isValidRing(const Point[] points)
{
	return points.length > 1 &&
			points[0] == points[$-1];	// must be closed
}
