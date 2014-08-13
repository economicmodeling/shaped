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
