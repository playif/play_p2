import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main() {

  Math.Random random = new Math.Random();

  bool enablePositionNoise = true; // Add some noise in circle positions
  num N = 15, // Number of circles in x direction
  M = 15, // and in y
  r = 0.07, // circle radius
  d = 2.2; // Distance between circle centers

// Create demo application
  new WebGLRenderer((WebGLRenderer app) {

// Create the world
    p2.World world = new p2.World(
        gravity : [0, -5],
        broadphase: new p2.NaiveBroadphase()
    );

    app.setWorld(world);

// Set stiffness of all contacts and constraints
    world.setGlobalStiffness(1e8);

// Max number of solver iterations to do
    world.solver.iterations = 20;

// Solver error tolerance
    world.solver.tolerance = 0.001;

// Enables sleeping of bodies
    world.sleepMode = p2.World.BODY_SLEEPING;

// Create circle bodies
    p2.Shape shape = new p2.Circle(r);
    for (var i = 0; i < N; i++) {
      for (var j = M - 1; j >= 0; j--) {
        var x = (i - N / 2) * r * d + (enablePositionNoise ? random.nextDouble() * r : r);
        var y = (j - M / 2) * r * d;
        var p = new p2.Body(
            mass: 1,
            position: [x, y]
        );
        p.addShape(shape);
        p.allowSleep = true;
        p.sleepSpeedLimit = 1; // Body will feel sleepy if speed<1 (speed is the norm of velocity)
        p.sleepTimeLimit = 1; // Body falls asleep after 1s of sleepiness
        world.addBody(p);
      }
    }

// Compute max/min positions of circles
    var xmin = (-N / 2 * r * d),
    xmax = ( N / 2 * r * d),
    ymin = (-M / 2 * r * d),
    ymax = ( M / 2 * r * d);

// Create bottom plane
    p2.Shape planeShape = new p2.Plane();
    var plane = new p2.Body(
        position : [0, ymin]
    );
    plane.addShape(planeShape);
    world.addBody(plane);

// Left plane
    p2.Body planeLeft = new p2.Body(
        angle: -Math.PI / 2,
        position: [xmin, 0]
    );
    planeLeft.addShape(planeShape);
    world.addBody(planeLeft);

// Right plane
    var planeRight = new p2.Body(
        angle: Math.PI / 2,
        position: [xmax, 0]
    );
    planeRight.addShape(planeShape);
    world.addBody(planeRight);

// Start demo
    app.frame(0, 0, 4, 4);
  });
}