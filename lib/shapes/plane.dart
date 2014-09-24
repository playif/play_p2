part of p2;


class Plane extends Shape {
  Plane() :super(Shape.PLANE);

  /**
   * Compute moment of inertia
   * @method computeMomentOfInertia
   */

  num computeMomentOfInertia(num mass) {
    return 0;
    // Plane is infinite. The inertia should therefore be infinty but by convention we set 0 here
  }

  /**
   * Update the bounding radius
   * @method updateBoundingRadius
   */

  updateBoundingRadius() {
    this.boundingRadius = double.MAX_FINITE;
  }

  /**
   * @method computeAABB
   * @param  {AABB}   out
   * @param  {Array}  position
   * @param  {Number} angle
   */

  computeAABB(AABB out, [List position, num angle]) {
    num a = 0;
    //set = vec2.set;
    if (angle is num) {
      a = angle % (2 * PI);
    }
    
    if (a == 0) {
      // y goes from -inf to 0
      vec2.set(out.lowerBound, -double.MAX_FINITE, -double.MAX_FINITE);
      vec2.set(out.upperBound, double.MAX_FINITE, 0);
    } else if (a == PI / 2) {
      // x goes from 0 to inf
      vec2.set(out.lowerBound, 0, -double.MAX_FINITE);
      vec2.set(out.upperBound, double.MAX_FINITE, double.MAX_FINITE);
    } else if (a == PI) {
      // y goes from 0 to inf
      vec2.set(out.lowerBound, -double.MAX_FINITE, 0);
      vec2.set(out.upperBound, double.MAX_FINITE, double.MAX_FINITE);
    } else if (a == 3 * PI / 2) {
      // x goes from -inf to 0
      vec2.set(out.lowerBound, -double.MAX_FINITE, -double.MAX_FINITE);
      vec2.set(out.upperBound, 0, double.MAX_FINITE);
    } else {
      // Set max bounds
      vec2.set(out.lowerBound, -double.MAX_FINITE, -double.MAX_FINITE);
      vec2.set(out.upperBound, double.MAX_FINITE, double.MAX_FINITE);
    }

    vec2.add(out.lowerBound, out.lowerBound, position);
    vec2.add(out.upperBound, out.upperBound, position);
  }

  updateArea() {
    this.area = double.MAX_FINITE;
  }


}
