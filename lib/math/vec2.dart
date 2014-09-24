part of p2;

typedef List Vec2Operation(List out, List a, List b);

class vec2 {

  /// Make a cross product and only return the z component
  static num crossLength(List a, List b) {
    return a[0] * b[1] - a[1] * b[0];
  }

  /// Cross product between a vector and the Z component of a vector

  static List crossVZ(List out, List vec, num zcomp) {
    vec2.rotate(out, vec, -PI / 2); // Rotate according to the right hand rule
    vec2.scale(out, out, zcomp); // Scale with z
    return out;
  }

  /// Cross product between a vector and the Z component of a vector

  static List crossZV(List out, num zcomp, List vec) {
    vec2.rotate(out, vec, PI / 2); // Rotate according to the right hand rule
    vec2.scale(out, out, zcomp); // Scale with z
    return out;
  }

  /// Rotate a vector by an angle

  static rotate(List out, List a, num angle) {
    if (angle != 0) {
      var c = cos(angle),
      s = sin(angle),
      x = a[0],
      y = a[1];
      out[0] = c * x - s * y;
      out[1] = s * x + c * y;
    } else {
      out[0] = a[0].toDouble();
      out[1] = a[1].toDouble();
    }
  }

  /// Rotate a vector 90 degrees clockwise

  static rotate90cw(List out, List a) {
    var x = a[0];
    var y = a[1];
    out[0] = y;
    out[1] = -x;
  }

  /// Transform a point position to local frame.

  static toLocalFrame(List out, List worldPoint, List framePosition, num frameAngle) {
    vec2.copy(out, worldPoint);
    vec2.sub(out, out, framePosition);
    vec2.rotate(out, out, -frameAngle);
  }

  /// Transform a point position to global frame.

  static toGlobalFrame(List out, List localPoint, List framePosition, num frameAngle) {
    vec2.copy(out, localPoint);
    vec2.rotate(out, out, frameAngle);
    vec2.add(out, out, framePosition);
  }

  /// Compute centroid of a triangle spanned by vectors a,b,c.

  static centroid(List out, List a, List b, List c) {
    vec2.add(out, a, b);
    vec2.add(out, out, c);
    vec2.scale(out, out, 1 / 3);
    return out;
  }

  /// Creates a new, empty vec2

  static List create() {
    Float32List out = new Float32List(2);
    out[0] = 0.0;
    out[1] = 0.0;
    return out;
  }

  /// Creates a new vec2 initialized with values from an existing vector

  static List clone(List a) {
    Float32List out = new Float32List(2);
    out[0] = a[0];
    out[1] = a[1];
    return out;
  }

  /// Creates a new vec2 initialized with the given values

  static List fromValues(num x, num y) {
    Float32List out = new Float32List(2);
    out[0] = x.toDouble();
    out[1] = y.toDouble();
    return out;
  }

  /// Copy the values from one vec2 to another

  static List copy(List out, List a) {
    out[0] = a[0].toDouble();
    out[1] = a[1].toDouble();
    return out;
  }

  /// Set the components of a vec2 to the given values

  static List set(List out, num x, num y) {
    out[0] = x.toDouble();
    out[1] = y.toDouble();
    return out;
  }

  /// Adds two vec2's

  static List add(List out, List a, List b) {
    out[0] = a[0] + b[0];
    out[1] = a[1] + b[1];
    return out;
  }

  /// Subtracts two vec2's

  static List subtract(List out, List a, List b) {
    out[0] = a[0] - b[0];
    out[1] = a[1] - b[1];
    return out;
  }
 
  /// Alias for vec2.subtract
  static Vec2Operation sub = subtract;

  /// Multiplies two vec2's

  static List multiply(List out, List a, List b) {
    out[0] = a[0] * b[0];
    out[1] = a[1] * b[1];
    return out;
  }

  /// Alias for vec2.multiply
  static Vec2Operation mul = multiply;


  /// Divides two vec2's

  static List divide(List out, List a, List b) {
    out[0] = a[0] / b[0];
    out[1] = a[1] / b[1];
    return out;
  }

  /// Alias for vec2.divide
  static Vec2Operation div = divide;

  /// Scales a vec2 by a scalar number

  static List scale(List out, List a, num b) {
    out[0] = a[0] * b;
    out[1] = a[1] * b;
    return out;
  }

  /// Calculates the euclidian distance between two vec2's

  static num distance(List a, List b) {
    num x = b[0] - a[0],
    y = b[1] - a[1];
    return sqrt(x * x + y * y);
  }

  /// Alias for vec2.distance
  static Function dist = distance;

  /// Calculates the squared euclidian distance between two vec2's

  static num squaredDistance(List a, List b) {
    num x = b[0] - a[0],
    y = b[1] - a[1];
    return x * x + y * y;
  }

  /// Alias for vec2.squaredDistance
  static Function sqrDist = squaredDistance;

  /// Calculates the length of a vec2

  static num length(List a) {
    num x = a[0],
    y = a[1];
    return sqrt(x * x + y * y);
  }

  /// Alias for vec2.length
  static Function len = length;

  /// Calculates the squared length of a vec2

  static num squaredLength(List a) {
    num x = a[0],
    y = a[1];
    return x * x + y * y;
  }

  /// Alias for vec2.squaredLength
  static Function sqrLen = squaredLength;

  /// Negates the components of a vec2

  static List negate(List out, List a) {
    out[0] = -a[0];
    out[1] = -a[1];
    return out;
  }

  /// Normalize a vec2

  static List normalize(List out, List a) {
    num x = a[0],
    y = a[1];
    num len = x * x + y * y;
    if (len > 0) {
      //TODO: evaluate use of glm_invsqrt here?
      len = 1 / sqrt(len);
      out[0] = a[0] * len;
      out[1] = a[1] * len;
    }
    return out;
  }

  /// Calculates the dot product of two vec2's

  static num dot(List a, List b) {
    return a[0] * b[0] + a[1] * b[1];
  }

  /// Returns a string representation of a vector

  static String str(List<num> a) {
    return 'vec2(${a[0]}, ${a[1]})';
  }


}
