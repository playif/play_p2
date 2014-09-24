part of p2;

class GearConstraint extends Constraint {
  /// The gear ratio.
  num ratio;
  /// The relative angle
  num angle;
  ///

  GearConstraint(Body bodyA, Body bodyB, {num angle, num ratio: 1, num maxTorque, num maxForce: double.MAX_FINITE, bool collideConnected: true, bool wakeUpBodies: true}) : super(bodyA, bodyB, Constraint.GEAR, collideConnected: collideConnected, wakeUpBodies: wakeUpBodies) {

    this.ratio = ratio;

    /**
         * The relative angle
         * @property angle
         * @type {Number}
         */
    this.angle = angle != null ? angle : bodyB.angle - this.ratio * bodyA.angle;


    this.equations = [new AngleLockEquation(bodyA, bodyB, angle: angle, ratio: ratio)];

    // Set max torque
    if (maxTorque is num) {
      this.setMaxTorque(maxTorque);
    }
  }

  update() {
    AngleLockEquation eq = this.equations[0];
    if (eq.ratio != this.ratio) {
      eq.setRatio(this.ratio);
    }
    eq.angle = this.angle;
  }

  /**
   * Set the max torque for the constraint.
   * @method setMaxTorque
   * @param {Number} torque
   */
  setMaxTorque(torque) {
    (this.equations[0] as AngleLockEquation).setMaxTorque(torque);
  }

  /**
   * Get the max torque for the constraint.
   * @method getMaxTorque
   * @return {Number}
   */
  num getMaxTorque(num torque) {
    return this.equations[0].maxForce;
  }
}
