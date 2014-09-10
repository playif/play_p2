part of p2;

/**
 * Defines a physics material.
 * @class Material
 * @constructor
 * @param {number} id Material identifier
 * @author schteppe
 */
class Material {
  num id;
  static num idCounter = 0;
  Material([num id]) {
    if (id != null) {
      this.id = id;
    } else {
      this.id = idCounter++;
    }
  }
}
