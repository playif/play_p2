part of p2;

class RotationalVelocityEquation extends Equation {
  num ratio;
  RotationalVelocityEquation(Body bodyA, Body bodyB):super(bodyA, bodyB) {
    this.relativeVelocity = 1;
    this.ratio = 1;
  }

  num computeB (num a, num b, num h){
    var G = this.G;
    G[2] = -1;
    G[5] = this.ratio;

    var GiMf = this.computeGiMf();
    var GW = this.computeGW();
    var B = - GW * b - h*GiMf;

    return B;
  }
}
