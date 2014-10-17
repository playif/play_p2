part of p2;

class Rectangle extends Convex {
  num width;
  num height;

  Rectangle([this.width = 1, this.height = 1]) : super._() {
    List<vec2> verts = [vec2.fromValues(-width / 2, -height / 2), vec2.fromValues(width / 2, -height / 2), vec2.fromValues(width / 2, height / 2), vec2.fromValues(-width / 2, height / 2)];
    List<vec2> axes = [vec2.fromValues(1, 0), vec2.fromValues(0, 1)];


    this.type = Shape.RECTANGLE;
    super.init(verts, axes);
  }

  /**
   * Compute moment of inertia
   * @method computeMomentOfInertia
   * @param  {Number} mass
   * @return {Number}
   */
  num computeMomentOfInertia(num mass) {
    num w = this.width,
        h = this.height;
    return mass * (h * h + w * w) / 12;
  }

  /**
   * Update the bounding radius
   * @method updateBoundingRadius
   */
  updateBoundingRadius() {
    num w = this.width,
        h = this.height;
    this.boundingRadius = sqrt(w * w + h * h) / 2;
  }

  static final vec2 corner1 = vec2.create(),
      corner2 = vec2.create(),
      corner3 = vec2.create(),
      corner4 = vec2.create();

  /**
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB(AABB out, [vec2 position, num angle]) {
    out.setFromPoints(this.vertices, position, angle, 0);
  }

  updateArea() {
    this.area = this.width * this.height;
  }
}
