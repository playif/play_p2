part of p2;

class PrismaticConstraint extends Constraint {
  List localAnchorA;
  List localAnchorB;
  List localAxisA;

  num maxForce;

  num lowerLimit;
  bool lowerLimitEnabled;

  num upperLimit;
  bool upperLimitEnabled;

  num position;
  num velocity;

  ContactEquation upperLimitEquation;
  ContactEquation lowerLimitEquation;

  Equation motorEquation;
  bool motorEnabled;
  num motorSpeed;


  PrismaticConstraint(Body bodyA, Body bodyB, {List localAnchorA: const [0, 0], List localAnchorB: const [0, 0], List localAxisA: const [1, 0], bool disableRotationalLock: false, num upperLimit, num lowerLimit, num maxForce: double.MAX_FINITE, bool collideConnected: true, bool wakeUpBodies: true}) : super(bodyA, bodyB, Constraint.PRISMATIC, collideConnected: collideConnected, wakeUpBodies: wakeUpBodies) {

    this.localAnchorA = vec2.create();
    vec2.copy(this.localAnchorA, localAnchorA);

    this.localAnchorB = vec2.create();
    vec2.copy(this.localAnchorB, localAnchorB);

    this.localAxisA = vec2.create();
    vec2.copy(this.localAxisA, localAxisA);

    /*

 The constraint violation for the common axis point is

     g = ( xj + rj - xi - ri ) * t   :=  gg*t

 where r are body-local anchor points, and t is a tangent to the constraint axis defined in body i frame.

     gdot =  ( vj + wj x rj - vi - wi x ri ) * t + ( xj + rj - xi - ri ) * ( wi x t )

 Note the use of the chain rule. Now we identify the jacobian

     G*W = [ -t      -ri x t + t x gg     t    rj x t ] * [vi wi vj wj]

 The rotational part is just a rotation lock.

  */

    this.maxForce = maxForce;

    // Translational part
    Equation trans = new Equation(bodyA, bodyB, -maxForce, maxForce);
    List ri = vec2.create(),
        rj = vec2.create(),
        gg = vec2.create(),
        t = vec2.create();
    trans.replacedGq = () {
      // g = ( xj + rj - xi - ri ) * t
      return vec2.dot(gg, t);
    };
    trans.updateJacobian = () {
      List G = trans.G;
      List xi = bodyA.position;
      List xj = bodyB.position;
      vec2.rotate(ri, localAnchorA, bodyA.angle);
      vec2.rotate(rj, localAnchorB, bodyB.angle);
      vec2.add(gg, xj, rj);
      vec2.sub(gg, gg, xi);
      vec2.sub(gg, gg, ri);
      vec2.rotate(t, localAxisA, bodyA.angle + PI / 2);

      G[0] = -t[0];
      G[1] = -t[1];
      G[2] = -vec2.crossLength(ri, t) + vec2.crossLength(t, gg);
      G[3] = t[0];
      G[4] = t[1];
      G[5] = vec2.crossLength(rj, t);
    };
    this.equations.add(trans);

    // Rotational part
    if (!disableRotationalLock) {
      RotationalLockEquation rot = new RotationalLockEquation(bodyA, bodyB, minForce:-maxForce, maxForce:maxForce);
      this.equations.add(rot);
    }

    /**
  * The position of anchor A relative to anchor B, along the constraint axis.
  * @property position
  * @type {Number}
  */
    this.position = 0;

    // Is this one used at all?
    this.velocity = 0;

    /**
  * Set to true to enable lower limit.
  * @property lowerLimitEnabled
  * @type {Boolean}
  */
    this.lowerLimitEnabled = lowerLimit != null ? true : false;

    /**
  * Set to true to enable upper limit.
  * @property upperLimitEnabled
  * @type {Boolean}
  */
    this.upperLimitEnabled = upperLimit != null ? true : false;

    /**
  * Lower constraint limit. The constraint position is forced to be larger than this value.
  * @property lowerLimit
  * @type {Number}
  */
    this.lowerLimit = lowerLimit != null ? lowerLimit : 0;

    /**
  * Upper constraint limit. The constraint position is forced to be smaller than this value.
  * @property upperLimit
  * @type {Number}
  */
    this.upperLimit = upperLimit != null ? upperLimit : 1;

    // Equations used for limits
    this.upperLimitEquation = new ContactEquation(bodyA, bodyB);
    this.lowerLimitEquation = new ContactEquation(bodyA, bodyB);

    // Set max/min forces
    this.upperLimitEquation.minForce = this.lowerLimitEquation.minForce = 0;
    this.upperLimitEquation.maxForce = this.lowerLimitEquation.maxForce = maxForce;

    /**
  * Equation used for the motor.
  * @property motorEquation
  * @type {Equation}
  */
    this.motorEquation = new Equation(bodyA, bodyB);

    /**
  * The current motor state. Enable or disable the motor using .enableMotor
  * @property motorEnabled
  * @type {Boolean}
  */
    this.motorEnabled = false;

    /**
  * Set the target speed for the motor.
  * @property motorSpeed
  * @type {Number}
  */
    this.motorSpeed = 0;

    //var that = this;
    //var motorEquation = this.motorEquation;
    //var old = motorEquation.computeGW;
    motorEquation.replacedGq = () {
      return 0;
    };
    motorEquation.replacedGW = () {
      var G = motorEquation.G,
          bi = motorEquation.bodyA,
          bj = motorEquation.bodyB,
          vi = bi.velocity,
          vj = bj.velocity,
          wi = bi.angularVelocity,
          wj = bj.angularVelocity;
      return motorEquation.gmult(G, vi, wi, vj, wj) + this.motorSpeed;
    };


  }



