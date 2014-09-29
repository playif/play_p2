
import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {

        var radius = 0.15,
            N = 20;

        // Create demo application
        new WebGLRenderer((WebGLRenderer app){

            var world = new p2.World(
                gravity : [0,-10]
            );

            app.setWorld(world);

            for(var i=0; i<N; i++){
                var circleBody = new p2.Body(
                    mass: 1,
                    position: [0,i*2*radius]
                );
                circleBody.allowSleep = true;
                circleBody.sleepSpeedLimit = 1; // Body will feel sleepy if speed<1 (speed is the norm of velocity)
                circleBody.sleepTimeLimit =  1; // Body falls asleep after 1s of sleepiness
                circleBody.addShape(new p2.Circle(radius));
                circleBody.damping = 0.2;
                world.addBody(circleBody);
            }

            // Create ground
            var planeShape = new p2.Plane();
            var plane = new p2.Body(
                position:[0,-1]
            );
            plane.addShape(planeShape);
            world.addBody(plane);

            // Allow sleeping
            world.sleepMode = p2.World.BODY_SLEEPING;
        });


}