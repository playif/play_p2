import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:async";

main() {


  Timer interval;

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {
    //setup: function(){

    var world = new p2.World(gravity: new p2.vec2(0.0, -10.0));

    app.setWorld(world);

    // Create circle sensor
    var shape = new p2.Circle(0.4);
    shape.sensor = true;
    var body = new p2.Body(mass: 1, position: new p2.vec2(0.0, 3.0));
    body.addShape(shape);

    // Create ground.
    var planeShape = new p2.Plane();
    var plane = new p2.Body(position: new p2.vec2(0.0, -1.0));
    plane.addShape(planeShape);
    world.addBody(plane);

    // The beginContact event is fired whenever two shapes
    // starts overlapping, including sensors.
    world.on("beginContact", (event) {

      // Check if our sensor body is involved in this contact event.
      // This might be false if the user added more bodies via the
      // GUI, that collides.
      if (event['bodyA'] == body || event['bodyB'] == body) {

        // Check if the body is added to the world. This should be
        // true, but better be safe.
        if (body.world != null) {

          // Remove the body from the world.
          world.removeBody(body);
        }
      }
    });

    spawnBody() {
      body.position.x = 0.0;
      body.position.y = 2.0;
      body.velocity.x = 0.0;
      body.velocity.y = 0.0;
      world.addBody(body);
    }

    spawnBody();
    
    interval = new Timer.periodic(const Duration(seconds: 1), (t) {
      spawnBody();
    });

    //interval = setInterval(spawnBody,2000);
    //},

    //teardown: function(){
    //    clearInterval(interval);
    //}
  });


}
