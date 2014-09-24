part of p2;

class ContactEquation extends Equation {

  /// Vector from body i center of mass to the contact point.
  List contactPointA;
  List penetrationVec;

  /// World-oriented vector from body A center of mass to the contact point.
  List contactPointB;

  /// The normal vector, pointing out of body i
  List normalA;

  /// The restitution to use (0=no bounciness, 1=max bounciness).
  num restitution;

  /// This property is set to true if this is the first impact between the bodies (not persistant contact).
  bool firstImpact;

  /// The shape in body i that triggered this contact.
  Shape shapeA;

  /// The shape in body j that triggered this contact.
  Shape shapeB;

  ContactEquation(Body bodyA, Body bodyB) :super(bodyA, bodyB, 0, double.MAX_FINITE) {
    this.contactPointA = vec2.create();
    this.penetrationVec = vec2.create();
    this.contactPointB = vec2.create();
    this.normalA = vec2.create();
    this.restitution = 0;
    this.firstImpact = false;
    this.shapeA = null;
    this.shapeB = null;
  }

  num computeB(num a, num b, num h) {
    Body bi = this.bodyA,
    bj = this.bodyB;
    List ri = this.contactPointA,
    rj = this.contactPointB,
    xi = bi.position,
    xj = bj.position;

    List penetrationVec = this.penetrationVec,
    n = this.normalA,
    G = this.G;

    // Caluclate cross products
    num rixn = vec2.crossLength(ri, n),
    rjxn = vec2.crossLength(rj, n);

    // G = [-n -rixn n rjxn]
    G[0] = -n[0];
    G[1] = -n[1];
    G[2] = -rixn;
    G[3] = n[0];
    G[4] = n[1];
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
