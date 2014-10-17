import "package:p2/p2.dart" as p2;
import "renderer.dart";
import "dart:math" as Math;

main() {


  var shouldersDistance = 0.5,
      upperArmLength = 0.4,
      lowerArmLength = 0.4,
      upperArmSize = 0.2,
      lowerArmSize = 0.2,
      neckLength = 0.1,
      headRadius = 0.25,
      upperBodyLength = 0.6,
      pelvisLength = 0.4,
      upperLegLength = 0.5,
      upperLegSize = 0.2,
      lowerLegSize = 0.2,
      lowerLegLength = 0.5;

  // Create demo application
  new WebGLRenderer((WebGLRenderer app) {

    var //OTHER = Math.pow(2, 1),
        BODYPARTS = Math.pow(2, 2),
        GROUND = Math.pow(2, 3),
        OTHER = Math.pow(2, 4),
        bodyPartShapes = [];

    var headShape = new p2.Circle(headRadius),
        upperArmShape = new p2.Rectangle(upperArmLength, upperArmSize),
        lowerArmShape = new p2.Rectangle(lowerArmLength, lowerArmSize),
        upperBodyShape = new p2.Rectangle(shouldersDistance, upperBodyLength),
        pelvisShape = new p2.Rectangle(shouldersDistance, pelvisLength),
        upperLegShape = new p2.Rectangle(upperLegSize, upperLegLength),
        lowerLegShape = new p2.Rectangle(lowerLegSize, lowerLegLength);

    bodyPartShapes.addAll([headShape, upperArmShape, lowerArmShape, upperBodyShape, pelvisShape, upperLegShape, lowerLegShape]);

    for (var i = 0; i < bodyPartShapes.length; i++) {
      var s = bodyPartShapes[i];
      s.collisionGroup = BODYPARTS;
      s.collisionMask = GROUND | OTHER;
    }

    var world = new p2.World(gravity: new p2.vec2(0.0, -10.0));

    app.setWorld(world);

    world.solver.iterations = 100;
    world.solver.tolerance = 0.002;

    // Lower legs
    var lowerLeftLeg = new p2.Body(mass: 1, position: new p2.vec2(-shouldersDistance / 2, lowerLegLength / 2));
    var lowerRightLeg = new p2.Body(mass: 1, position: new p2.vec2(shouldersDistance / 2, lowerLegLength / 2));
    lowerLeftLeg.addShape(lowerLegShape);
    lowerRightLeg.addShape(lowerLegShape);
    world.addBody(lowerLeftLeg);
    world.addBody(lowerRightLeg);

    // Upper legs
    var upperLeftLeg = new p2.Body(mass: 1, position: new p2.vec2(-shouldersDistance / 2, lowerLeftLeg.position.y + lowerLegLength / 2 + upperLegLength / 2));
    var upperRightLeg = new p2.Body(mass: 1, position: new p2.vec2(shouldersDistance / 2, lowerRightLeg.position.y + lowerLegLength / 2 + upperLegLength / 2));
    upperLeftLeg.addShape(upperLegShape);
    upperRightLeg.addShape(upperLegShape);
    world.addBody(upperLeftLeg);
    world.addBody(upperRightLeg);

    // Pelvis
    var pelvis = new p2.Body(mass: 1, position: new p2.vec2(0.0, upperLeftLeg.position.y + upperLegLength / 2 + pelvisLength / 2));
    pelvis.addShape(pelvisShape);
    world.addBody(pelvis);

    // Upper body
    var upperBody = new p2.Body(mass: 1, position: new p2.vec2(0.0, pelvis.position.y + pelvisLength / 2 + upperBodyLength / 2));
    upperBody.addShape(upperBodyShape);
    world.addBody(upperBody);

    // Head
    var head = new p2.Body(mass: 1, position: new p2.vec2(0.0, upperBody.position.y + upperBodyLength / 2 + headRadius + neckLength));
    head.addShape(headShape);
    world.addBody(head);

    // Upper arms
    var upperLeftArm = new p2.Body(mass: 1, position: new p2.vec2(-shouldersDistance / 2 - upperArmLength / 2, upperBody.position.y + upperBodyLength / 2));
    var upperRightArm = new p2.Body(mass: 1, position: new p2.vec2(shouldersDistance / 2 + upperArmLength / 2, upperBody.position.y + upperBodyLength / 2));
    upperLeftArm.addShape(upperArmShape);
    upperRightArm.addShape(upperArmShape);
    world.addBody(upperLeftArm);
    world.addBody(upperRightArm);

    // lower arms
    var lowerLeftArm = new p2.Body(mass: 1, position: new p2.vec2(upperLeftArm.position.x - lowerArmLength / 2 - upperArmLength / 2, upperLeftArm.position.y));
    var lowerRightArm = new p2.Body(mass: 1, position: new p2.vec2(upperRightArm.position.x + lowerArmLength / 2 + upperArmLength / 2, upperRightArm.position.y));
    lowerLeftArm.addShape(lowerArmShape);
    lowerRightArm.addShape(lowerArmShape);
    world.addBody(lowerLeftArm);
    world.addBody(lowerRightArm);


    // Neck joint
    var neckJoint = new p2.RevoluteConstraint(head, upperBody, localPivotA: new p2.vec2(0.0, -headRadius - neckLength / 2), localPivotB: new p2.vec2(0.0, upperBodyLength / 2));
    neckJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    world.addConstraint(neckJoint);

    // Knee joints
    var leftKneeJoint = new p2.RevoluteConstraint(lowerLeftLeg, upperLeftLeg, localPivotA: new p2.vec2(0.0, lowerLegLength / 2), localPivotB: new p2.vec2(0.0, -upperLegLength / 2));
    var rightKneeJoint = new p2.RevoluteConstraint(lowerRightLeg, upperRightLeg, localPivotA: new p2.vec2(0.0, lowerLegLength / 2), localPivotB: new p2.vec2(0.0, -upperLegLength / 2));
    leftKneeJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    rightKneeJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    world.addConstraint(leftKneeJoint);
    world.addConstraint(rightKneeJoint);

    // Hip joints
    var leftHipJoint = new p2.RevoluteConstraint(upperLeftLeg, pelvis, localPivotA: new p2.vec2(0.0, upperLegLength / 2), localPivotB: new p2.vec2(-shouldersDistance / 2, -pelvisLength / 2));
    var rightHipJoint = new p2.RevoluteConstraint(upperRightLeg, pelvis, localPivotA: new p2.vec2(0.0, upperLegLength / 2), localPivotB: new p2.vec2(shouldersDistance / 2, -pelvisLength / 2));
    leftHipJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    rightHipJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    world.addConstraint(leftHipJoint);
    world.addConstraint(rightHipJoint);

    // Spine
    var spineJoint = new p2.RevoluteConstraint(pelvis, upperBody, localPivotA: new p2.vec2(0.0, pelvisLength / 2), localPivotB: new p2.vec2(0.0, -upperBodyLength / 2));
    spineJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    world.addConstraint(spineJoint);

    // Shoulders
    var leftShoulder = new p2.RevoluteConstraint(upperBody, upperLeftArm, localPivotA: new p2.vec2(-shouldersDistance / 2, upperBodyLength / 2), localPivotB: new p2.vec2(upperArmLength / 2, 0.0));
    var rightShoulder = new p2.RevoluteConstraint(upperBody, upperRightArm, localPivotA: new p2.vec2(shouldersDistance / 2, upperBodyLength / 2), localPivotB: new p2.vec2(-upperArmLength / 2, 0.0));
    leftShoulder.setLimits(-Math.PI / 3, Math.PI / 3);
    rightShoulder.setLimits(-Math.PI / 3, Math.PI / 3);
    world.addConstraint(leftShoulder);
    world.addConstraint(rightShoulder);

    // Elbow joint
    var leftElbowJoint = new p2.RevoluteConstraint(lowerLeftArm, upperLeftArm, localPivotA: new p2.vec2(lowerArmLength / 2, 0.0), localPivotB: new p2.vec2(-upperArmLength / 2, 0.0));
    var rightElbowJoint = new p2.RevoluteConstraint(lowerRightArm, upperRightArm, localPivotA: new p2.vec2(-lowerArmLength / 2, 0.0), localPivotB: new p2.vec2(upperArmLength / 2, 0.0));
    leftElbowJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    rightElbowJoint.setLimits(-Math.PI / 8, Math.PI / 8);
    world.addConstraint(leftElbowJoint);
    world.addConstraint(rightElbowJoint);

    // Create ground
    var planeShape = new p2.Plane();
    var plane = new p2.Body(position: new p2.vec2(0.0, -1.0));
    plane.addShape(planeShape);
    planeShape.collisionGroup = GROUND;
    planeShape.collisionMask = BODYPARTS | OTHER;
    world.addBody(plane);

    app.newShapeCollisionGroup = OTHER;
    app.newShapeCollisionMask = BODYPARTS | OTHER | GROUND;
  });


}
