part of p2;

typedef vec2 Vec2Operation(vec2 out, a, b);

class vec2 {
  double x = 0.0;
  double y = 0.0;


  vec2(double x, double y) {
    this.x = x;
    this.y = y;
  }

//  num operator [](int v) {
//    if (v == 0) {
//      return x;
//    } else {
//      return y;
//    }
//  }
//
//  operator []=(int v, num n) {
//    if (v == 0) {
//      x = n;
//    } else {
//      y = n;
//    }
//  }

  /// Make a cross product and only return the z component
  static num crossLength(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
  }

  /// Cross product between a vector and the Z component of a vector

  static vec2 crossVZ(vec2 out, vec2 vec, num zcomp) {
    vec2.rotate(out, vec, -PI / 2); // Rotate according to the right hand rule
    vec2.scale(out, out, zcomp); // Scale with z
    return out;
  }

  /// Cross product between a vector and the Z component of a vector

  static vec2 crossZV(vec2 out, num zcomp, vec2 vec) {
    vec2.rotate(out, vec, PI / 2); // Rotate according to the right hand rule
    vec2.scale(out, out, zcomp); // Scale with z
    return out;
  }

  /// Rotate a vector by an angle

  static rotate(vec2 out, vec2 a, num angle) {
    if (angle != 0) {
      num c = cos(angle),
          s = sin(angle),
          x = a.x,
          y = a.y;
      out.x = c * x - s * y;
      out.y = s * x + c * y;
    } else {
      out.x = a.x;
      out.y = a.y;
    }
  }

  /// Rotate a vector 90 degrees clockwise

  static rotate90cw(vec2 out, vec2 a) {
    num x = a.x,
        y = a.y;
    out.x = y;
    out.y = -x;
  }

  /// Transform a point position to local frame.

  static toLocalFrame(vec2 out, vec2 worldPoint, vec2 framePosition, num frameAngle) {
    vec2.copy(out, worldPoint);
    vec2.sub(out, out, framePosition);
    vec2.rotate(out, out, -frameAngle);
  }

  /// Transform a point position to global frame.

  static toGlobalFrame(vec2 out, vec2 localPoint, vec2 framePosition, num frameAngle) {
    vec2.copy(out, localPoint);
    vec2.rotate(out, out, frameAngle);
    vec2.add(out, out, framePosition);
  }

  /// Compute centroid of a triangle spanned by vectors a,b,c.

  static vec2 centroid(vec2 out, vec2 a, vec2 b, vec2 c) {
    vec2.add(out, a, b);
    vec2.add(out, out, c);
    vec2.scale(out, out, 1 / 3);
    return out;
  }

  /// Creates a new, empty vec2

  static vec2 create() {
    vec2 out = new vec2(0.0,0.0);
    return out;
  }

  /// Creates a new vec2 initialized with values from an existing vector

  static vec2 clone(vec2 a) {
    vec2 out = new vec2(0.0,0.0);
    out.x = a.x;
    out.y = a.y;
    return out;
  }

  /// Creates a new vec2 initialized with the given values

  static vec2 fromValues(num x, num y) {
    vec2 out = new vec2(x.toDouble(), y.toDouble());
    return out;
  }

  /// Copy the values from one vec2 to another

  static vec2 copy(vec2 out, vec2 a) {
    out.x = a.x;
    out.y = a.y;
    return out;
  }

  /// Set the components of a vec2 to the given values

  static vec2 set(vec2 out, num x, num y) {
    out.x = x;
    out.y = y;
    return out;
  }

  /// Adds two vec2's

  static vec2 add(vec2 out, vec2 a, vec2 b) {
    out.x = a.x + b.x;
    out.y = a.y + b.y;
    return out;
  }

  static vec2 add2(vec2 out, vec2 a, vec2 b) {
    
    out.x = a.x + b.x;
    out.y = a.y + b.y;
    //print("hi");
    return out;
  }

  /// Subtracts two vec2's

  static vec2 subtract(vec2 out, vec2 a, vec2 b) {
    out.x = a.x - b.x;
    out.y = a.y - b.y;
    return out;
  }

  /// Alias for vec2.subtract
  static Vec2Operation sub = subtract;

  /// Multiplies two vec2's

  static vec2 multiply(vec2 out, vec2 a, vec2 b) {
    out.x = a.x * b.x;
    out.y = a.y * b.y;
    return out;
  }

  /// Alias for vec2.multiply
  static Vec2Operation mul = multiply;


  /// Divides two vec2's

  static vec2 divide(vec2 out, vec2 a, vec2 b) {
    out.x = a.x / b.x;
    out.y = a.y / b.y;
    return out;
  }

  /// Alias for vec2.divide
  static Vec2Operation div = divide;

  /// Scales a vec2 by a scalar number

  static vec2 scale(vec2 out, vec2 a, num b) {
    out.x = a.x * b;
    out.y = a.y * b;
    return out;
  }
  static vec2 scale2(vec2 out, vec2 a, num b) {
    out.x = a.x * b;
    out.y = a.y * b;
    return out;
  }

  /// Calculates the euclidian distance between two vec2's

  static num distance(vec2 a, vec2 b) {
    num x = b.x - a.x,
        y = b.y - a.y;
    return sqrt(x * x + y * y);
  }

  /// Alias for vec2.distance
  static Function dist = distance;

  /// Calculates the squared euclidian distance between two vec2's

  static num squaredDistance(vec2 a, vec2 b) {
    num x = b.x - a.x,
        y = b.y - a.y;
    return x * x + y * y;
  }

  /// Alias for vec2.squaredDistance
  static Function sqrDist = squaredDistance;

  /// Calculates the length of a vec2

  static num length(vec2 a) {
    num x = a.x,
        y = a.y;
    return sqrt(x * x + y * y);
  }

  /// Alias for vec2.length
  static Function len = length;

  /// Calculates the squared length of a vec2

  static num squaredLength(vec2 a) {
    num x = a.x,
        y = a.y;
    return x * x + y * y;
  }

  /// Alias for vec2.squaredLength
  static Function sqrLen = squaredLength;

  /// Negates the components of a vec2

  static vec2 negate(vec2 out, vec2 a) {
    out.x = -a.x;
    out.y = -a.y;
    return out;
  }

  /// Normalize a vec2

  static vec2 normalize(vec2 out, vec2 a) {
    num x = a.x,
        y = a.y;
    num len = x * x + y * y;
    if (len > 0) {
      //TODO: evaluate use of glm_invsqrt here?
      len = 1 / sqrt(len);
      out.x = a.x * len;
      out.y = a.y * len;
    }
    return out;
  }

  /// Calculates the dot product of two vec2's

  static num dot(vec2 a, vec2 b) {
    return a.x * b.x + a.y * b.y;
  }

  /// Returns a string representation of a vector

  static String str(vec2 a) {
    return 'vec2(${a.x}, ${a.y})';
  }


}
