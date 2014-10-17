import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    // Create physics world
    p2.World world = new p2.World(gravity: new p2.vec2(0.0, -10.0));

    app.setWorld(world);

    // Create two circles
    p2.Circle circleShape = new p2.Circle(0.5);
    p2.Body bodyA = new p2.Body(mass: 1, position: new p2.vec2(-2.0, 1.0));
    bodyA.addShape(circleShape);
    world.addBody(bodyA);
    p2.Body bodyB = new p2.Body(mass: 1, position: new p2.vec2(-0.5, 1.0));
    bodyB.addShape(circleShape);
    world.addBody(bodyB);

    // Create constraint.
    // If target distance is not given as an option, then the current distance between the bodies is used.
    p2.DistanceConstraint constraint1 = new p2.DistanceConstraint(bodyA, bodyB);
    world.addConstraint(constraint1);
    constraint1.upperLimitEnabled = true;
    constraint1.lowerLimitEnabled = true;
    constraint1.upperLimit = 2;
    constraint1.lowerLimit = 1.5;

    // Create two boxes that must have distance 0 between their corners
    p2.Rectangle boxShape = new p2.Rectangle(0.5, 0.5);
    p2.Body boxBodyA = new p2.Body(mass: 1, position: new p2.vec2(1.5, 1.0));
    boxBodyA.addShape(boxShape);
    world.addBody(boxBodyA);
    p2.Body boxBodyB = new p2.Body(mass: 1, position: new p2.vec2(2.0, 1.0));
    boxBodyB.addShape(boxShape);
    world.addBody(boxBodyB);

    // Create constraint.
    p2.DistanceConstraint constraint2 = new p2.DistanceConstraint(boxBodyA, boxBodyB, localAnchorA: new p2.vec2(boxShape.width / 2, boxShape.height / 2), localAnchorB: new p2.vec2(-boxShape.width / 2, boxShape.height / 2));
    world.addConstraint(constraint2);


    // Create ground
    p2.Plane planeShape = new p2.Plane();
    p2.Body plane = new p2.Body(position: new p2.vec2(0.0, -1.0));
    plane.addShape(planeShape);
    world.addBody(plane);
  });

}
