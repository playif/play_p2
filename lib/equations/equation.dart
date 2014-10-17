part of p2;

/**
 * Base class for constraint equations.
 */
class Equation {
  /// Minimum force to apply when solving.
  num minForce;

  /// Max force to apply when solving.
  num maxForce;

  /// First body participating in the constraint
  Body bodyA;

  /// Second body participating in the constraint
  Body bodyB;

  /// The stiffness of this equation. Typically chosen to a large number (~1e7), but can be chosen somewhat freely to get a stable simulation.
  num stiffness;

  /// The number of time steps needed to stabilize the constraint equation. Typically between 3 and 5 time steps.
  num relaxation;

  /// The Jacobian entry of this equation. 6 numbers, 3 per body (x,y,angle).
  final Float32List G = new Float32List(6);

  num offset = 0;

  num a = 0;
  num b = 0;
  num epsilon = 0;
  num timeStep = 1 / 60;

  /// Indicates if stiffness or relaxation was changed.
  bool needsUpdate = true;

  /// The resulting constraint multiplier from the last solve. This is mostly equivalent to the force produced by the constraint.
  num multiplier = 0;

  /// Relative velocity.
  num relativeVelocity = 0;

  /// Whether this equation is enabled or not. If true, it will be added to the solver.
  bool enabled = true;

  Function replacedGq;
  Function replacedGW;
  Function updateJacobian;

  Equation(Body bodyA, Body bodyB, [num minForce = -double.MAX_FINITE, num maxForce = double.MAX_FINITE])
      : this.bodyA = bodyA,
        this.bodyB = bodyB {

    this.minForce = minForce;

    this.maxForce = maxForce;

//    this.bodyA = bodyA;
//
//    this.bodyB = bodyB;

    this.stiffness = Equation.DEFAULT_STIFFNESS;

    this.relaxation = Equation.DEFAULT_RELAXATION;

    for (int i = 0; i < 6; i++) {
      this.G[i] = 0.0;
    }

    this.offset = 0;

    this.a = 0;
    this.b = 0;
    this.epsilon = 0;
    this.timeStep = 1 / 60;

    this.needsUpdate = true;

    this.multiplier = 0;

    this.relativeVelocity = 0;

    this.enabled = true;
  }

  /// The default stiffness when creating a new Equation.
  static const num DEFAULT_STIFFNESS = 1e6;

  /// The default relaxation when creating a new Equation.
  static const num DEFAULT_RELAXATION = 4;

  /// Compute SPOOK parameters .a, .b and .epsilon according to the current parameters.
  update() {
    num k = this.stiffness,
        d = this.relaxation,
        h = this.timeStep;

    this.a = 4.0 / (h * (1 + 4 * d));
    this.b = (4.0 * d) / (1 + 4 * d);
    this.epsilon = 4.0 / (h * h * k * (1 + 4 * d));

    this.needsUpdate = false;
  }

  /// Multiply a jacobian entry with corresponding positions or velocities
  num gmult(Float32List G, vec2 vi, num wi, vec2 vj, num wj) {
    return G[0] * vi.x + G[1] * vi.y + G[2] * wi + G[3] * vj.x + G[4] * vj.y + G[5] * wj;
  }

  /// Computes the RHS of the SPOOK equation
  num computeB(num a, num b, num h) {
    num GW = this.replacedGW == null ? this.computeGW() : this.replacedGW();
    num Gq = this.replacedGq == null ? this.computeGq() : this.replacedGq();
    num GiMf = this.computeGiMf();
    return -Gq * a - GW * b - GiMf * h;
  }

  static final vec2 qi = vec2.create(),
      qj = vec2.create();

  /// Computes G\*q, where q are the generalized body coordinates
  num computeGq() {
    Float32List G = this.G;
    Body bi = this.bodyA,
        bj = this.bodyB;
    vec2 xi = bi.position,
        xj = bj.position;
    num ai = bi.angle,
        aj = bj.angle;

    return this.gmult(G, qi, ai, qj, aj) + this.offset;
  }

