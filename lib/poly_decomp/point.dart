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
  static num area(vec2 a, vec2 b, vec2 c) {
    return (((b.x - a.x) * (c.y - a.y)) - ((c.x - a.x) * (b.y - a.y)));
  }

  static bool left(vec2 a, vec2 b, vec2 c) {
    return Point.area(a, b, c) > 0;
  }

  static bool leftOn(vec2 a, vec2 b, vec2 c) {
    return Point.area(a, b, c) >= 0;
  }

  static bool right(vec2 a, vec2 b, vec2 c) {
    return Point.area(a, b, c) < 0;
  }

  static bool rightOn(vec2 a, vec2 b, vec2 c) {
    return Point.area(a, b, c) <= 0;
  }

  static final vec2 tmpPoint1 = new vec2(0.0,0.0),
  tmpPoint2 = new vec2(0.0,0.0);

  /**
   * Check if three points are collinear
   * @method collinear
   * @param  {Array} a
   * @param  {Array} b
   * @param  {Array} c
   * @param  {Number} [thresholdAngle=0] Threshold angle to use when comparing the vectors. The function will return true if the angle between the resulting vectors is less than this value. Use zero for max precision.
   * @return {Boolean}
   */

  static bool collinear(vec2 a, vec2 b, vec2 c, [num thresholdAngle=0]) {
    if (thresholdAngle == 0)
      return Point.area(a, b, c) == 0;
    else {
      vec2 ab = tmpPoint1,
      bc = tmpPoint2;

      ab.x = b.x - a.x;
      ab.y = b.y - a.y;
      bc.x = c.x - b.x;
      bc.y = c.y - b.y;

      num dot = ab.x * bc.x + ab.y * bc.y,
      magA = sqrt(ab.x * ab.x + ab.y * ab.y),
      magB = sqrt(bc.x * bc.x + bc.y * bc.y),
      angle = acos(dot / (magA * magB));
      return angle < thresholdAngle;
    }
  }

  static sqdist(vec2 a, vec2 b) {
    num dx = b.x - a.x;
    num dy = b.y - a.y;
    return dx * dx + dy * dy;
  }
}
