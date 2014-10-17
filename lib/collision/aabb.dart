part of p2;

/// Axis aligned bounding box class.
class AABB {
  static final vec2 tmp = vec2.create();
  final vec2  lowerBound= vec2.create();
  final vec2  upperBound= vec2.create();

  AABB({vec2 lowerBound, vec2  upperBound}) {
    /**
     * The lower bound of the bounding box.
     * @property lowerBound
     * @type {Array}
     */
    //this.lowerBound = vec2.create();
    if (lowerBound != null) {
      vec2.copy(this.lowerBound, lowerBound);
    }

    /**
     * The upper bound of the bounding box.
     * @property upperBound
     * @type {Array}
     */
    //this.upperBound = vec2.create();
    if (upperBound != null) {
      vec2.copy(this.upperBound, upperBound);
    }

  }

  /**
   * Set the AABB bounds from a set of points.
   * @method setFromPoints
   * @param {Array} points An array of vec2's.
   */

  setFromPoints(List<vec2> points, [vec2 position, num angle = 0, int skinSize = 0]) {
    vec2 l = this.lowerBound,
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
      vec2 p = points[i];

      if (angle != 0) {
        num x = p.x,
            y = p.y;
        tmp.x = cosAngle * x - sinAngle * y;
        tmp.y = sinAngle * x + cosAngle * y;
        p = tmp;
      }
        if (p.x > u.x) {
          u.x = p.x;
        }
        if (p.x < l.x) {
          l.x = p.x;
        }
        if (p.y > u.y) {
          u.y = p.y;
        }
        if (p.y < l.y) {
          l.y = p.y;
        }
//      for (int j = 0; j < 2; j++) {
//        if (p[j] > u[j]) {
//          u[j] = p[j];
//        }
//        if (p[j] < l[j]) {
//          l[j] = p[j];
//        }
//      }
    }

    // Add offset
    if (position != null) {
      vec2.add(this.lowerBound, this.lowerBound, position);
      vec2.add(this.upperBound, this.upperBound, position);
    }

    if (skinSize != 0) {
      this.lowerBound.x -= skinSize;
      this.lowerBound.y -= skinSize;
      this.upperBound.x += skinSize;
      this.upperBound.y += skinSize;
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
    
    num l = aabb.lowerBound.x;
    if (this.lowerBound.x > l) {
      this.lowerBound.x = l;
    }

    // Upper
    num u = aabb.upperBound.x;
    if (this.upperBound.x < u) {
      this.upperBound.x = u;
    }

    l = aabb.lowerBound.y;
    if (this.lowerBound.y > l) {
      this.lowerBound.y = l;
    }

    // Upper
    u = aabb.upperBound.y;
    if (this.upperBound.y < u) {
      this.upperBound.y = u;
    }
//
//    
//    // Loop over x and y
//    int i = 2;
//    while (i-- > 0) {
//      // Extend lower bound
//      num l = aabb.lowerBound[i];
//      if (this.lowerBound[i] > l) {
//        this.lowerBound[i] = l;
//      }
//
//      // Upper
//      num u = aabb.upperBound[i];
//      if (this.upperBound[i] < u) {
//        this.upperBound[i] = u;
//      }
//    }
  }

  /**
   * Returns true if the given AABB overlaps this AABB.
   * @method overlaps
   * @param  {AABB} aabb
   * @return {Boolean}
   */

  bool overlaps(AABB aabb) {
    vec2 l1 = this.lowerBound,
        u1 = this.upperBound,
        l2 = aabb.lowerBound,
        u2 = aabb.upperBound;

    //      l2        u2
    //      |---------|
    // |--------|
    // l1       u1

    return ((l2.x <= u1.x && u1.x <= u2.x) || (l1.x <= u2.x && u2.x <= u1.x)) && ((l2.y <= u1.y && u1.y <= u2.y) || (l1.y <= u2.y && u2.y <= u1.y));
  }
}
