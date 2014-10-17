part of p2;

/**
 * Heightfield shape class. Height data is given as an array. These data points are spread out evenly with a distance "elementWidth".
 * @class Heightfield
 * @extends Shape
 * @constructor
 * @param {Array} data An array of Y values that will be used to construct the terrain.
 * @param {object} options
 * @param {Number} [options.minValue] Minimum value of the data points in the data array. Will be computed automatically if not given.
 * @param {Number} [options.maxValue] Maximum value.
 * @param {Number} [options.elementWidth=0.1] World spacing between the data points in X direction.
 * @todo Should be possible to use along all axes, not just y
 *
 * @example
 *     // Generate some height data (y-values).
 *     var data = [];
 *     for(var i = 0; i < 1000; i++){
 *         var y = 0.5 * Math.cos(0.2 * i);
 *         data.push(y);
 *     }
 *
 *     // Create the heightfield shape
 *     var heightfieldShape = new Heightfield(data, {
 *         elementWidth: 1 // Distance between the data points in X direction
 *     });
 *     var heightfieldBody = new Body();
 *     heightfieldBody.addShape(heightfieldShape);
 *     world.addBody(heightfieldBody);
 */
class Heightfield extends Shape {
  /// An array of numbers, or height values, that are spread out along the x axis.
  List<num> data;

  /// Max value of the data
  num maxValue;

  /// Max value of the data
  num minValue;

  /// The width of each element
  num elementWidth;


  Heightfield(List<num> data, {num maxValue, num minValue, num elementWidth}) : super(Shape.HEIGHTFIELD) {
//    options = Utils.defaults(options, {
//        maxValue : null,
//        minValue : null,
//        elementWidth : 0.1
//    });

    if (minValue == null || maxValue == null) {
      maxValue = data[0];
      minValue = data[0];
      for (int i = 0; i != data.length; i++) {
        num v = data[i];
        if (v > maxValue) {
          maxValue = v;
        }
        if (v < minValue) {
          minValue = v;
        }
      }
    }


    this.data = data;

    this.maxValue = maxValue;

    this.minValue = minValue;

    this.elementWidth = elementWidth;

    //Shape.call(this,Shape.HEIGHTFIELD);
  }

  /**
   * @method computeMomentOfInertia
   * @param  {Number} mass
   * @return {Number}
   */
  num computeMomentOfInertia(num mass) {
    return double.MAX_FINITE;
  }

  updateBoundingRadius() {
    this.boundingRadius = double.MAX_FINITE;
  }

  updateArea() {
    List<num> data = this.data;
    num area = 0;
    for (int i = 0; i < data.length - 1; i++) {
      area += (data[i] + data[i + 1]) / 2 * this.elementWidth;
    }
    this.area = area;
  }

  /**
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB(AABB out, [vec2 position, num angle]) {
    // Use the max data rectangle
    out.upperBound.x = this.elementWidth * this.data.length + position.x;
    out.upperBound.y = this.maxValue + position.y;
    out.lowerBound.x = position.x;
    out.lowerBound.y = -double.MAX_FINITE; // Infinity
  }

}
