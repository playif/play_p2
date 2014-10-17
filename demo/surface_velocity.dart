
import "package:p2/p2.dart" as p2;
import "renderer.dart";


main() {


        // Create demo application
  new WebGLRenderer((WebGLRenderer app){

            // Create a World
            var world = new p2.World(
                gravity : new p2.vec2(0.0,-10.0)
            );

            app.setWorld(world);

            // Create ground
            p2.Plane planeShape = new p2.Plane();
            p2.Body plane = new p2.Body();
            plane.addShape(planeShape);
            world.addBody(plane);

            // Create moving box
            var boxBody = new p2.Body(
                    mass: 1,
                    position: new p2.vec2(1.0,4.0)
                ),
                boxShape = new p2.Rectangle(0.5,0.5);
            boxShape.material = new p2.Material();
            boxBody.addShape(boxShape);
            world.addBody(boxBody);

            // Create static platform box
            var platformBody1 = new p2.Body(
                    mass: 0, // static
                    position: new p2.vec2(-0.5,1.0)
                ),
                platformShape1 = new p2.Rectangle(3,0.2);
            platformBody1.addShape(platformShape1);
            world.addBody(platformBody1);
            platformShape1.material = new p2.Material();

            // Create static platform box
            var platformBody2 = new p2.Body(
                    mass: 0, // static
                    position: new p2.vec2(0.5, 2.0)
                ),
                platformShape2 = new p2.Rectangle(3,0.2);
            platformBody2.addShape(platformShape2);
            world.addBody(platformBody2);
            platformShape2.material = new p2.Material();

            var contactMaterial1 = new p2.ContactMaterial(boxShape.material,platformShape1.material,
                surfaceVelocity:-0.5
            );
            world.addContactMaterial(contactMaterial1);

            var contactMaterial2 = new p2.ContactMaterial(boxShape.material,platformShape2.material,
                surfaceVelocity:0.5
            );
            world.addContactMaterial(contactMaterial2);

            app.frame(0,1,4,4);
        });

}