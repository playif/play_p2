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
  static List lineInt(List l1, List l2, [num precision=0]) {

    var i = [0, 0]; // point
    var a1, b1, c1, a2, b2, c2, det; // scalars
    a1 = l1[1][1] - l1[0][1];
    b1 = l1[0][0] - l1[1][0];
    c1 = a1 * l1[0][0] + b1 * l1[0][1];
    a2 = l2[1][1] - l2[0][1];
    b2 = l2[0][0] - l2[1][0];
    c2 = a2 * l2[0][0] + b2 * l2[0][1];
    det = a1 * b2 - a2 * b1;
    if (!Scalar.eq(det, 0, precision)) {
      // lines are not parallel
      i[0] = (b2 * c1 - b1 * c2) / det;
      i[1] = (a1 * c2 - a2 * c1) / det;
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

  static bool segmentsIntersect(List p1, List p2, List q1, List q2) {
    var dx = p2[0] - p1[0];
    var dy = p2[1] - p1[1];
    var da = q2[0] - q1[0];
    var db = q2[1] - q1[1];

    // segments are parallel
    if (da * dy - db * dx == 0)
      return false;

    var s = (dx * (q1[1] - p1[1]) + dy * (p1[0] - q1[0])) / (da * dy - db * dx);
    var t = (da * (p1[1] - q1[1]) + db * (q1[0] - p1[0])) / (db * dx - da * dy);

    return (s >= 0 && s <= 1 && t >= 0 && t <= 1);
  }
}
