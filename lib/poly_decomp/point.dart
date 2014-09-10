part of poly_decomp;

class Point {
  /**
   * Get the area of a triangle spanned by the three given points. Note that the area will be negative if the points are not given in counter-clockwise order.
   * @static
   * @method area
   * @param  {Array} a
   * @param  {Array} b
   * @param  {Array} c
   * @return {Number}
   */
  static num area(List a, List b, List c) {
    return (((b[0] - a[0]) * (c[1] - a[1])) - ((c[0] - a[0]) * (b[1] - a[1])));
  }

  static bool left(List a, List b, List c) {
    return Point.area(a, b, c) > 0;
  }

  static bool leftOn(List a, List b, List c) {
    return Point.area(a, b, c) >= 0;
  }

  static bool right(List a, List b, List c) {
    return Point.area(a, b, c) < 0;
  }

  static bool rightOn(List a, List b, List c) {
    return Point.area(a, b, c) <= 0;
  }

  List tmpPoint1 = [],
  tmpPoint2 = [];

  /**
   * Check if three points are collinear
   * @method collinear
   * @param  {Array} a
   * @param  {Array} b
   * @param  {Array} c
   * @param  {Number} [thresholdAngle=0] Threshold angle to use when comparing the vectors. The function will return true if the angle between the resulting vectors is less than this value. Use zero for max precision.
   * @return {Boolean}
   */

  static bool collinear(List a, List b, List c, [num thresholdAngle=0]) {
    if (thresholdAngle == 0)
      return Point.area(a, b, c) == 0;
    else {
      List ab = tmpPoint1,
      bc = tmpPoint2;

      ab[0] = b[0] - a[0];
      ab[1] = b[1] - a[1];
      bc[0] = c[0] - b[0];
      bc[1] = c[1] - b[1];

      var dot = ab[0] * bc[0] + ab[1] * bc[1],
      magA = sqrt(ab[0] * ab[0] + ab[1] * ab[1]),
      magB = sqrt(bc[0] * bc[0] + bc[1] * bc[1]),
      angle = acos(dot / (magA * magB));
      return angle < thresholdAngle;
    }
  }

  static sqdist(List a, List b) {
    num dx = b[0] - a[0];
    num dy = b[1] - a[1];
    return dx * dx + dy * dy;
  }
}
