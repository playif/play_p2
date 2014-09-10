part of p2;

class LinearSpring extends Spring {
  /// Anchor for bodyA in local bodyA coordinates.
  List localAnchorA;

  /// Anchor for bodyB in local bodyB coordinates.
  List localAnchorB;

  /// Rest length of the spring.
  num restLength;

  LinearSpring(Body bodyA, Body bodyB, {
  num restLength,
  num stiffness:100,
  num damping:1,
  List worldAnchorA,
  List worldAnchorB,
  List localAnchorA,
  List localAnchorB
  }) : super(bodyA, bodyB, stiffness:stiffness, damping:damping) {

    this.localAnchorA = vec2.fromValues(0, 0);

    this.localAnchorB = vec2.fromValues(0, 0);

    if (localAnchorA != null) {
      vec2.copy(this.localAnchorA, localAnchorA);
    }
    if (localAnchorB != null) {
      vec2.copy(this.localAnchorB, localAnchorB);
    }
    if (worldAnchorA != null) {
      this.setWorldAnchorA(worldAnchorA);
    }
    if (worldAnchorB != null) {
      this.setWorldAnchorB(worldAnchorB);
    }

    if (restLength == null) {
      var worldAnchorA = vec2.create();
      var worldAnchorB = vec2.create();
      this.getWorldAnchorA(worldAnchorA);
      this.getWorldAnchorB(worldAnchorB);
      var worldDistance = vec2.distance(worldAnchorA, worldAnchorB);
    }
    else {
      this.restLength = restLength;
    }
  }


  /// Set the anchor point on body A, using world coordinates.

  setWorldAnchorA(List worldAnchorA) {
    this.bodyA.toLocalFrame(this.localAnchorA, worldAnchorA);
  }

  /// Set the anchor point on body B, using world coordinates.

  setWorldAnchorB(List worldAnchorB) {
    this.bodyB.toLocalFrame(this.localAnchorB, worldAnchorB);
  }

  /// Get the anchor point on body A, in world coordinates.

  getWorldAnchorA(List result) {
    this.bodyA.toWorldFrame(result, this.localAnchorA);
  }

  /// Get the anchor point on body B, in world coordinates.

  getWorldAnchorB(List result) {
    this.bodyB.toWorldFrame(result, this.localAnchorB);
  }

  List applyForce_r = vec2.create(),
  applyForce_r_unit = vec2.create(),
  applyForce_u = vec2.create(),
  applyForce_f = vec2.create(),
  applyForce_worldAnchorA = vec2.create(),
  applyForce_worldAnchorB = vec2.create(),
  applyForce_ri = vec2.create(),
  applyForce_rj = vec2.create(),
  applyForce_tmp = vec2.create();

  /// Apply the spring force to the connected bodies.

  applyForce() {
    var k = this.stiffness,
    d = this.damping,
    l = this.restLength,
    bodyA = this.bodyA,
    bodyB = this.bodyB,
    r = applyForce_r,
    r_unit = applyForce_r_unit,
    u = applyForce_u,
    f = applyForce_f,
    tmp = applyForce_tmp;

    var worldAnchorA = applyForce_worldAnchorA,
    worldAnchorB = applyForce_worldAnchorB,
    ri = applyForce_ri,
    rj = applyForce_rj;

    // Get world anchors
    this.getWorldAnchorA(worldAnchorA);
    this.getWorldAnchorB(worldAnchorB);

    // Get offset points
    vec2.sub(ri, worldAnchorA, bodyA.position);
    vec2.sub(rj, worldAnchorB, bodyB.position);

    // Compute distance vector between world anchor points
    vec2.sub(r, worldAnchorB, worldAnchorA);
    var rlen = vec2.len(r);
    vec2.normalize(r_unit, r);

    //console.log(rlen)
    //console.log("A",vec2.str(worldAnchorA),"B",vec2.str(worldAnchorB))

    // Compute relative velocity of the anchor points, u
    vec2.sub(u, bodyB.velocity, bodyA.velocity);
    vec2.crossZV(tmp, bodyB.angularVelocity, rj);
    vec2.add(u, u, tmp);
    vec2.crossZV(tmp, bodyA.angularVelocity, ri);
    vec2.sub(u, u, tmp);

    // F = - k * ( x - L ) - D * ( u )
    vec2.scale(f, r_unit, -k * (rlen - l) - d * vec2.dot(u, r_unit));

    // Add forces to bodies
    vec2.sub(bodyA.force, bodyA.force, f);
    vec2.add(bodyB.force, bodyB.force, f);

    // Angular force
    var ri_x_f = vec2.crossLength(ri, f);
    var rj_x_f = vec2.crossLength(rj, f);
    bodyA.angularForce -= ri_x_f;
    bodyB.angularForce += rj_x_f;
  }

}
