import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;


main() {
  var N = 10, // Number of circles
      r = 0.1; // circle radius

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    var world = new p2.World(gravity: [0, -15]);

    app.setWorld(world);

    world.solver.iterations = N;

    // Add a line
    p2.Body lineBody = new p2.Body(mass: 1, position: [-1.5, -0.5], angle: Math.PI / 2, angularVelocity: 10);
    lineBody.addShape(new p2.Line(1));
    world.addBody(lineBody);

    // Add a "null" body
    var groundBody = new p2.Body();
    world.addBody(groundBody);

    var revolute = new p2.RevoluteConstraint(lineBody, groundBody, worldPivot: [-1.5, 0.0]);
    world.addConstraint(revolute);

    // Create circle rope
    var shape = new p2.Circle(r);
    var lastBody;
    for (var i = N - 1; i >= 0; i--) {
      var x = 0;
      var y = (N - i - N / 2) * r * 2.1;
      var p = new p2.Body(mass: i == 0 ? 0 : 1, position: [x, y]);
      p.addShape(shape);
      if (lastBody != null) {
        var c = new p2.DistanceConstraint(p, lastBody);
        world.addConstraint(c);
      } else {
        p.velocity[0] = 10.0;
      }
      lastBody = p;
      world.addBody(p);
    }

    // Create RevoluteConstraint
    var bodyA = new p2.Body(mass: 1, position: [3.0, 0.0], angularVelocity: 30);
    bodyA.addShape(new p2.Circle(1));
    world.addBody(bodyA);
    var bodyB = new p2.Body(mass: 0, position: [3.0, 4.0]);
    bodyB.addShape(new p2.Circle(1));
    world.addBody(bodyB);
    var pivotA = [0, 2];
    var pivotB = [0, -2];
    var cr = new p2.RevoluteConstraint(bodyA, bodyB, worldPivot: [3.0, 2.0]);
    cr.setLimits(-Math.PI / 4, Math.PI / 4);
    world.addConstraint(cr);

    app.frame(0, 0, 8, 8);
  });


}
