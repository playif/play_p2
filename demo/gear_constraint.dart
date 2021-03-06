import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main(){
        // Create demo application
        new WebGLRenderer((WebGLRenderer app){

          p2.Circle shape = new p2.Circle(1);

          p2.World world = new p2.World(
                gravity : new p2.vec2(0.0,-10.0)
            );

            app.setWorld(world);

            // Create first circle
            p2.Body bodyA = new p2.Body(
                mass: 1,
                position: new p2.vec2(-2.0,0.0),
                angle: Math.PI/2,
                angularVelocity : -5
            );
            bodyA.addShape(shape);
            world.addBody(bodyA);

            // Create second circle
            p2.Body bodyB = new p2.Body(
                mass: 1,
                position: new p2.vec2(2.0,0.0)
            );
            bodyB.addShape(shape);
            world.addBody(bodyB);

            // Create a dummy body that we can hinge them to
            p2.Body dummyBody = new p2.Body();
            world.addBody(dummyBody);

            // Hinge em
            p2.RevoluteConstraint revoluteA = new p2.RevoluteConstraint(dummyBody, bodyA, 
                worldPivot: bodyA.position
            );
            p2.RevoluteConstraint revoluteB = new p2.RevoluteConstraint(dummyBody, bodyB, 
                worldPivot: bodyB.position
            );
            world.addConstraint(revoluteA);
            world.addConstraint(revoluteB);

            // Add gear
            p2.GearConstraint gearConstraint = new p2.GearConstraint(bodyA,bodyB, ratio: 2 );
            world.addConstraint(gearConstraint);
        });
}