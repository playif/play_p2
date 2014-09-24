part of p2;

/// Axis aligned bounding box class.
class AABB {
  List tmp = vec2.create();
  List lowerBound;
  List upperBound;

  AABB({List lowerBound, List upperBound}) {
    /**
     * The lower bound of the bounding box.
     * @property lowerBound
     * @type {Array}
     */
    this.lowerBound = vec2.create();
    if (lowerBound != null) {
      vec2.copy(this.lowerBound, lowerBound);
    }

    /**
     * The upper bound of the bounding box.
     * @property upperBound
     * @type {Array}
     */
    this.upperBound = vec2.create();
    if (upperBound != null) {
      vec2.copy(this.upperBound, upperBound);
    }

  }

  /**
   * Set the AABB bounds from a set of points.
   * @method setFromPoints
   * @param {Array} points An array of vec2's.
   */

  setFromPoints(List points, [List position, num angle = 0, int skinSize = 0]) {
    List l = this.lowerBound,
        u = this.upperBound;


    // Set to the first point
    if (angle != 0) {
      vec2.rotate(l, points[0], angle);
    } else {
      vec2.copy(l, points[0]);
    }
    vec2.copy(u, l);

    // Compute cosines and sines just once
    num cosAngle = cos(angle),
        sinAngle = sin(angle);
    for (int i = 1; i < points.length; i++) {
      List p = points[i];

      if (angle != 0) {
        num x = p[0],
            y = p[1];
        tmp[0] = cosAngle * x - sinAngle * y;
        tmp[1] = sinAngle * x + cosAngle * y;
        p = tmp;
      }

      for (int j = 0; j < 2; j++) {
        if (p[j] > u[j]) {
          u[j] = p[j];
        }
        if (p[j] < l[j]) {
          l[j] = p[j];
        }
      }
    }

    // Add offset
    if (position != null) {
      vec2.add(this.lowerBound, this.lowerBound, position);
      vec2.add(this.upperBound, this.upperBound, position);
    }

    if (skinSize != 0) {
      this.lowerBound[0] -= skinSize;
      this.lowerBound[1] -= skinSize;
      this.upperBound[0] += skinSize;
      this.upperBound[1] += skinSize;
    }
  }

  /**
   * Copy bounds from an AABB to this AABB
   * @method copy
   * @param  {AABB} aabb
   */

  copy(AABB aabb) {
    vec2.copy(this.lowerBound, aabb.lowerBound);
    vec2.copy(this.upperBound, aabb.upperBound);
  }

  /**
   * Extend this AABB so that it covers the given AABB too.
   * @method extend
   * @param  {AABB} aabb
   */

  extend(AABB aabb) {
    // Loop over x and y
    int i = 2;
    while (i-- > 0) {
      // Extend lower bound
      num l = aabb.lowerBound[i];
      if (this.lowerBound[i] > l) {
        this.lowerBound[i] = l;
      }

      // Upper
      num u = aabb.upperBound[i];
      if (this.upperBound[i] < u) {
        this.upperBound[i] = u;
      }
    }
  }

  /**
   * Returns true if the given AABB overlaps this AABB.
   * @method overlaps
   * @param  {AABB} aabb
   * @return {Boolean}
   */

  bool overlaps(AABB aabb) {
    List l1 = this.lowerBound,
        u1 = this.upperBound,
        l2 = aabb.lowerBound,
        u2 = aabb.upperBound;

    //      l2        u2
    //      |---------|
    // |--------|
    // l1       u1

    return ((l2[0] <= u1[0] && u1[0] <= u2[0]) || (l1[0] <= u2[0] && u2[0] <= u1[0])) && ((l2[1] <= u1[1] && u1[1] <= u2[1]) || (l1[1] <= u2[1] && u2[1] <= u1[1]));
  }
}
