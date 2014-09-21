part of p2;

class AngleLockEquation extends Equation {
  /// The gear angle.
  num angle;

  /// The gear ratio.
  num ratio;

  AngleLockEquation(Body bodyA, Body bodyB, {num angle:0, num ratio:1}) : super(bodyA,bodyB) {
    this.angle = angle;
    this.ratio = ratio;
    this.setRatio(this.ratio);
  }

  computeGq() {
    return this.ratio * this.bodyA.angle - this.bodyB.angle + this.angle;
  }


  /// Set the gear ratio for this equation

  setRatio(num ratio) {
    G[2] = ratio;
    G[5] = -1;
    this.ratio = ratio;
  }

  /// Set the max force for the equation.

  setMaxTorque(num torque) {
    this.maxForce = torque;
    this.minForce = -torque;
  }
}
