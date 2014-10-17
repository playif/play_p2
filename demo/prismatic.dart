import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {


  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    // Create the physics world
    var world = new p2.World(gravity: new p2.vec2(0.0, -10.0));

    app.setWorld(world);

    // Create two rectangle bodies
    var bodyA = new p2.Body(mass: 1, position: new p2.vec2(-1.0, 0.0));
    bodyA.addShape(new p2.Rectangle(1, 1));
    world.addBody(bodyA);
    var bodyB = new p2.Body(mass: 1, position: new p2.vec2(1.0, 0.0));
    bodyB.addShape(new p2.Rectangle(1, 1));
    world.addBody(bodyB);

    // Create PrismaticConstraint, aka "slider".
    // It lets two bodies slide along an axis.
    p2.PrismaticConstraint prismatic = new p2.PrismaticConstraint(bodyA, bodyB, localAnchorA: new p2.vec2(1.0, 0.0), // Anchor point in bodyA, where the axis starts
    localAnchorB: new p2.vec2(-1.0, 0.0), // Anchor point in bodyB, that will slide along the axis
    localAxisA: new p2.vec2(0.0, 1.0), // An axis defined locally in bodyA
    upperLimit: 0.5, // Upper limit along the axis
    lowerLimit: -0.5 // Lower limit along the axis
    );
    world.addConstraint(prismatic);

    // Create ground
    var planeShape = new p2.Plane();
    var plane = new p2.Body(position: new p2.vec2(0.0, -1.0));
    plane.addShape(planeShape);
    world.addBody(plane);
  });

}
