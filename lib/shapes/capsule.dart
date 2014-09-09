part of p2;

class Capsule extends Shape {
  num length;
  num radius;

  Capsule([this.length=1, this.radius=1]) :super(Shape.CAPSULE);

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

  List r = vec2.create();

  /**
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB (AABB out, List position, num angle){
    num radius = this.radius;

    // Compute center position of one of the the circles, world oriented, but with local offset
    vec2.set(r,this.length / 2,0);
    if(angle != 0){
      vec2.rotate(r,r,angle);
    }

    // Get bounds
    vec2.set(out.upperBound,  max(r[0]+radius, -r[0]+radius),
    max(r[1]+radius, -r[1]+radius));
    vec2.set(out.lowerBound,  min(r[0]-radius, -r[0]-radius),
    min(r[1]-radius, -r[1]-radius));

    // Add offset
    vec2.add(out.lowerBound, out.lowerBound, position);
    vec2.add(out.upperBound, out.upperBound, position);
  }

}
