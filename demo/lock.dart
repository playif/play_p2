
import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {


        // Create demo application
  new WebGLRenderer((WebGLRenderer app){

            // Create physics world
            var world = new p2.World(
                gravity : new p2.vec2(0.0,-10.0)
            );

            app.setWorld(world);

            world.solver.iterations = 100;
            world.solver.tolerance = 0.001;

            // Create two circles
            var circleShape = new p2.Circle(0.5);
            var bodyA = new p2.Body(
                mass: 1,
                position: new p2.vec2(-1.0, 1.0)
            );
            bodyA.addShape(circleShape);
            world.addBody(bodyA);
            var bodyB = new p2.Body(
                mass: 1,
                position: new p2.vec2(1.0, 1.0)
            );
            bodyB.addShape(circleShape);
            world.addBody(bodyB);

            // Create constraint.
            // This will lock bodyB to bodyA
            var constraint = new p2.LockConstraint(bodyA, bodyB);
            world.addConstraint(constraint);

            // Create a beam made of locked rectangles
            var boxShape = new p2.Rectangle(0.5,0.5);
            var r = 1,
                lastBody,
                N = 10;
            for(var i=0; i<N; i++){
                var body = new p2.Body(
                    mass:1,
                    position:new p2.vec2(i*boxShape.width*r - N*boxShape.width*r/2,3.0)
                );
                body.addShape(boxShape);
                world.addBody(body);
                if(lastBody != null){
                    // Connect current body to the last one
                    var constraint = new p2.LockConstraint(lastBody, body, 
                        collideConnected : false
                    );
                    world.addConstraint(constraint);
                }
                lastBody = body;
            }

            // Create ground
            var planeShape = new p2.Plane();
            var plane = new p2.Body(
                position : new p2.vec2(0.0,-1.0)
            );
            plane.addShape(planeShape);
            world.addBody(plane);
        });

}