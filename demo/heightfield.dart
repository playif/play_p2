import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main() {

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    var world = new p2.World(gravity: [0, -10]);

    app.setWorld(world);

    world.solver.tolerance = 0.01;

    // Set large friction - needed for powerful vehicle engine!
    world.defaultContactMaterial.friction = 10;

    // Create ground
    var data = [];
    var numDataPoints = 10000;
    for (var i = 0; i < numDataPoints; i++) {
      data.add(0.5 * Math.cos(0.2 * i) * Math.sin(0.5 * i) + 0.6 * Math.sin(0.1 * i) * Math.sin(0.05 * i));
    }
    var heightfieldShape = new p2.Heightfield(data, elementWidth: 1);
    var heightfield = new p2.Body(position: [-10, -1]);
    heightfield.addShape(heightfieldShape);
    world.addBody(heightfield);


    // Create chassis
    var chassisBody = new p2.Body(mass: 1, position: [-4, 1]),
        chassisShape = new p2.Rectangle(1, 0.5);
    chassisBody.addShape(chassisShape);
    world.addBody(chassisBody);

    // Create wheels
    var wheelBody1 = new p2.Body(mass: 1, position: [chassisBody.position[0] - 0.5, 0.7]),
        wheelBody2 = new p2.Body(mass: 1, position: [chassisBody.position[0] + 0.5, 0.7]),
        wheelShape = new p2.Circle(0.3);
    wheelBody1.addShape(wheelShape);
    wheelBody2.addShape(wheelShape);
    world.addBody(wheelBody1);
    world.addBody(wheelBody2);

    // Disable collisions between chassis and wheels
    var WHEELS = 1, // Define bits for each shape type
        CHASSIS = 2,
        GROUND = 4,
        OTHER = 8;

    wheelShape.collisionGroup = WHEELS; // Assign groups
    chassisShape.collisionGroup = CHASSIS;
    heightfieldShape.collisionGroup = GROUND;

    wheelShape.collisionMask = GROUND | OTHER; // Wheels can only collide with ground
    chassisShape.collisionMask = GROUND | OTHER; // Chassis can only collide with ground
    heightfieldShape.collisionMask = WHEELS | CHASSIS | OTHER; // Ground can collide with wheels and chassis

    // Constrain wheels to chassis
    p2.PrismaticConstraint c1 = new p2.PrismaticConstraint(chassisBody, wheelBody1, localAnchorA: [-0.5, -0.3], localAnchorB: [0, 0], localAxisA: [0, 1], disableRotationalLock: true);
    p2.PrismaticConstraint c2 = new p2.PrismaticConstraint(chassisBody, wheelBody2, localAnchorA: [0.5, -0.3], localAnchorB: [0, 0], localAxisA: [0, 1], disableRotationalLock: true);
    c1.setLimits(-0.4, 0.2);
    c2.setLimits(-0.4, 0.2);
    world.addConstraint(c1);
    world.addConstraint(c2);

    // Add springs for the suspension
    var stiffness = 100,
        damping = 5,
        restLength = 0.5;
    // Left spring
    world.addSpring(new p2.LinearSpring(chassisBody, wheelBody1, restLength: restLength, stiffness: stiffness, damping: damping, localAnchorA: [-0.5, 0], localAnchorB: [0, 0]));
    // Right spring
    world.addSpring(new p2.LinearSpring(chassisBody, wheelBody2, restLength: restLength, stiffness: stiffness, damping: damping, localAnchorA: [0.5, 0], localAnchorB: [0, 0]));

    app.newShapeCollisionGroup = OTHER;
    app.newShapeCollisionMask = GROUND | WHEELS | CHASSIS | OTHER;

    // Apply current engine torque after each step
    var torque = 0;
    world.on("postStep", (evt) {
      wheelBody1.angularForce += torque;
      wheelBody2.angularForce += torque;
      app.centerCamera(chassisBody.position[0], chassisBody.position[1]);
    });

    // Change the current engine torque with the left/right keys
    app.on("keydown", (evt) {
      num t = 5;
      switch (evt['keyCode']) {
        case 39: // right
          torque = -t;
          break;
        case 37: // left
          torque = t;
          break;
      }
    });
    app.on("keyup", (evt) {
      torque = 0;
    });

    world.on("addBody", (evt) {
      evt['body'].setDensity(1);
    });
  });


}
