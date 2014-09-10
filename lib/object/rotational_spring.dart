part of p2;

class RotationalSpring extends Spring {

  /// Rest angle of the spring.
  num restAngle;

  RotationalSpring(Body bodyA, Body bodyB, {num restAngle, num stiffness:100, num damping:1 })
  :super (bodyA, bodyB, stiffness:stiffness, damping:damping) {
    this.restAngle = restAngle != null ? restAngle : bodyB.angle - bodyA.angle;
  }

  /// Apply the spring force to the connected bodies.

  applyForce() {
    var k = this.stiffness,
    d = this.damping,
    l = this.restAngle,
    bodyA = this.bodyA,
    bodyB = this.bodyB,
    x = bodyB.angle - bodyA.angle,
    u = bodyB.angularVelocity - bodyA.angularVelocity;

    var torque = -k * (x - l) - d * u * 0;

    bodyA.angularForce -= torque;
    bodyB.angularForce += torque;
  }
}
