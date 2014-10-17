import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;


main() {
  num N = 10, // Number of circles
      r = 0.1; // circle radius

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    p2.World world = new p2.World(gravity: new p2.vec2(0.0, -15.0));

    app.setWorld(world);

    world.solver.iterations = N;

    // Add a line
    p2.Body lineBody = new p2.Body(mass: 1, position: new p2.vec2(-1.5, -0.5), angle: Math.PI / 2, angularVelocity: 10);
    lineBody.addShape(new p2.Line(1));
    world.addBody(lineBody);

    // Add a "null" body
    p2.Body groundBody = new p2.Body();
    world.addBody(groundBody);

    p2.RevoluteConstraint revolute = new p2.RevoluteConstraint(lineBody, groundBody, worldPivot: new p2.vec2(-1.5, 0.0));
    world.addConstraint(revolute);

    // Create circle rope
    p2.Circle shape = new p2.Circle(r);
    p2.Body lastBody;
    for (int i = N - 1; i >= 0; i--) {
      double x = 0.0;
      double y = (N - i - N / 2) * r * 2.1;
      p2.Body p = new p2.Body(mass: i == 0 ? 0 : 1, position: new p2.vec2(x, y));
      p.addShape(shape);
      if (lastBody != null) {
        p2.DistanceConstraint c = new p2.DistanceConstraint(p, lastBody);
        world.addConstraint(c);
      } else {
        p.velocity.x = 10.0;
      }
      lastBody = p;
      world.addBody(p);
    }

    // Create RevoluteConstraint
    p2.Body bodyA = new p2.Body(mass: 1, position: new p2.vec2(3.0, 0.0), angularVelocity: 30);
    bodyA.addShape(new p2.Circle(1));
    world.addBody(bodyA);
    p2.Body bodyB = new p2.Body(mass: 0, position: new p2.vec2(3.0, 4.0));
    bodyB.addShape(new p2.Circle(1));
    world.addBody(bodyB);
    List<num> pivotA = [0, 2];
    List<num> pivotB = [0, -2];
    p2.RevoluteConstraint cr = new p2.RevoluteConstraint(bodyA, bodyB, worldPivot: new p2.vec2(3.0, 2.0));
    cr.setLimits(-Math.PI / 4, Math.PI / 4);
    world.addConstraint(cr);

    app.frame(0, 0, 8, 8);
  });


}
