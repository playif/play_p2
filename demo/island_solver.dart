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
    var world = new p2.World(gravity: [0, -10], islandSplit: true);

    app.setWorld(world);

    world.solver.tolerance = 0.1;
    world.solver.iterations = N;

    // Create circle ropes
    for (var j = 0; j < M; j++) {
      var shape = new p2.Circle(r);
      var lastBody;
      for (var i = N; i >= 0; i--) {
        var x = (j + 0.5 - M / 2) * r * 8;
        var y = (N / 2 - i) * r * 2.1;
        var p = new p2.Body(mass: i == 0 ? 0 : 1, position: [x, y]);
        p.addShape(shape);
        if (lastBody != null) {
          // Connect the current body to the previous one
          var dist = (p.position[1] - lastBody.position[1]).abs();
          var constraint = new p2.DistanceConstraint(p, lastBody, distance: dist);
          world.addConstraint(constraint);
        } else {
          p.velocity[0] = (1 * i).toDouble();
        }
        lastBody = p;
        world.addBody(p);
      }
      lastBody = null;
    }

    // Print the number of independent islands to console repeatedly.
    // This will output 10 if the ropes don't touch.
    interval = new Timer.periodic(const Duration(seconds: 1), (t) {
      var numIslands = world.islandManager.islands.length;
      window.console.log("Number of islands: " + numIslands.toString());
    });
    // },

    // teardown: function(){
    //     clearInterval(interval);
    // }
  });

}
