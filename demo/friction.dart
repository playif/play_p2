
import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main() {


        // Create demo application
        new WebGLRenderer((WebGLRenderer app){

            // Create a world
          p2.World world = new p2.World(
                gravity : new p2.vec2(0.0,-10.0)
            );

            app.setWorld(world);

            // Create a circle
            p2.Circle shape = new p2.Circle(0.5);
            shape.material = new p2.Material();
            p2.Body p = new p2.Body(
                mass: 1,
                position: new p2.vec2(0.0, 1.5)
            );
            p.addShape(shape);
            world.addBody(p);

            // Create a slippery circle
            p2.Circle slipperyShape = new p2.Circle(0.5);
            slipperyShape.material = new p2.Material();
            p = new p2.Body(
                mass: 1,
                position: new p2.vec2(-1.5, 1.5)
            );
            p.addShape(slipperyShape);
            world.addBody(p);

            // Create ground
            p2.Plane planeShape = new p2.Plane();
            planeShape.material = new p2.Material();
            p2.Body plane = new p2.Body(
                angle:Math.PI/16
            );
            plane.addShape(planeShape);
            world.addBody(plane);

            // When the materials of the plane and the first circle meet, they should yield
            // a contact friction of 0.3. We tell p2 this by creating a ContactMaterial.
            p2.ContactMaterial frictionContactMaterial = new p2.ContactMaterial(planeShape.material, shape.material, 
                friction : 0.3
            );
            world.addContactMaterial(frictionContactMaterial);

            // When the plane and the slippery circle meet, the friction should be 0 (slippery). Add a new ContactMaterial.
            p2.ContactMaterial slipperyContactMaterial = new p2.ContactMaterial(planeShape.material, slipperyShape.material, 
                friction : 0.0
            );
            world.addContactMaterial(slipperyContactMaterial);
        });

}