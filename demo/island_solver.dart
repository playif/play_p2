import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:async";
import "dart:html";

main() {


  Timer interval;

  num N = 10, // Number of circles in each rope
      M = 10, // Number of ropes
      r = 0.1; // Circle radius



  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    //setup: function(){

    // Create a world with island splitting enabled.
    // The island splitting will cut the scene into independent islands and treat them as separate simulations. This can improve performance.
    p2.World world = new p2.World(gravity: new p2.vec2(0.0, -10.0), islandSplit: true);

    app.setWorld(world);

    world.solver.tolerance = 0.1;
    world.solver.iterations = N;

    // Create circle ropes
    for (int j = 0; j < M; j++) {
      p2.Circle shape = new p2.Circle(r);
      p2.Body lastBody;
      for (int i = N; i >= 0; i--) {
        num x = (j + 0.5 - M / 2) * r * 8;
        num y = (N / 2 - i) * r * 2.1;
        p2.Body p = new p2.Body(mass: i == 0 ? 0 : 1, position: new p2.vec2(x, y));
        p.addShape(shape);
        if (lastBody != null) {
          // Connect the current body to the previous one
          num dist = (p.position.y - lastBody.position.y).abs();
          p2.DistanceConstraint constraint = new p2.DistanceConstraint(p, lastBody, distance: dist);
          world.addConstraint(constraint);
        } else {
          p.velocity.x = (1 * i).toDouble();
        }
        lastBody = p;
        world.addBody(p);
      }
      lastBody = null;
    }

    // Print the number of independent islands to console repeatedly.
    // This will output 10 if the ropes don't touch.
    interval = new Timer.periodic(const Duration(seconds: 1), (t) {
      int numIslands = world.islandManager.islands.length;
      window.console.log("Number of islands: " + numIslands.toString());
    });
    // },

    // teardown: function(){
    //     clearInterval(interval);
    // }
  });

}
