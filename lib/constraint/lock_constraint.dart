part of p2;

class LockConstraint extends Constraint {
  num localAngleB;
  List localOffsetB;


  LockConstraint(Body bodyA, Body bodyB, {num angle, num ratio: 1, List localOffsetB, num localAngleB, num maxForce: double.MAX_FINITE, bool collideConnected: true, bool wakeUpBodies: true}) : super(bodyA, bodyB, Constraint.LOCK, collideConnected: collideConnected, wakeUpBodies: wakeUpBodies) {
    Equation x = new Equation(bodyA, bodyB, -maxForce, maxForce),
        y = new Equation(bodyA, bodyB, -maxForce, maxForce),
        rot = new Equation(bodyA, bodyB, -maxForce, maxForce);

    List l = vec2.create(),
        g = vec2.create();
    x.replacedGq = () {
      vec2.rotate(l, this.localOffsetB, bodyA.angle);
      vec2.sub(g, bodyB.position, bodyA.position);
      vec2.sub(g, g, l);
      return g[0];
    };
    y.replacedGq = () {
      vec2.rotate(l, this.localOffsetB, bodyA.angle);
      vec2.sub(g, bodyB.position, bodyA.position);
      vec2.sub(g, g, l);
      return g[1];
    };
    var r = vec2.create(),
        t = vec2.create();
    rot.replacedGq = () {
      vec2.rotate(r, this.localOffsetB, bodyB.angle - this.localAngleB);
      vec2.scale(r, r, -1);
      vec2.sub(g, bodyA.position, bodyB.position);
      vec2.add(g, g, r);
      vec2.rotate(t, r, -PI / 2);
      vec2.normalize(t, t);
      return vec2.dot(g, t);
    };

    /**
         * The offset of bodyB in bodyA's frame.
         * @property {Array} localOffsetB
         */
    this.localOffsetB = vec2.create();
    if (localOffsetB != null) {
      vec2.copy(this.localOffsetB, localOffsetB);
    } else {
      // Construct from current positions
      vec2.sub(this.localOffsetB, bodyB.position, bodyA.position);
      vec2.rotate(this.localOffsetB, this.localOffsetB, -bodyA.angle);
    }

    /**
         * The offset angle of bodyB in bodyA's frame.
         * @property {Number} localAngleB
         */
    this.localAngleB = 0;
    if (localAngleB is num) {
      this.localAngleB = localAngleB;
    } else {
      // Construct
      this.localAngleB = bodyB.angle - bodyA.angle;
    }

    this.equations.addAll([x, y, rot]);
    this.setMaxForce(maxForce);
  }

  /**
   * Set the maximum force to be applied.
   * @method setMaxForce
   * @param {Number} force
   */
  setMaxForce(force) {
    var eqs = this.equations;
    for (var i = 0; i < this.equations.length; i++) {
      eqs[i].maxForce = force;
      eqs[i].minForce = -force;
    }
  }

  /**
   * Get the max force.
   * @method getMaxForce
   * @return {Number}
   */
  getMaxForce() {
    return this.equations[0].maxForce;
  }

  var l = vec2.create();
  var r = vec2.create();
  var t = vec2.create();
  var xAxis = vec2.fromValues(1, 0);
  var yAxis = vec2.fromValues(0, 1);
  update() {
    var x = this.equations[0],
        y = this.equations[1],
        rot = this.equations[2],
        bodyA = this.bodyA,
        bodyB = this.bodyB;

    vec2.rotate(l, this.localOffsetB, bodyA.angle);
    vec2.rotate(r, this.localOffsetB, bodyB.angle - this.localAngleB);
    vec2.scale(r, r, -1);

    vec2.rotate(t, r, PI / 2);
    vec2.normalize(t, t);

    x.G[0] = -1.0;
    x.G[1] = 0.0;
    x.G[2] = -vec2.crossLength(l, xAxis);
    x.G[3] = 1.0;

    y.G[0] = 0.0;
    y.G[1] = -1.0;
    y.G[2] = -vec2.crossLength(l, yAxis);
    y.G[4] = 1.0;

    rot.G[0] = -t[0];
    rot.G[1] = -t[1];
    rot.G[3] = t[0];
    rot.G[4] = t[1];
    rot.G[5] = vec2.crossLength(r, t);
  }

}
