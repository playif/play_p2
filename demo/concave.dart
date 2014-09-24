
import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {
  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

             // Create the physics world
             var world = new p2.World(
                 gravity : [0,-10]
             );

             // Register the world in the demo app
             app.setWorld(world);

             // Set stiffness of contact & constraints
             world.setGlobalStiffness(1e4);

             world.solver.iterations = 20;
             world.solver.tolerance = 0.01;
             world.islandSplit = true;

             // Enable dynamic friction. A bit more expensive than without, but gives more accurate friction
             world.solver.frictionIterations = 10;

             // Create ground
             var planeShape = new p2.Plane();
             var plane = new p2.Body(
                 mass: 0, // static
                 position: [0,-2]
             );
             plane.addShape(planeShape);
             world.addBody(plane);

             // Create a concave body
             p2.Body concaveBody = new p2.Body(
                 mass : 1,
                 position:[0,2]
             );

             // Give a concave path to the body.
             // Body.prototype.fromPolygon will automatically add shapes at
             // proper offsets and adjust the center of mass.
             var path = [[-1, 1],
                         [-1, 0],
                         [1, 0],
                         [1, 1],
                         [0.5, 0.5]];
             concaveBody.fromPolygon(path);

             // Add the body to the world
             world.addBody(concaveBody);

             // Automatically set the density of bodies that the user draws on the screen
             world.on("addBody",(evt){
                 evt['body'].setDensity(1);
             });

             // Enable shape drawing
             app.setState(Renderer.DRAWPOLYGON);

             // Set camera position and zoom
             app.frame(0, 1, 6, 8);
         });
  

}