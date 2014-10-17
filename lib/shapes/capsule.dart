part of p2;

class Capsule extends Shape {
  num length;
  num radius;

  Capsule([this.length=1, this.radius=1]) :super(Shape.CAPSULE);

  /// Compute the mass moment of inertia of the Capsule.
  num computeMomentOfInertia(num mass){
      // Approximate with rectangle
      num r = this.radius,
          w = this.length + r, // 2*r is too much, 0 is too little
          h = r*2;
      return mass * (h*h + w*w) / 12;
  }
  
  /**
   * @method updateBoundingRadius
   */
  updateBoundingRadius(){
    this.boundingRadius = this.radius + this.length/2;
  }

  /**
   * @method updateArea
   */
  updateArea (){
    this.area = PI * this.radius * this.radius + this.radius * 2 * this.length;
  }

  static final vec2 r = vec2.create();

  /**
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB (AABB out, [vec2 position, num angle]){
    num radius = this.radius;

    // Compute center position of one of the the circles, world oriented, but with local offset
    vec2.set(r,this.length / 2,0);
    if(angle != 0){
      vec2.rotate(r,r,angle);
    }

    // Get bounds
    vec2.set(out.upperBound,  max(r.x+radius, -r.x+radius),
    max(r.y+radius, -r.y+radius));
    vec2.set(out.lowerBound,  min(r.x-radius, -r.x-radius),
    min(r.y-radius, -r.y-radius));

    // Add offset
    vec2.add(out.lowerBound, out.lowerBound, position);
    vec2.add(out.upperBound, out.upperBound, position);
  }

}