  List worldAxisA = vec2.create(),
      worldAnchorA = vec2.create(),
      worldAnchorB = vec2.create(),
      orientedAnchorA = vec2.create(),
      orientedAnchorB = vec2.create(),
      tmp = vec2.create();

  /**
   * Update the constraint equations. Should be done if any of the bodies changed position, before solving.
   * @method update
   */
  update() {
    List<Equation> eqs = this.equations;
    Equation trans = eqs[0];
//        upperLimit = this.upperLimit,
//        lowerLimit = this.lowerLimit,
//        upperLimitEquation = this.upperLimitEquation,
//        lowerLimitEquation = this.lowerLimitEquation,
//        bodyA = this.bodyA,
//        bodyB = this.bodyB,
//        localAxisA = this.localAxisA,
//        localAnchorA = this.localAnchorA,
//        localAnchorB = this.localAnchorB;

    trans.updateJacobian();

    // Transform local things to world
    vec2.rotate(worldAxisA, localAxisA, bodyA.angle);
    vec2.rotate(orientedAnchorA, localAnchorA, bodyA.angle);
    vec2.add(worldAnchorA, orientedAnchorA, bodyA.position);
    vec2.rotate(orientedAnchorB, localAnchorB, bodyB.angle);
    vec2.add(worldAnchorB, orientedAnchorB, bodyB.position);

    num relPosition = this.position = vec2.dot(worldAnchorB, worldAxisA) - vec2.dot(worldAnchorA, worldAxisA);

    // Motor
    if (this.motorEnabled) {
      // G = [ a     a x ri   -a   -a x rj ]
      List G = this.motorEquation.G;
      G[0] = worldAxisA[0];
      G[1] = worldAxisA[1];
      G[2] = vec2.crossLength(worldAxisA, orientedAnchorB);
      G[3] = -worldAxisA[0];
      G[4] = -worldAxisA[1];
      G[5] = -vec2.crossLength(worldAxisA, orientedAnchorA);
    }

    /*
          Limits strategy:
          Add contact equation, with normal along the constraint axis.
          min/maxForce is set so the constraint is repulsive in the correct direction.
          Some offset is added to either equation.contactPointA or .contactPointB to get the correct upper/lower limit.

                   ^
                   |
        upperLimit x
                   |    ------
           anchorB x<---|  B |
                   |    |    |
          ------   |    ------
          |    |   |
          |  A |-->x anchorA
          ------   |
                   x lowerLimit
                   |
                  axis
       */


    if (this.upperLimitEnabled && relPosition > upperLimit) {
      // Update contact constraint normal, etc
      vec2.scale(upperLimitEquation.normalA, worldAxisA, -1);
      vec2.sub(upperLimitEquation.contactPointA, worldAnchorA, bodyA.position);
      vec2.sub(upperLimitEquation.contactPointB, worldAnchorB, bodyB.position);
      vec2.scale(tmp, worldAxisA, upperLimit);
      vec2.add(upperLimitEquation.contactPointA, upperLimitEquation.contactPointA, tmp);
      if (eqs.indexOf(upperLimitEquation) == -1) {
        eqs.add(upperLimitEquation);
      }
    } else {
      var idx = eqs.indexOf(upperLimitEquation);
      if (idx != -1) {
        eqs.removeAt(idx);
      }
    }

    if (this.lowerLimitEnabled && relPosition < lowerLimit) {
      // Update contact constraint normal, etc
      vec2.scale(lowerLimitEquation.normalA, worldAxisA, 1);
      vec2.sub(lowerLimitEquation.contactPointA, worldAnchorA, bodyA.position);
      vec2.sub(lowerLimitEquation.contactPointB, worldAnchorB, bodyB.position);
      vec2.scale(tmp, worldAxisA, lowerLimit);
      vec2.sub(lowerLimitEquation.contactPointB, lowerLimitEquation.contactPointB, tmp);
      if (eqs.indexOf(lowerLimitEquation) == -1) {
        eqs.add(lowerLimitEquation);
      }
    } else {
      var idx = eqs.indexOf(lowerLimitEquation);
      if (idx != -1) {
        eqs.removeAt(idx);
      }
    }
  }

  /**
   * Enable the motor
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
    var i = this.equations.indexOf(this.motorEquation);
    this.equations.removeAt(i);
    this.motorEnabled = false;
  }

  /**
   * Set the constraint limits.
   * @method setLimits
   * @param {number} lower Lower limit.
   * @param {number} upper Upper limit.
   */
  setLimits(num lower, num upper) {
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


}