  /// Computes G\*W, where W are the body velocities
  num computeGW() {
    Float32List G = this.G;
    Body bi = this.bodyA,
        bj = this.bodyB;
    vec2 vi = bi.velocity,
        vj = bj.velocity;
    num wi = bi.angularVelocity,
        wj = bj.angularVelocity;
    return this.gmult(G, vi, wi, vj, wj) + this.relativeVelocity;
  }

  /// Computes G\*Wlambda, where W are the body velocities
  num computeGWlambda() {
    Body bi = this.bodyA,
        bj = this.bodyB;
    Float32List G = this.G;
    vec2 vi = bi.vlambda,
        vj = bj.vlambda;
    num wi = bi.wlambda,
        wj = bj.wlambda;
    return this.gmult(G, vi, wi, vj, wj);
  }


  static final vec2 iMfi = vec2.create(),
      iMfj = vec2.create();

  /// Computes G\*inv(M)\*f, where M is the mass matrix with diagonal blocks for each body, and f are the forces on the bodies.
  num computeGiMf() {
    Body bi = this.bodyA,
        bj = this.bodyB;
    vec2 fi = bi.force;
    num ti = bi.angularForce;
    vec2 fj = bj.force;
    num tj = bj.angularForce,
        invMassi = bi.invMassSolve,
        invMassj = bj.invMassSolve,
        invIi = bi.invInertiaSolve,
        invIj = bj.invInertiaSolve;
    Float32List G = this.G;

    vec2.scale(iMfi, fi, invMassi);
    vec2.scale(iMfj, fj, invMassj);

    return this.gmult(G, iMfi, ti * invIi, iMfj, tj * invIj);
  }

  /// Computes G\*inv(M)\*G'
  num computeGiMGt() {
    Body bi = this.bodyA,
        bj = this.bodyB;
    num invMassi = bi.invMassSolve,
        invMassj = bj.invMassSolve,
        invIi = bi.invInertiaSolve,
        invIj = bj.invInertiaSolve;
    Float32List G = this.G;

    return G[0] * G[0] * invMassi + G[1] * G[1] * invMassi + G[2] * G[2] * invIi + G[3] * G[3] * invMassj + G[4] * G[4] * invMassj + G[5] * G[5] * invIj;
  }

  static final vec2 addToWlambda_temp = vec2.create(),
      addToWlambda_Gi = vec2.create(),
      addToWlambda_Gj = vec2.create(),
      addToWlambda_ri = vec2.create(),
      addToWlambda_rj = vec2.create(),
      addToWlambda_Mdiag = vec2.create();
  //static int count=0;
  /// Add constraint velocity to the bodies.
  addToWlambda(double deltalambda) {
    Body bi = this.bodyA,
        bj = this.bodyB;
    vec2 temp = addToWlambda_temp,
        Gi = addToWlambda_Gi,
        Gj = addToWlambda_Gj,
        ri = addToWlambda_ri,
        rj = addToWlambda_rj;
    double invMassi = bi.invMassSolve,
        invMassj = bj.invMassSolve,
        invIi = bi.invInertiaSolve,
        invIj = bj.invInertiaSolve;
    vec2 Mdiag = addToWlambda_Mdiag;
    Float32List G = this.G;

    Gi.x = G[0];
    Gi.y = G[1];
    Gj.x = G[3];
    Gj.y = G[4];

    // Add to linear velocity
    // v_lambda += inv(M) * delta_lamba * G
    vec2.scale2(temp, Gi, invMassi * deltalambda);
    vec2.add(bi.vlambda, bi.vlambda, temp);
    // This impulse is in the offset frame
    // Also add contribution to angular
    //bi.wlambda -= vec2.crossLength(temp,ri);
    bi.wlambda += invIi * G[2] * deltalambda;

    vec2.scale2(temp, Gj, invMassj * deltalambda);
    vec2.add(bj.vlambda, bj.vlambda, temp);
    //bj.wlambda -= vec2.crossLength(temp,rj);
    bj.wlambda += invIj * G[5] * deltalambda;

    //print(count++);
  }

  /// Compute the denominator part of the SPOOK equation: C = G\*inv(M)\*G' + eps
  num computeInvC(num eps) {
    return 1.0 / (this.computeGiMGt() + eps);
  }
}
