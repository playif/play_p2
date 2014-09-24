import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main() {

  num size = 0.23,
  dropHeight = size * 2,
  dist = size * 2;

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    p2.World world = new p2.World(
        gravity : [0, -10]
    );

    app.setWorld(world);

    world.islandSplit = true;
    world.sleepMode = p2.World.ISLAND_SLEEPING;

    world.solver.iterations = 20;
    world.solver.tolerance = 0.01;

    world.setGlobalStiffness(1e4);

    // Create all testable shapes
    p2.Particle particle = new p2.Particle();
    p2.Circle circle = new p2.Circle(size / 2);
    p2.Rectangle rectangle = new p2.Rectangle(size, size);
    p2.Line line = new p2.Line(size);
    p2.Capsule capsule = new p2.Capsule(size * 2, size / 4);
    p2.Shape plane = null;

    // Create a convex shape.
    List vertices = [];
    for (int i = 0, N = 5; i < N; i++) {
      num a = 2 * Math.PI / N * i;
      List vertex = [size * 0.5 * Math.cos(a), size * 0.5 * Math.sin(a)]; // Note: vertices are added counter-clockwise
      vertices.add(vertex);
    }
    p2.Convex convex = new p2.Convex(vertices);

    Map opts = {
        'mass': 1,
        'position': [0, 1],
    };

    num numAdded = 0;

    add([p2.Shape shapeA, p2.Shape shapeB]) {
      if (shapeA!= null) {
        p2.Body bodyA = new p2.Body(mass:opts['mass'],position:opts['position']);
        bodyA.addShape(shapeA);
        world.addBody(bodyA);
      }
      if (shapeB!= null) {
        p2.Body bodyB = new p2.Body(mass:opts['mass'],position:opts['position']);
        bodyB.addShape(shapeB);
        world.addBody(bodyB);
        bodyB.position[1] = dropHeight;
      }
      opts['position'][0] += dist;
      numAdded++;
    }

    add(circle, circle);
    add(circle, plane);
    add(circle, rectangle);
    add(circle, convex);
    add(circle, particle);
    add(circle, line);
    add(plane, rectangle);
    add(plane, convex);
    add(plane, particle);
    add(plane, line);
    add(rectangle, rectangle);
    add(rectangle, convex);
    add(rectangle, particle);
    add(rectangle, line);
    add(convex, convex);
    add(convex, particle);
    add(convex, line);
    add(particle, line);
    add(line, line);
    add(capsule);
    add(circle, capsule);
    add(capsule, particle);

    for (var i = 0; i < world.bodies.length; i++) {
      world.bodies[i].position[0] -= (numAdded - 1) * dist / 2;
    }

    // Create ground
    p2.Plane planeShape = new p2.Plane();
    p2.Body planeBody = new p2.Body(
        position:[0, 0]
    );
    planeBody.addShape(planeShape);
    world.addBody(planeBody);

    app.frame(0, 0, 12, 2);
  });

}