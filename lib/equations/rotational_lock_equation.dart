part of p2;

class RotationalLockEquation extends Equation {
  num angle = 0;

  RotationalLockEquation(Body bodyA, Body bodyB, {num angle:0}) :super(bodyA, bodyB) {
    this.angle = angle;
    G[2] = 1.0;
    G[5] = -1.0;
  }

  List worldVectorA = vec2.create(),
  worldVectorB = vec2.create(),
  xAxis = vec2.fromValues(1, 0),
  yAxis = vec2.fromValues(0, 1);

  computeGq() {
    vec2.rotate(worldVectorA, xAxis, this.bodyA.angle + this.angle);
    vec2.rotate(worldVectorB, yAxis, this.bodyB.angle);
    return vec2.dot(worldVectorA, worldVectorB);
  }
}
