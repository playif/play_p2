part of p2;

class FrictionEquation extends Equation {
  /// Relative vector from center of body A to the contact point, world oriented.
  final vec2 contactPointA= vec2.create();

  /// Relative vector from center of body B to the contact point, world oriented.
  final vec2 contactPointB= vec2.create();

  /// Tangent vector that the friction force will act along. World oriented.
  final vec2 t= vec2.create();

  /// A ContactEquation connected to this friction. The contact equations can be used to rescale the max force for the friction. If more than one contact equation is given, then the max force can be set to the average.
  List<ContactEquation> contactEquations;

  /// The shape in body i that triggered this friction.
  Shape shapeA;

  /// The shape in body j that triggered this friction.
  Shape shapeB;

  /// The friction coefficient to use.
  num frictionCoefficient = 0.3;

  FrictionEquation(Body bodyA, Body bodyB, {num slipForce: 0}) : super(bodyA, bodyB, -slipForce, slipForce) {
    this.contactEquations = new List<ContactEquation>();
    this.shapeA = null;
    this.shapeB = null;
    this.frictionCoefficient = 0.3;
  }

  /// Set the slipping condition for the constraint. The friction force cannot be larger than this value.
  setSlipForce(num slipForce) {
    this.maxForce = slipForce;
    this.minForce = -slipForce;
  }

  /// Get the max force for the constraint.
  num getSlipForce() {
    return this.maxForce;
  }


  num computeB(num a, num b, num h) {
    final Body bi = this.bodyA,
        bj = this.bodyB;
    final vec2 ri = this.contactPointA,
        rj = this.contactPointB,
        t = this.t;
    final Float32List G = this.G;

    // G = [-t -rixt t rjxt]
    // And remember, this is a pure velocity constraint, g is always zero!
    G[0] = -t.x;
    G[1] = -t.y;
    G[2] = -vec2.crossLength(ri, t);
    G[3] = t.x;
    G[4] = t.y;
    G[5] = vec2.crossLength(rj, t);

    num GW = this.computeGW(),
        GiMf = this.computeGiMf();

    num B = /* - g * a  */ -GW * b - h * GiMf;

    return B;
  }
}
