import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {


  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    // Create a World
    p2.World world = new p2.World(gravity: new p2.vec2(0.0, -10.0));

    app.setWorld(world);

    p2.Circle circleShape = new p2.Circle(0.5);
    p2.Body ballBody1 = new p2.Body(position: new p2.vec2(-2.0, 1.0), mass: 1);

    // Create a material for the circle shape
    circleShape.material = new p2.Material();
    ballBody1.addShape(circleShape);

    // Remove damping from the ball, so it does not lose energy
    ballBody1.damping = 0.0;
    ballBody1.angularDamping = 0.0;

    // Add ball to world
    world.addBody(ballBody1);

    // Create a platform that the ball can bounce on
    p2.Rectangle platformShape1 = new p2.Rectangle(1, 1);
    p2.Body platformBody1 = new p2.Body(position: new p2.vec2(-2.0, -1.0));
    platformBody1.addShape(platformShape1);
    world.addBody(platformBody1);

    // Create material for the platform
    platformShape1.material = new p2.Material();

    // Create contact material between the two materials.
    // The ContactMaterial defines what happens when the two materials meet.
    // In this case, we use some restitution.
    world.addContactMaterial(new p2.ContactMaterial(platformShape1.material, circleShape.material, restitution: 1.0, stiffness: double.MAX_FINITE // We need infinite stiffness to get exact restitution
    ));


    // Create another ball
    p2.Body ballBody2 = new p2.Body(position: new p2.vec2(0.0, 1.0), mass: 1);
    ballBody2.addShape(circleShape);
    ballBody2.damping = 0.0;
    ballBody2.angularDamping = 0.0;
    world.addBody(ballBody2);

    // Create another platform
    p2.Rectangle platformShape2 = new p2.Rectangle(1, 1);
    p2.Body platformBody2 = new p2.Body(position: new p2.vec2(0.0, -1.0));
    platformBody2.addShape(platformShape2);
    world.addBody(platformBody2);

    platformShape2.material = new p2.Material();

    world.addContactMaterial(new p2.ContactMaterial(platformShape2.material, circleShape.material, restitution: 0.0 // This means no bounce!
    ));


    // New ball
    p2.Body ballBody3 = new p2.Body(position: new p2.vec2(2.0, 1.0), mass: 1);
    ballBody3.addShape(circleShape);
    ballBody3.damping = 0.0;
    ballBody3.angularDamping = 0.0;
    world.addBody(ballBody3);

    p2.Rectangle planeShape3 = new p2.Rectangle(1, 1);
    p2.Body plane3 = new p2.Body(position: new p2.vec2(2.0, -1.0));
    plane3.addShape(planeShape3);
    world.addBody(plane3);

    // Create material for the plane shape
    planeShape3.material = new p2.Material();

    world.addContactMaterial(new p2.ContactMaterial(planeShape3.material, circleShape.material, restitution: 0.0, stiffness: 200, // This makes the contact soft!
    relaxation: 0.1));

  });


}
