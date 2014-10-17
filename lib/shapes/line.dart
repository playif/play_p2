part of p2;


/**
 * Line shape class. The line shape is along the x direction, and stretches from [-length/2, 0] to [length/2,0].
 * @class Line
 * @param {Number} [length=1] The total length of the line
 * @extends Shape
 * @constructor
 */
class Line extends Shape {
  num length;

  Line([this.length=1]) :super(Shape.LINE);

  num computeMomentOfInertia (num mass){
    return mass * pow(this.length,2) / 12;
  }

  updateBoundingRadius (){
    this.boundingRadius = this.length/2;
  }

  List<vec2> points = [vec2.create(),vec2.create()];

  /**
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB (AABB out, [vec2 position, num angle]){
    num l2 = this.length / 2;
    vec2.set(points[0], -l2,  0);
    vec2.set(points[1],  l2,  0);
    out.setFromPoints(points,position,angle,0);
  }
  
  updateArea(){
    
  }
}
