part of p2;

/// A spring, connecting two bodies. The Spring explicitly adds force and angularForce to the bodies and does therefore not put load on the constraint solver.
abstract class Spring {
  /// Stiffness of the spring.
  num stiffness;

  /// Damping of the spring.
  num damping;

  /// First connected body.
  Body bodyA;

  /// Second connected body.
  Body bodyB;

  Spring(Body bodyA, Body bodyB, {num stiffness:100, num damping:1}) {
    this.stiffness = stiffness;

    this.damping = damping;

    this.bodyA = bodyA;

    this.bodyB = bodyB;
  }

  /// Apply the spring force to the connected bodies.

  applyForce();

}
