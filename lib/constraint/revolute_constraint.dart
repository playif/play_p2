part of p2;

final vec2 worldPivotA = vec2.create(),
    worldPivotB = vec2.create(),
    xAxis = vec2.fromValues(1, 0),
    yAxis = vec2.fromValues(0, 1),
    g = vec2.create();

class RevoluteConstraint extends Constraint {
  final vec2 pivotA= vec2.create();
  final vec2 pivotB= vec2.create();

  Equation motorEquation;

  /// Indicates whether the motor is enabled. Use .enableMotor() to enable the constraint motor.
  bool motorEnabled;

  /// The constraint position.
  num angle;

  /// Set to true to enable lower limit
  bool lowerLimitEnabled;

  /// Set to true to enable upper limit
  bool upperLimitEnabled;

  /// The lower limit on the constraint angle.
  num lowerLimit;

  /// The upper limit on the constraint angle.
  num upperLimit;

  Equation upperLimitEquation;
  Equation lowerLimitEquation;

  RevoluteConstraint(Body bodyA, Body bodyB, {vec2 worldPivot,vec2 localPivotA,vec2 localPivotB, num maxForce: double.MAX_FINITE, bool collideConnected: true, bool wakeUpBodies: true}) : super(bodyA, bodyB, Constraint.REVOLUTE, collideConnected: collideConnected, wakeUpBodies: wakeUpBodies) {
    
    if (worldPivot != null) {
      // Compute pivotA and pivotB
      vec2.sub(this.pivotA, worldPivot, bodyA.position);
      vec2.sub(this.pivotB, worldPivot, bodyB.position);
      // Rotate to local coordinate system
      vec2.rotate(this.pivotA, this.pivotA, -bodyA.angle);
      vec2.rotate(this.pivotB, this.pivotB, -bodyB.angle);
    } else {
      // Get pivotA and pivotB
      vec2.copy(this.pivotA, localPivotA);
      vec2.copy(this.pivotB, localPivotB);
    }

    // Equations to be fed to the solver
    List<Equation> eqs = this.equations = [new Equation(bodyA, bodyB, -maxForce, maxForce), new Equation(bodyA, bodyB, -maxForce, maxForce)];

    Equation x = eqs[0];
    Equation y = eqs[1];

    x.replacedGq = () {
      vec2.rotate(worldPivotA, this.pivotA, bodyA.angle);
      vec2.rotate(worldPivotB, this.pivotB, bodyB.angle);
      vec2.add(g, bodyB.position, worldPivotB);
      vec2.sub(g, g, bodyA.position);
      vec2.sub(g, g, worldPivotA);
      return vec2.dot(g, xAxis);
    };

    y.replacedGq = () {
      vec2.rotate(worldPivotA, this.pivotA, bodyA.angle);
      vec2.rotate(worldPivotB, this.pivotB, bodyB.angle);
      vec2.add(g, bodyB.position, worldPivotB);
      vec2.sub(g, g, bodyA.position);
      vec2.sub(g, g, worldPivotA);
      return vec2.dot(g, yAxis);
    };

    y.minForce = x.minForce = -maxForce;
    y.maxForce = x.maxForce = maxForce;

    this.motorEquation = new RotationalVelocityEquation(bodyA, bodyB);

    this.motorEnabled = false;

    this.angle = 0;
    this.lowerLimitEnabled = false;
    this.upperLimitEnabled = false;

    this.lowerLimit = 0;
    this.upperLimit = 0;

    this.upperLimitEquation = new RotationalLockEquation(bodyA, bodyB);
    this.lowerLimitEquation = new RotationalLockEquation(bodyA, bodyB);
    this.upperLimitEquation.minForce = 0;
    this.lowerLimitEquation.maxForce = 0;
  }

  /**
   * Set the constraint angle limits.
   * @method setLimits
   * @param {number} lower Lower angle limit.
   * @param {number} upper Upper angle limit.
   */
  setLimits([num lower, num upper]) {
    if (lower is num) {
      this.lowerLimit = lower;
      this.lowerLimitEnabled = true;
    } else {
      this.lowerLimit = lower;
      this.lowerLimitEnabled = false;
    }

    if (upper is num) {
      this.upperLimit = upper;
      this.upperLimitEnabled = true;
    } else {
      this.upperLimit = upper;
      this.upperLimitEnabled = false;
    }
  }

