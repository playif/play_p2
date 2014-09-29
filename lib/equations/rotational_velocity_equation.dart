part of p2;

class RotationalVelocityEquation extends Equation {
  num ratio;
  RotationalVelocityEquation(Body bodyA, Body bodyB, {num minForce: -double.MAX_FINITE, num maxForce: double.MAX_FINITE}) : super(bodyA, bodyB, minForce, maxForce) {
    this.relativeVelocity = 1.0;
    this.ratio = 1.0;
  }

  num computeB(num a, num b, num h) {
    List G = this.G;
    G[2] = -1.0;
    G[5] = this.ratio;

    num GiMf = this.computeGiMf();
    num GW = this.computeGW();
    num B = -GW * b - h * GiMf;

    return B;
  }
}
