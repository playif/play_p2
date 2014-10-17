part of poly_decomp;

class Line {
  /**
   * Compute the intersection between two lines.
   * @static
   * @method lineInt
   * @param  {Array}  l1          Line vector 1
   * @param  {Array}  l2          Line vector 2
   * @param  {Number} precision   Precision to use when checking if the lines are parallel
   * @return {Array}              The intersection point.
   */
  static vec2 lineInt(List<vec2> l1, List<vec2> l2, [num precision=0]) {

    vec2 i = new vec2(0.0,0.0); // point
    num a1, b1, c1, a2, b2, c2, det; // scalars
    a1 = l1[1].y - l1[0].y;
    b1 = l1[0].x - l1[1].x;
    c1 = a1 * l1[0].x + b1 * l1[0].y;
    a2 = l2[1].y - l2[0].y;
    b2 = l2[0].x - l2[1].x;
    c2 = a2 * l2[0].x + b2 * l2[0].y;
    det = a1 * b2 - a2 * b1;
    if (!Scalar.eq(det, 0, precision)) {
      // lines are not parallel
      i.x = (b2 * c1 - b1 * c2) / det;
      i.y = (a1 * c2 - a2 * c1) / det;
    }
    return i;
  }

  /**
   * Checks if two line segments intersects.
   * @method segmentsIntersect
   * @param {Array} p1 The start vertex of the first line segment.
   * @param {Array} p2 The end vertex of the first line segment.
   * @param {Array} q1 The start vertex of the second line segment.
   * @param {Array} q2 The end vertex of the second line segment.
   * @return {Boolean} True if the two line segments intersect
   */

  static bool segmentsIntersect(vec2 p1, vec2 p2, vec2 q1, vec2 q2) {
    num dx = p2.x - p1.x;
    num dy = p2.y - p1.y;
    num da = q2.x - q1.x;
    num db = q2.y - q1.y;

    // segments are parallel
    if (da * dy - db * dx == 0)
      return false;

    num s = (dx * (q1.y - p1.y) + dy * (p1.x - q1.x)) / (da * dy - db * dx);
    num t = (da * (p1.y - q1.y) + db * (q1.x - p1.x)) / (db * dx - da * dy);

    return (s >= 0 && s <= 1 && t >= 0 && t <= 1);
  }
}