  update() {
    Body bodyA = this.bodyA,
        bodyB = this.bodyB;
    vec2 pivotA = this.pivotA,
        pivotB = this.pivotB;
    List<Equation> eqs = this.equations;
    Equation normal = eqs[0],
        tangent = eqs[1],
        x = eqs[0],
        y = eqs[1];
    num upperLimit = this.upperLimit,
        lowerLimit = this.lowerLimit;
    RotationalLockEquation upperLimitEquation = this.upperLimitEquation,
        lowerLimitEquation = this.lowerLimitEquation;

    num relAngle = this.angle = bodyB.angle - bodyA.angle;

    if (this.upperLimitEnabled && relAngle > upperLimit) {
      upperLimitEquation.angle = upperLimit;
      if (eqs.indexOf(upperLimitEquation) == -1) {
        eqs.add(upperLimitEquation);
      }
    } else {
      int idx = eqs.indexOf(upperLimitEquation);
      if (idx != -1) {
        eqs.removeAt(idx);
      }
    }

    if (this.lowerLimitEnabled && relAngle < lowerLimit) {
      lowerLimitEquation.angle = lowerLimit;
      if (eqs.indexOf(lowerLimitEquation) == -1) {
        eqs.add(lowerLimitEquation);
      }
    } else {
      int idx = eqs.indexOf(lowerLimitEquation);
      if (idx != -1) {
        eqs.removeAt(idx);
      }
    }

    /*

      The constraint violation is

          g = xj + rj - xi - ri

      ...where xi and xj are the body positions and ri and rj world-oriented offset vectors. Differentiate:

          gdot = vj + wj x rj - vi - wi x ri

      We split this into x and y directions. (let x and y be unit vectors along the respective axes)

          gdot * x = ( vj + wj x rj - vi - wi x ri ) * x
                   = ( vj*x + (wj x rj)*x -vi*x -(wi x ri)*x
                   = ( vj*x + (rj x x)*wj -vi*x -(ri x x)*wi
                   = [ -x   -(ri x x)   x   (rj x x)] * [vi wi vj wj]
                   = G*W

      ...and similar for y. We have then identified the jacobian entries for x and y directions:

          Gx = [ x   (rj x x)   -x   -(ri x x)]
          Gy = [ y   (rj x y)   -y   -(ri x y)]

       */

    vec2.rotate(worldPivotA, pivotA, bodyA.angle);
    vec2.rotate(worldPivotB, pivotB, bodyB.angle);

    // todo: these are a bit sparse. We could save some computations on making custom eq.computeGW functions, etc

    x.G[0] = -1.0;
    x.G[1] = 0.0;
    x.G[2] = -vec2.crossLength(worldPivotA, xAxis);
    x.G[3] = 1.0;
    x.G[4] = 0.0;
    x.G[5] = vec2.crossLength(worldPivotB, xAxis);

    y.G[0] = 0.0;
    y.G[1] = -1.0;
    y.G[2] = -vec2.crossLength(worldPivotA, yAxis);
    y.G[3] = 0.0;
    y.G[4] = 1.0;
    y.G[5] = vec2.crossLength(worldPivotB, yAxis);
  }

  /**
   * Enable the rotational motor
   * @method enableMotor
   */
  enableMotor() {
    if (this.motorEnabled) {
      return;
    }
    this.equations.add(this.motorEquation);
    this.motorEnabled = true;
  }

  /**
   * Disable the rotational motor
   * @method disableMotor
   */
  disableMotor() {
    if (!this.motorEnabled) {
      return;
    }
    int i = this.equations.indexOf(this.motorEquation);
    this.equations.removeAt(i);
    this.motorEnabled = false;
  }

  /**
   * Check if the motor is enabled.
   * @method motorIsEnabled
   * @deprecated use property motorEnabled instead.
   * @return {Boolean}
   */
  bool motorIsEnabled() {
    return this.motorEnabled;
  }

  /**
   * Set the speed of the rotational constraint motor
   * @method setMotorSpeed
   * @param  {Number} speed
   */
  setMotorSpeed(num speed) {
    if (!this.motorEnabled) {
      return;
    }
    int i = this.equations.indexOf(this.motorEquation);
    this.equations[i].relativeVelocity = speed;
  }

  /**
   * Get the speed of the rotational constraint motor
   * @method getMotorSpeed
   * @return {Number} The current speed, or false if the motor is not enabled.
   */
  num getMotorSpeed() {
    if (!this.motorEnabled) {
      return 0;
    }
    return this.motorEquation.relativeVelocity;
  }
}
