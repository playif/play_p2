part of p2;

class Circle extends Shape {
  num radius;

  Circle([this.radius=1]): super(Shape.CIRCLE);

  /**
   * @method computeMomentOfInertia
   * @param  {Number} mass
   * @return {Number}
   */
  num computeMomentOfInertia (num mass){
    num r = this.radius;
    return mass * r * r / 2;
  }

  /**
   * @method updateBoundingRadius
   * @return {Number}
   */
  updateBoundingRadius (){
    this.boundingRadius = this.radius;
  }

  /**
   * @method updateArea
   * @return {Number}
   */
  updateArea (){
    this.area = PI * this.radius * this.radius;
  }

  /**
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB (AABB out, [List position, num angle]){
    num r = this.radius;
    vec2.set(out.upperBound,  r,  r);
    vec2.set(out.lowerBound, -r, -r);
    if(position != null){
      vec2.add(out.lowerBound, out.lowerBound, position);
      vec2.add(out.upperBound, out.upperBound, position);
    }
  }

}
