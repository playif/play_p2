import "package:p2/p2.dart" as p2;
import "renderer.dart";

main() {
  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    // Create a World
    p2.World world = new p2.World(gravity: [0, -10] // Set gravity to -10 in y direction
    );

    app.setWorld(world);

    // Set high friction so the wheels don't slip
    world.defaultContactMaterial.friction = 100;

    // Create ground shape (plane)
    p2.Plane planeShape = new p2.Plane();

    // Create a body for the ground
    p2.Body planeBody = new p2.Body(mass: 0 // Mass == 0 makes the body static
    );
    planeBody.addShape(planeShape); // Add the shape to the body
    world.addBody(planeBody); // Add the body to the World

    // Add circle bump in the center
    p2.Circle circleShape = new p2.Circle(2); // Circle shape of radius 2
    p2.Body circleBody = new p2.Body(position: [0, -1] // Set initial position
    );
    circleBody.addShape(circleShape);
    world.addBody(circleBody);

    // Create chassis for our car
    p2.Body chassisBody = new p2.Body(mass: 1, // Setting mass > 0 makes it dynamic
    position: [-4, 1] // Initial position
    );
    p2.Rectangle chassisShape = new p2.Rectangle(1, 0.5); // Chassis shape is a rectangle
    chassisBody.addShape(chassisShape);
    world.addBody(chassisBody);

    // Create wheels
    p2.Body wheelBody1 = new p2.Body(mass: 1, position: [chassisBody.position[0] - 0.5, 0.7]);
    p2.Body wheelBody2 = new p2.Body(mass: 1, position: [chassisBody.position[0] + 0.5, 0.7]);
    p2.Circle wheelShape1 = new p2.Circle(0.2);
    p2.Circle wheelShape2 = new p2.Circle(0.2);
    wheelBody1.addShape(wheelShape1);
    wheelBody2.addShape(wheelShape2);
    world.addBody(wheelBody1);
    world.addBody(wheelBody2);

    // Constrain wheels to chassis with revolute constraints.
    // Revolutes lets the connected bodies rotate around a shared point.
    p2.RevoluteConstraint revoluteBack = new p2.RevoluteConstraint(chassisBody, wheelBody1, localPivotA: [-0.5, -0.3], // Where to hinge first wheel on the chassis
    localPivotB: [0, 0], collideConnected: false);
    p2.RevoluteConstraint revoluteFront = new p2.RevoluteConstraint(chassisBody, wheelBody2, localPivotA: [0.5, -0.3], // Where to hinge second wheel on the chassis
    localPivotB: [0, 0], // Where the hinge is in the wheel (center)
    collideConnected: false);
    world.addConstraint(revoluteBack);
    world.addConstraint(revoluteFront);

    // Enable the constraint motor for the back wheel
    revoluteBack.enableMotor();
    revoluteBack.setMotorSpeed(10); // Rotational speed in radians per second

    app.frame(0, 0, 8, 6);
  });
}
