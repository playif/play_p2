part of p2;

class FrictionEquation extends Equation {
  /// Relative vector from center of body A to the contact point, world oriented.
  List contactPointA;

  /// Relative vector from center of body B to the contact point, world oriented.
  List contactPointB;

  /// Tangent vector that the friction force will act along. World oriented.
  List t;

  /// A ContactEquation connected to this friction. The contact equations can be used to rescale the max force for the friction. If more than one contact equation is given, then the max force can be set to the average.
  List<ContactEquation> contactEquations;

  /// The shape in body i that triggered this friction.
  Shape shapeA;

  /// The shape in body j that triggered this friction.
  Shape shapeB;

  /// The friction coefficient to use.
  num frictionCoefficient = 0.3;

  FrictionEquation(Body bodyA, Body bodyB, num slipForce) : super(bodyA, bodyB, -slipForce, slipForce) {
    this.contactPointA = vec2.create();
    this.contactPointB = vec2.create();
    this.t = vec2.create();
    this.contactEquations = [];
    this.shapeA = null;
    this.shapeB = null;
    this.frictionCoefficient = 0.3;
  }

  /// Set the slipping condition for the constraint. The friction force cannot be larger than this value.
  setSlipForce (num slipForce){
    this.maxForce = slipForce;
    this.minForce = -slipForce;
  }

  /// Get the max force for the constraint.
  getSlipForce(){
    return this.maxForce;
  }


  num computeB (num a, num b, num h){
    var bi = this.bodyA,
    bj = this.bodyB,
    ri = this.contactPointA,
    rj = this.contactPointB,
    t = this.t,
    G = this.G;

    // G = [-t -rixt t rjxt]
    // And remember, this is a pure velocity constraint, g is always zero!
    G[0] = -t[0];
    G[1] = -t[1];
    G[2] = -vec2.crossLength(ri,t);
    G[3] = t[0];
    G[4] = t[1];
    G[5] = vec2.crossLength(rj,t);

    var GW = this.computeGW(),
    GiMf = this.computeGiMf();

    var B = /* - g * a  */ - GW * b - h*GiMf;

    return B;
  }
}
