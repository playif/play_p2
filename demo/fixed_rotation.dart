import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    var world = new p2.World(gravity: [0, -10]);

    app.setWorld(world);

    world.solver.tolerance = 0.01;

    p2.Body boxBody = new p2.Body(mass: 1, position: [-1, 0], fixedRotation: true);
    boxBody.addShape(new p2.Rectangle(1, 1));
    world.addBody(boxBody);

    // Create ground
    var planeShape = new p2.Plane();
    var plane = new p2.Body(position: [0, -1]);
    plane.addShape(planeShape);
    world.addBody(plane);
  });


}
