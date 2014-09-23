part of p2;

/**
 * Particle shape class.
 * @class Particle
 * @constructor
 * @extends Shape
 */
class Particle extends Shape {
  Particle() : super(Shape.PARTICLE);

  num computeMomentOfInertia (num mass){
    return 0; // Can't rotate a particle
  }

  updateBoundingRadius (){
    this.boundingRadius = 0;
  }

  /**
   * @method computeAABB
   * @param  {AABB}   out
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB (AABB out, [List position, num angle]){
    vec2.copy(out.lowerBound, position);
    vec2.copy(out.upperBound, position);
  }

  updateArea(){
    
  }
}
