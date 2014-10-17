part of p2;

class ContactEquation extends Equation {

  /// Vector from body i center of mass to the contact point.
  final vec2 contactPointA = vec2.create();
  final vec2 penetrationVec = vec2.create();

  /// World-oriented vector from body A center of mass to the contact point.
  final vec2 contactPointB = vec2.create();

  /// The normal vector, pointing out of body i
  final vec2 normalA = vec2.create();

  /// The restitution to use (0=no bounciness, 1=max bounciness).
  num restitution;

  /// This property is set to true if this is the first impact between the bodies (not persistant contact).
  bool firstImpact;

  /// The shape in body i that triggered this contact.
  Shape shapeA;

  /// The shape in body j that triggered this contact.
  Shape shapeB;

  ContactEquation(Body bodyA, Body bodyB) : super(bodyA, bodyB, 0, double.MAX_FINITE) {
    this.restitution = 0;
    this.firstImpact = false;
    this.shapeA = null;
    this.shapeB = null;
  }

  num computeB(num a, num b, num h) {
    final Body bi = this.bodyA,
        bj = this.bodyB;
    final vec2 ri = this.contactPointA,
        rj = this.contactPointB,
        xi = bi.position,
        xj = bj.position;

    final vec2 penetrationVec = this.penetrationVec,
        n = this.normalA;
    Float32List G = this.G;

    // Caluclate cross products
    num rixn = vec2.crossLength(ri, n),
        rjxn = vec2.crossLength(rj, n);

    // G = [-n -rixn n rjxn]
    G[0] = -n.x;
    G[1] = -n.y;
    G[2] = -rixn;
    G[3] = n.x;
    G[4] = n.y;
    G[5] = rjxn;

    // Calculate q = xj+rj -(xi+ri) i.e. the penetration vector
    vec2.add(penetrationVec, xj, rj);
    vec2.sub(penetrationVec, penetrationVec, xi);
    vec2.sub(penetrationVec, penetrationVec, ri);

    // Compute iteration
    num GW, Gq;
    if (this.firstImpact && this.restitution != 0) {
      Gq = 0;
      GW = (1 / b) * (1 + this.restitution) * this.computeGW();
    } else {
      Gq = vec2.dot(n, penetrationVec) + this.offset;
      GW = this.computeGW();
    }

    num GiMf = this.computeGiMf();
    num B = -Gq * a - GW * b - h * GiMf;

    return B;
  }
}
