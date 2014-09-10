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
  List G;

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

  Equation(Body bodyA, Body bodyB, [num minForce=-double.MAX_FINITE, num maxForce=double.MAX_FINITE]) {

    this.minForce = minForce;

    this.maxForce = maxForce;

    this.bodyA = bodyA;

    this.bodyB = bodyB;

    this.stiffness = Equation.DEFAULT_STIFFNESS;

    this.relaxation = Equation.DEFAULT_RELAXATION;

    this.G = new Float32List(6);
    for (var i = 0; i < 6; i++) {
      this.G[i] = 0;
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
  update (){
    var k = this.stiffness,
    d = this.relaxation,
    h = this.timeStep;

    this.a = 4.0 / (h * (1 + 4 * d));
    this.b = (4.0 * d) / (1 + 4 * d);
    this.epsilon = 4.0 / (h * h * k * (1 + 4 * d));

    this.needsUpdate = false;
  }

  /// Multiply a jacobian entry with corresponding positions or velocities
  gmult (G,vi,wi,vj,wj){
    return  G[0] * vi[0] +
            G[1] * vi[1] +
            G[2] * wi +
            G[3] * vj[0] +
            G[4] * vj[1] +
            G[5] * wj;
  }

  /// Computes the RHS of the SPOOK equation
  num computeB (a,b,h){
    var GW = this.computeGW();
    var Gq = this.computeGq();
    var GiMf = this.computeGiMf();
    return - Gq * a - GW * b - GiMf*h;
  }

  List  qi = vec2.create(),
  qj = vec2.create();

  /// Computes G\*q, where q are the generalized body coordinates
  num computeGq(){
    var G = this.G,
    bi = this.bodyA,
    bj = this.bodyB,
    xi = bi.position,
    xj = bj.position,
    ai = bi.angle,
    aj = bj.angle;

    return this.gmult(G, qi, ai, qj, aj) + this.offset;
  }

  /// Computes G\*W, where W are the body velocities
  num computeGW (){
    var G = this.G,
    bi = this.bodyA,
    bj = this.bodyB,
    vi = bi.velocity,
    vj = bj.velocity,
    wi = bi.angularVelocity,
    wj = bj.angularVelocity;
    return this.gmult(G,vi,wi,vj,wj) + this.relativeVelocity;
  }

  /// Computes G\*Wlambda, where W are the body velocities
  num computeGWlambda (){
    var G = this.G,
    bi = this.bodyA,
    bj = this.bodyB,
    vi = bi.vlambda,
    vj = bj.vlambda,
    wi = bi.wlambda,
    wj = bj.wlambda;
    return this.gmult(G,vi,wi,vj,wj);
  }


  List iMfi = vec2.create(),
  iMfj = vec2.create();

  /// Computes G\*inv(M)\*f, where M is the mass matrix with diagonal blocks for each body, and f are the forces on the bodies.
  num computeGiMf(){
    var bi = this.bodyA,
    bj = this.bodyB,
    fi = bi.force,
    ti = bi.angularForce,
    fj = bj.force,
    tj = bj.angularForce,
    invMassi = bi.invMassSolve,
    invMassj = bj.invMassSolve,
    invIi = bi.invInertiaSolve,
    invIj = bj.invInertiaSolve,
    G = this.G;

    vec2.scale(iMfi, fi,invMassi);
    vec2.scale(iMfj, fj,invMassj);

    return this.gmult(G,iMfi,ti*invIi,iMfj,tj*invIj);
  }

  /// Computes G\*inv(M)\*G'
  num computeGiMGt (){
    var bi = this.bodyA,
    bj = this.bodyB,
    invMassi = bi.invMassSolve,
    invMassj = bj.invMassSolve,
    invIi = bi.invInertiaSolve,
    invIj = bj.invInertiaSolve,
    G = this.G;

    return  G[0] * G[0] * invMassi +
            G[1] * G[1] * invMassi +
            G[2] * G[2] *    invIi +
            G[3] * G[3] * invMassj +
            G[4] * G[4] * invMassj +
            G[5] * G[5] *    invIj;
  }

  List addToWlambda_temp = vec2.create(),
  addToWlambda_Gi = vec2.create(),
  addToWlambda_Gj = vec2.create(),
  addToWlambda_ri = vec2.create(),
  addToWlambda_rj = vec2.create(),
  addToWlambda_Mdiag = vec2.create();

  /// Add constraint velocity to the bodies.
  addToWlambda (num deltalambda){
    var bi = this.bodyA,
    bj = this.bodyB,
    temp = addToWlambda_temp,
    Gi = addToWlambda_Gi,
    Gj = addToWlambda_Gj,
    ri = addToWlambda_ri,
    rj = addToWlambda_rj,
    invMassi = bi.invMassSolve,
    invMassj = bj.invMassSolve,
    invIi = bi.invInertiaSolve,
    invIj = bj.invInertiaSolve,
    Mdiag = addToWlambda_Mdiag,
    G = this.G;

    Gi[0] = G[0];
    Gi[1] = G[1];
    Gj[0] = G[3];
    Gj[1] = G[4];

    // Add to linear velocity
    // v_lambda += inv(M) * delta_lamba * G
    vec2.scale(temp, Gi, invMassi*deltalambda);
    vec2.add( bi.vlambda, bi.vlambda, temp);
    // This impulse is in the offset frame
    // Also add contribution to angular
    //bi.wlambda -= vec2.crossLength(temp,ri);
    bi.wlambda += invIi * G[2] * deltalambda;


    vec2.scale(temp, Gj, invMassj*deltalambda);
    vec2.add( bj.vlambda, bj.vlambda, temp);
    //bj.wlambda -= vec2.crossLength(temp,rj);
    bj.wlambda += invIj * G[5] * deltalambda;
  }

  /// Compute the denominator part of the SPOOK equation: C = G\*inv(M)\*G' + eps
  num computeInvC (num eps){
    return 1.0 / (this.computeGiMGt() + eps);
  }
}
