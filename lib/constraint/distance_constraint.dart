part of p2;

class DistanceConstraint extends Constraint {
  List localAnchorA;
  List localAnchorB;
  num distance;
  /// Max force to apply.
  num maxForce;
  /// If the upper limit is enabled or not.
  bool upperLimitEnabled;
  /// The upper constraint limit.
  num upperLimit;
  /// If the lower limit is enabled or not.
  bool lowerLimitEnabled;
  /// The lower constraint limit.
  num lowerLimit;
  /// Current constraint position. This is equal to the current distance between the world anchor points.
  num position;


  DistanceConstraint(Body bodyA, Body bodyB, {List localAnchorA:const [0,0], List localAnchorB:const [0,0], num distance, num maxForce: double.MAX_FINITE, bool collideConnected: true, bool wakeUpBodies: true}) : super(bodyA, bodyB, Constraint.REVOLUTE, collideConnected: collideConnected, wakeUpBodies: wakeUpBodies) {
//    if (localAnchorA == null) {
//      localAnchorA = vec2.fromValues(0.0, 0.0);
//    }
//    if (localAnchorB == null) {
//      localAnchorB = vec2.fromValues(0.0, 0.0);
//    }

    this.localAnchorA=vec2.fromValues(localAnchorA[0],localAnchorA[1]);
    this.localAnchorB=vec2.fromValues(localAnchorB[0],localAnchorB[1]);
    this.distance = distance;

    if (this.distance == null) {
// Use the current world distance between the world anchor points.
      var worldAnchorA = vec2.create(),
          worldAnchorB = vec2.create(),
          r = vec2.create();

      // Transform local anchors to world
      vec2.rotate(worldAnchorA, localAnchorA, bodyA.angle);
      vec2.rotate(worldAnchorB, localAnchorB, bodyB.angle);

      vec2.add(r, bodyB.position, worldAnchorB);
      vec2.sub(r, r, worldAnchorA);
      vec2.sub(r, r, bodyA.position);

      this.distance = vec2.length(r);
    }




    Equation normal = new Equation(bodyA, bodyB, -maxForce, maxForce); // Just in the normal direction
    this.equations = [normal];

    this.maxForce = maxForce;

    // g = (xi - xj).dot(n)
    // dg/dt = (vi - vj).dot(n) = G*W = [n 0 -n 0] * [vi wi vj wj]'

    // ...and if we were to include offset points (TODO for now):
    // g =
    //      (xj + rj - xi - ri).dot(n) - distance
    //
    // dg/dt =
    //      (vj + wj x rj - vi - wi x ri).dot(n) =
    //      { term 2 is near zero } =
    //      [-n   -ri x n   n   rj x n] * [vi wi vj wj]' =
    //      G * W
    //
    // => G = [-n -rixn n rjxn]

    var r = vec2.create();
    var ri = vec2.create(); // worldAnchorA
    var rj = vec2.create(); // worldAnchorB
    //var that = this;
    normal.replacedGq = () {
      var bodyA = this.bodyA,
          bodyB = this.bodyB,
          xi = bodyA.position,
          xj = bodyB.position;

      // Transform local anchors to world
      vec2.rotate(ri, localAnchorA, bodyA.angle);
      vec2.rotate(rj, localAnchorB, bodyB.angle);

      vec2.add(r, xj, rj);
      vec2.sub(r, r, ri);
      vec2.sub(r, r, xi);

      //vec2.sub(r, bodyB.position, bodyA.position);
      return vec2.length(r) - this.distance;
    };

    // Make the contact constraint bilateral
    this.setMaxForce(maxForce);

    this.upperLimitEnabled = false;

    this.upperLimit = 1;

    this.lowerLimitEnabled = false;

    this.lowerLimit = 0;

    this.position = 0;

  }

  /**
   * Update the constraint equations. Should be done if any of the bodies changed position, before solving.
   * @method update
   */
  var n = vec2.create();
  var ri = vec2.create(); // worldAnchorA
  var rj = vec2.create(); // worldAnchorB
  update() {
    var normal = this.equations[0],
        bodyA = this.bodyA,
        bodyB = this.bodyB,
        distance = this.distance,
        xi = bodyA.position,
        xj = bodyB.position,
        normalEquation = this.equations[0],
        G = normal.G;

    // Transform local anchors to world
    vec2.rotate(ri, this.localAnchorA, bodyA.angle);
    vec2.rotate(rj, this.localAnchorB, bodyB.angle);

    // Get world anchor points and normal
    vec2.add(n, xj, rj);
    vec2.sub(n, n, ri);
    vec2.sub(n, n, xi);
    this.position = vec2.length(n);

    var violating = false;
    if (this.upperLimitEnabled) {
      if (this.position > this.upperLimit) {
        normalEquation.maxForce = 0;
        normalEquation.minForce = -this.maxForce;
        this.distance = this.upperLimit;
        violating = true;
      }
    }

    if (this.lowerLimitEnabled) {
      if (this.position < this.lowerLimit) {
        normalEquation.maxForce = this.maxForce;
        normalEquation.minForce = 0;
        this.distance = this.lowerLimit;
        violating = true;
      }
    }

    if ((this.lowerLimitEnabled || this.upperLimitEnabled) && !violating) {
      // No constraint needed.
      normalEquation.enabled = false;
      return;
    }

    normalEquation.enabled = true;

    vec2.normalize(n, n);

    // Caluclate cross products
    var rixn = vec2.crossLength(ri, n),
        rjxn = vec2.crossLength(rj, n);

    // G = [-n -rixn n rjxn]
    G[0] = -n[0];
    G[1] = -n[1];
    G[2] = -rixn;
    G[3] = n[0];
    G[4] = n[1];
    G[5] = rjxn;
  }

  /**
   * Set the max force to be used
   * @method setMaxForce
   * @param {Number} f
   */
  setMaxForce(f) {
    var normal = this.equations[0];
    normal.minForce = -f;
    normal.maxForce = f;
  }

  /**
   * Get the max force
   * @method getMaxForce
   * @return {Number}
   */
  num getMaxForce(num f) {
    var normal = this.equations[0];
    return normal.maxForce;
  }
}
