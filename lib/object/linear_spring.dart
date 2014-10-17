part of p2;

class LinearSpring extends Spring {
  /// Anchor for bodyA in local bodyA coordinates.
  final vec2 localAnchorA=vec2.create();

  /// Anchor for bodyB in local bodyB coordinates.
  final vec2 localAnchorB=vec2.create();

  /// Rest length of the spring.
  num restLength;

  LinearSpring(Body bodyA, Body bodyB, {num restLength, num stiffness: 100, num damping: 1, vec2 worldAnchorA, vec2 worldAnchorB, vec2 localAnchorA, vec2 localAnchorB}) : super(bodyA, bodyB, stiffness: stiffness, damping: damping) {

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
      vec2 worldAnchorA = vec2.create();
      vec2 worldAnchorB = vec2.create();
      this.getWorldAnchorA(worldAnchorA);
      this.getWorldAnchorB(worldAnchorB);
      num worldDistance = vec2.distance(worldAnchorA, worldAnchorB);
    } else {
      this.restLength = restLength;
    }
  }


  /// Set the anchor point on body A, using world coordinates.

  setWorldAnchorA(vec2 worldAnchorA) {
    this.bodyA.toLocalFrame(this.localAnchorA, worldAnchorA);
  }

  /// Set the anchor point on body B, using world coordinates.

  setWorldAnchorB(vec2 worldAnchorB) {
    this.bodyB.toLocalFrame(this.localAnchorB, worldAnchorB);
  }

  /// Get the anchor point on body A, in world coordinates.

  getWorldAnchorA(vec2 result) {
    this.bodyA.toWorldFrame(result, this.localAnchorA);
  }

  /// Get the anchor point on body B, in world coordinates.

  getWorldAnchorB(vec2 result) {
    this.bodyB.toWorldFrame(result, this.localAnchorB);
  }

  static final vec2 applyForce_r = vec2.create(),
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
    num k = this.stiffness,
        d = this.damping,
        l = this.restLength;
    Body bodyA = this.bodyA,
        bodyB = this.bodyB;
    vec2 r = applyForce_r,
        r_unit = applyForce_r_unit,
        u = applyForce_u,
        f = applyForce_f,
        tmp = applyForce_tmp;

    vec2 worldAnchorA = applyForce_worldAnchorA,
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
    num rlen = vec2.len(r);
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
    num ri_x_f = vec2.crossLength(ri, f);
    num rj_x_f = vec2.crossLength(rj, f);
    bodyA.angularForce -= ri_x_f;
    bodyB.angularForce += rj_x_f;
  }

}
