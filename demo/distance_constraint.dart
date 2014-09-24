import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    // Create physics world
    var world = new p2.World(gravity: [0, -10]);

    app.setWorld(world);

    // Create two circles
    var circleShape = new p2.Circle(0.5);
    var bodyA = new p2.Body(mass: 1, position: [-2, 1]);
    bodyA.addShape(circleShape);
    world.addBody(bodyA);
    var bodyB = new p2.Body(mass: 1, position: [-0.5, 1]);
    bodyB.addShape(circleShape);
    world.addBody(bodyB);

    // Create constraint.
    // If target distance is not given as an option, then the current distance between the bodies is used.
    var constraint1 = new p2.DistanceConstraint(bodyA, bodyB);
    world.addConstraint(constraint1);
    constraint1.upperLimitEnabled = true;
    constraint1.lowerLimitEnabled = true;
    constraint1.upperLimit = 2;
    constraint1.lowerLimit = 1.5;

    // Create two boxes that must have distance 0 between their corners
    var boxShape = new p2.Rectangle(0.5, 0.5);
    var boxBodyA = new p2.Body(mass: 1, position: [1.5, 1]);
    boxBodyA.addShape(boxShape);
    world.addBody(boxBodyA);
    var boxBodyB = new p2.Body(mass: 1, position: [2, 1]);
    boxBodyB.addShape(boxShape);
    world.addBody(boxBodyB);

    // Create constraint.
    var constraint2 = new p2.DistanceConstraint(boxBodyA, boxBodyB, localAnchorA: [boxShape.width / 2, boxShape.height / 2], localAnchorB: [-boxShape.width / 2, boxShape.height / 2]);
    world.addConstraint(constraint2);


    // Create ground
    var planeShape = new p2.Plane();
    var plane = new p2.Body(position: [0, -1]);
    plane.addShape(planeShape);
    world.addBody(plane);
  });

}
