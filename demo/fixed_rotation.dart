import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    p2.World world = new p2.World(gravity: new p2.vec2(0.0, -10.0));

    app.setWorld(world);

    world.solver.tolerance = 0.01;

    p2.Body boxBody = new p2.Body(mass: 1, position: new p2.vec2(-1.0, 0.0), fixedRotation: true);
    boxBody.addShape(new p2.Rectangle(1, 1));
    world.addBody(boxBody);

    // Create ground
    p2.Plane planeShape = new p2.Plane();
    p2.Body plane = new p2.Body(position: new p2.vec2(0.0, -1.0));
    plane.addShape(planeShape);
    world.addBody(plane);
  });


}
