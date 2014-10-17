import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {

  num R = 0.7,
      L = R * 3;

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    p2.World world = new p2.World(gravity: new p2.vec2(0.0, 0.0));

    app.setWorld(world);

    world.solver.iterations = 30;
    world.solver.tolerance = 0.01;

    // Create static dummy body that we can constrain other bodies to
    p2.Body dummyBody = new p2.Body(mass: 0);
    world.addBody(dummyBody);

    // Create circle
    p2.Circle shape = new p2.Circle(R);
    p2.Body circleBody = new p2.Body(mass: 1, position: new p2.vec2(0.0, 0.0));
    circleBody.addShape(shape);
    world.addBody(circleBody);

    // Constrain it to the world
    p2.RevoluteConstraint c = new p2.RevoluteConstraint(circleBody, dummyBody, worldPivot: new p2.vec2(0.0, 0.0), collideConnected: false);
    c.enableMotor();
    c.setMotorSpeed(5);
    world.addConstraint(c);

    // Create arm
    p2.Rectangle armShape = new p2.Rectangle(L, 0.1 * L);
    p2.Body armBody = new p2.Body(mass: 1);
    armBody.addShape(armShape);
    world.addBody(armBody);

    // Constrain arm to circle
    p2.RevoluteConstraint c2 = new p2.RevoluteConstraint(circleBody, armBody, localPivotA: new p2.vec2(R * 0.7, 0.0), localPivotB: new p2.vec2(L / 2, 0.0), collideConnected: false);
    world.addConstraint(c2);

    // Piston
    p2.Rectangle pistonShape = new p2.Rectangle(1, 1);
    p2.Body pistonBody = new p2.Body(mass: 1);
    pistonBody.addShape(pistonShape);
    world.addBody(pistonBody);

    // Connect piston to arm
    p2.RevoluteConstraint c3 = new p2.RevoluteConstraint(pistonBody, armBody, localPivotA: new p2.vec2(0.0, 0.0), localPivotB: new p2.vec2(-L / 2, 0.0), collideConnected: false);
    world.addConstraint(c3);

    // Prismatic constraint to keep the piston along a line
    p2.PrismaticConstraint c4 = new p2.PrismaticConstraint(dummyBody, pistonBody, localAnchorA: new p2.vec2(0.0, 0.0), localAnchorB: new p2.vec2(0.0, 0.0), localAxisA: new p2.vec2(1.0, 0.0), collideConnected: false);
    world.addConstraint(c4);
  });



}
