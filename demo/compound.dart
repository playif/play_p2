import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main() {

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    num N = 2,
    M = 2,
    d = 1.2,
    r = 0.3;

    p2.Particle childShape1 = new p2.Particle();
    p2.Circle childShape2 = new p2.Circle(r);

    p2.World world = new p2.World(
        gravity : new p2.vec2(0.0, -10.0)
    );

    app.setWorld(world);

    // Create circle bodies
    p2.Body body1 = new p2.Body(
        mass: 1,
        position: new p2.vec2(-M * r * d, N * r * d * 2),
        angularVelocity : 1
    );
    p2.Body body2 = new p2.Body(
        mass: 1,
        position: new p2.vec2(M * r * d, N * r * d * 2),
        angularVelocity : 1
    );
    for (int i = 0; i < N; i++) {
      for (int j = 0; j < M; j++) {
        num x = (i - N / 2 + 1 / 2) * 2 * r * d;
        num y = (j - M / 2 + 1 / 2) * 2 * r * d;
        body1.addShape(childShape1, new p2.vec2(x, y), 0);
        body2.addShape(childShape2, new p2.vec2(x, y), 0);
      }
    }
    world.addBody(body1);
    world.addBody(body2);

    // Create boxes
    p2.Rectangle boxShape = new p2.Rectangle(1, 1);
    p2.Body box = new p2.Body(
        position:new p2.vec2(3.0, 2.0),
        mass : 1,
        angularVelocity : -0.2
    );
    box.addShape(boxShape, new p2.vec2(0.0, 0.5));
    box.addShape(boxShape, new p2.vec2(0.0, -0.5));
    world.addBody(box);

    // Create circle
    p2.Circle circleShape = new p2.Circle(0.5);
    p2.Body circle = new p2.Body(
        position:new p2.vec2(3.0, 4.0),
        mass : 1,
        angularVelocity:1
    );
    circle.addShape(circleShape);
    world.addBody(circle);

    // Create convex
    List verts = [];
    for (var i = 0, N = 5; i < N; i++) {
      num a = 2 * Math.PI / N * i;
      verts.add(new p2.vec2(0.5 * Math.cos(a), 0.5 * Math.sin(a)));
    }
    p2.Shape convexShape = new p2.Convex(verts);
    p2.Body convex = new p2.Body(
        position:new p2.vec2(-4.0, 2.0),
        mass : 1,
        angularVelocity : -0.1
    );
    convex.addShape(convexShape, new p2.vec2(0.0, 0.5));
    convex.addShape(convexShape, new p2.vec2(0.0, -0.5), Math.PI / 4);
    world.addBody(convex);

    // Create ground
    p2.Plane planeShape = new p2.Plane();
    p2.Body plane = new p2.Body(
        position:new p2.vec2(0.0, -1.0)
    );
    plane.addShape(planeShape);
    world.addBody(plane);

    app.frame(0, 0, 6, 6);
  });
}