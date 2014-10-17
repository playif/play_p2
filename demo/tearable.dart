import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {


  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    // Create a World
    var world = new p2.World(gravity: new p2.vec2(0.0, -15.0));

    app.setWorld(world);

    world.solver.iterations = 30;
    world.solver.tolerance = 0.001;

    // Create circle rope
    var N = 10, // Number of circles
        r = 0.1; // Radius of circle
    var shape = new p2.Circle(r),
        lastBody,
        constraints = [];
    for (var i = N - 1; i >= 0; i--) {
      double x = 0.0,
          y = (N - i - N / 2) * r * 2.1;
      p2.Body p = new p2.Body(mass: i == 0 ? 0 : 1, // top body has mass=0 and is static
      position: new p2.vec2(x, y), angularDamping: 0.5);
      p.addShape(shape);
      if (lastBody != null) {
        // Create a DistanceConstraint, it will constrain the
        // current and the last body to have a fixed distance from each other
        var dist = (p.position.y - lastBody.position[1]).abs(),
            c = new p2.DistanceConstraint(p, lastBody, distance: dist);
        world.addConstraint(c);
        constraints.add(c);
      } else {
        // Set horizontal velocity of the last body
        p.velocity.x = 1.0;
      }
      lastBody = p;
      world.addBody(p);
    }

    // Create ground
    var planeShape = new p2.Plane();
    var plane = new p2.Body(position: new p2.vec2(0.0, (-N / 2) * r * 2.1));
    plane.addShape(planeShape);
    world.addBody(plane);

    // After each physics step, we check the constraint force
    // applied. If it is too large, we remove the constraint.
    world.on("postStep", (evt) {
      for (var i = 0; i < constraints.length; i++) {
        var c = constraints[i],
            eqs = c.equations;
        // Equation.multiplier can be seen as the magnitude of the force
        if ((eqs[0].multiplier).abs() > 1500) {
          // Constraint force is too large... Remove the constraint.
          world.removeConstraint(c);
          constraints.removeAt(constraints.indexOf(c));
        }
      }
    });
  });

}
