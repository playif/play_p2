part of p2;

//typedef num CompareFunc(lineBody, lineShape, lineOffset, lineAngle, rectangleBody, rectangleShape, rectangleOffset, rectangleAngle, justTest);

/// Narrowphase. Creates contacts and friction given shapes and transforms.
class Narrowphase {
  /// Temp things
  List yAxis = vec2.fromValues(0, 1);

  List tmp1 = vec2.fromValues(0, 0),
      tmp2 = vec2.fromValues(0, 0),
      tmp3 = vec2.fromValues(0, 0),
      tmp4 = vec2.fromValues(0, 0),
      tmp5 = vec2.fromValues(0, 0),
      tmp6 = vec2.fromValues(0, 0),
      tmp7 = vec2.fromValues(0, 0),
      tmp8 = vec2.fromValues(0, 0),
      tmp9 = vec2.fromValues(0, 0),
      tmp10 = vec2.fromValues(0, 0),
      tmp11 = vec2.fromValues(0, 0),
      tmp12 = vec2.fromValues(0, 0),
      tmp13 = vec2.fromValues(0, 0),
      tmp14 = vec2.fromValues(0, 0),
      tmp15 = vec2.fromValues(0, 0),
      tmp16 = vec2.fromValues(0, 0),
      tmp17 = vec2.fromValues(0, 0),
      tmp18 = vec2.fromValues(0, 0),
      tmpArray = new List(2);


  List<ContactEquation> contactEquations;
  List<FrictionEquation> frictionEquations;
  bool enableFriction;
  num slipForce;
  num frictionCoefficient;
  num surfaceVelocity;
  bool reuseObjects;
  List<ContactEquation> reusableContactEquations;
  List<FrictionEquation> reusableFrictionEquations;

  /// The restitution value to use in the next contact equations.
  num restitution;
  /// The stiffness value to use in the next contact equations.
  num stiffness;
  /// The stiffness value to use in the next contact equations.
  num relaxation;
  /// The stiffness value to use in the next friction equations.
  num frictionStiffness;
  /// The relaxation value to use in the next friction equations.
  num frictionRelaxation;
  ///Enable reduction of friction equations. If disabled, a box on a plane will generate 2 contact equations and 2 friction equations. If enabled, there will be only one friction equation. Same kind of simplifications are made  for all collision types.
  bool enableFrictionReduction;
  /// Keeps track of the colliding bodies last step.
  TupleDictionary collidingBodiesLastStep;
  /// Contact skin size value to use in the next contact equations.
  num contactSkinSize;

  Narrowphase() {
    this.contactEquations = [];
    this.frictionEquations = [];
    this.enableFriction = true;
    this.slipForce = 10.0;
    this.frictionCoefficient = 0.3;
    this.surfaceVelocity = 0;

    this.reuseObjects = true;
    this.reusableContactEquations = [];
    this.reusableFrictionEquations = [];

    this.restitution = 0;
    this.stiffness = Equation.DEFAULT_STIFFNESS;
    this.relaxation = Equation.DEFAULT_RELAXATION;
    this.frictionStiffness = Equation.DEFAULT_STIFFNESS;
    this.frictionRelaxation = Equation.DEFAULT_RELAXATION;
    this.enableFrictionReduction = true;

    this.collidingBodiesLastStep = new TupleDictionary();
    this.contactSkinSize = 0.01;

    compareMap[Shape.LINE | Shape.CONVEX] = convexLine;
    compareMap[Shape.LINE | Shape.RECTANGLE] = lineRectangle;

    compareMap[Shape.CAPSULE | Shape.CONVEX] = compareMap[Shape.CAPSULE | Shape.RECTANGLE] = convexCapsule;

    compareMap[Shape.CAPSULE | Shape.CAPSULE] = capsuleCapsule;

    compareMap[Shape.LINE | Shape.LINE] = lineLine;

    compareMap[Shape.PLANE | Shape.LINE] = planeLine;

    compareMap[Shape.PARTICLE | Shape.CAPSULE] = particleCapsule;

    compareMap[Shape.CIRCLE | Shape.LINE] = circleLine;

    compareMap[Shape.CIRCLE | Shape.CAPSULE] = circleCapsule;

    compareMap[Shape.CIRCLE | Shape.CONVEX] = compareMap[Shape.CIRCLE | Shape.RECTANGLE] = circleConvex;

    compareMap[Shape.PARTICLE | Shape.CONVEX] = compareMap[Shape.PARTICLE | Shape.RECTANGLE] = particleConvex;

    compareMap[Shape.CIRCLE] = circleCircle;

    compareMap[Shape.PLANE | Shape.CONVEX] = compareMap[Shape.PLANE | Shape.RECTANGLE] = planeConvex;

    compareMap[Shape.PARTICLE | Shape.PLANE] = particlePlane;

    compareMap[Shape.CIRCLE | Shape.PARTICLE] = circleParticle;

    compareMap[Shape.PLANE | Shape.CAPSULE] = planeCapsule;

    compareMap[Shape.CIRCLE | Shape.PLANE] = circlePlane;

    compareMap[Shape.CONVEX] = compareMap[Shape.CONVEX | Shape.RECTANGLE] = compareMap[Shape.RECTANGLE] = convexConvex;


    compareMap[Shape.CIRCLE | Shape.HEIGHTFIELD] = circleHeightfield;


    compareMap[Shape.RECTANGLE | Shape.HEIGHTFIELD] = compareMap[Shape.CONVEX | Shape.HEIGHTFIELD] = convexHeightfield;
  }

  /// Check if the bodies were in contact since the last reset().
  bool collidedLastStep(Body bodyA, Body bodyB) {
    var id1 = bodyA.id | 0,
        id2 = bodyB.id | 0;
    return this.collidingBodiesLastStep.get(id1, id2) != null;
  }

  /// Throws away the old equations and gets ready to create new
  reset() {
    this.collidingBodiesLastStep.reset();

    List<Equation> eqs = this.contactEquations;
    int l = eqs.length;
    while (l-- > 0) {
      Equation eq = eqs[l];
      num id1 = eq.bodyA.id,
          id2 = eq.bodyB.id;
      this.collidingBodiesLastStep.set(id1, id2, true);
    }

    if (this.reuseObjects) {
      List<Equation> ce = this.contactEquations,
          fe = this.frictionEquations,
          rfe = this.reusableFrictionEquations,
          rce = this.reusableContactEquations;
      Utils.appendArray(rce, ce);
      Utils.appendArray(rfe, fe);
    }

    // Reset
    this.contactEquations.clear();
    this.frictionEquations.clear();
  }

  /// Creates a ContactEquation, either by reusing an existing object or creating a new one.
  ContactEquation createContactEquation(Body bodyA, Body bodyB, Shape shapeA, Shape shapeB) {
    ContactEquation c;
    if (!this.reusableContactEquations.isEmpty) {
      c = this.reusableContactEquations.removeLast();
    } else {
      c = new ContactEquation(bodyA, bodyB);
    }

    c.bodyA = bodyA;
    c.bodyB = bodyB;
    c.shapeA = shapeA;
    c.shapeB = shapeB;
    c.restitution = this.restitution;
    c.firstImpact = !this.collidedLastStep(bodyA, bodyB);
    c.stiffness = this.stiffness;
    c.relaxation = this.relaxation;
    c.needsUpdate = true;
    c.enabled = true;
    c.offset = this.contactSkinSize;

    return c;
  }

  /**
   * Creates a FrictionEquation, either by reusing an existing object or creating a new one.
   * @method createFrictionEquation
   * @param  {Body} bodyA
   * @param  {Body} bodyB
   * @return {FrictionEquation}
   */
  FrictionEquation createFrictionEquation(Body bodyA, Body bodyB, Shape shapeA, Shape shapeB) {
    FrictionEquation c;
    if (!this.reusableFrictionEquations.isEmpty) {
      c = this.reusableFrictionEquations.removeLast();
    } else {
      c = new FrictionEquation(bodyA, bodyB);
    }
    c.bodyA = bodyA;
    c.bodyB = bodyB;
    c.shapeA = shapeA;
    c.shapeB = shapeB;
    c.setSlipForce(this.slipForce);
    c.frictionCoefficient = this.frictionCoefficient;
    c.relativeVelocity = this.surfaceVelocity;
    c.enabled = true;
    c.needsUpdate = true;
    c.stiffness = this.frictionStiffness;
    c.relaxation = this.frictionRelaxation;
    c.contactEquations.length = 0;
    return c;
  }

  /// Creates a FrictionEquation given the data in the ContactEquation. Uses same offset vectors ri and rj, but the tangent vector will be constructed from the collision normal.
  FrictionEquation createFrictionFromContact(ContactEquation c) {
    var eq = this.createFrictionEquation(c.bodyA, c.bodyB, c.shapeA, c.shapeB);
    vec2.copy(eq.contactPointA, c.contactPointA);
    vec2.copy(eq.contactPointB, c.contactPointB);
    vec2.rotate90cw(eq.t, c.normalA);
    eq.contactEquations.add(c);
    return eq;
  }

  /// Take the average N latest contact point on the plane.
  FrictionEquation createFrictionFromAverage(num numContacts) {
    if (numContacts == 0) {
      throw new Exception("numContacts == 0!");
    }
    ContactEquation c = this.contactEquations[this.contactEquations.length - 1];
    FrictionEquation eq = this.createFrictionEquation(c.bodyA, c.bodyB, c.shapeA, c.shapeB);
    Body bodyA = c.bodyA;
    Body bodyB = c.bodyB;
    vec2.set(eq.contactPointA, 0, 0);
    vec2.set(eq.contactPointB, 0, 0);
    vec2.set(eq.t, 0, 0);
    for (int i = 0; i != numContacts; i++) {
      c = this.contactEquations[this.contactEquations.length - 1 - i];
      if (c.bodyA == bodyA) {
        vec2.add(eq.t, eq.t, c.normalA);
        vec2.add(eq.contactPointA, eq.contactPointA, c.contactPointA);
        vec2.add(eq.contactPointB, eq.contactPointB, c.contactPointB);
      } else {
        vec2.sub(eq.t, eq.t, c.normalA);
        vec2.add(eq.contactPointA, eq.contactPointA, c.contactPointB);
        vec2.add(eq.contactPointB, eq.contactPointB, c.contactPointA);
      }
      eq.contactEquations.add(c);
    }

    num invNumContacts = 1 / numContacts;
    vec2.scale(eq.contactPointA, eq.contactPointA, invNumContacts);
    vec2.scale(eq.contactPointB, eq.contactPointB, invNumContacts);
    vec2.normalize(eq.t, eq.t);
    vec2.rotate90cw(eq.t, eq.t);
    return eq;
  }

  Map<int, Function> compareMap = {};

  /**
   * Convex/line narrowphase
   * @method convexLine
   * @param  {Body}       convexBody
   * @param  {Convex}     convexShape
   * @param  {Array}      convexOffset
   * @param  {Number}     convexAngle
   * @param  {Body}       lineBody
   * @param  {Line}       lineShape
   * @param  {Array}      lineOffset
   * @param  {Number}     lineAngle
   * @param {boolean}     justTest
   * @todo Implement me!
   */
  num convexLine(Body convexBody, Shape convexShape, convexOffset, convexAngle, lineBody, lineShape, lineOffset, lineAngle, justTest) {
    // TODO
    if (justTest) {
      return 0;
    } else {
      return 0;
    }
  }

  /**
   * Line/rectangle narrowphase
   * @method lineRectangle
   * @param  {Body}       lineBody
   * @param  {Line}       lineShape
   * @param  {Array}      lineOffset
   * @param  {Number}     lineAngle
   * @param  {Body}       rectangleBody
   * @param  {Rectangle}  rectangleShape
   * @param  {Array}      rectangleOffset
   * @param  {Number}     rectangleAngle
   * @param  {Boolean}    justTest
   * @todo Implement me!
   */
  num lineRectangle(lineBody, lineShape, lineOffset, lineAngle, rectangleBody, rectangleShape, rectangleOffset, rectangleAngle, justTest) {
    // TODO
    if (justTest) {
      return 0;
    } else {
      return 0;
    }
  }

  setConvexToCapsuleShapeMiddle(Convex convexShape, Capsule capsuleShape) {
    vec2.set(convexShape.vertices[0], -capsuleShape.length * 0.5, -capsuleShape.radius);
    vec2.set(convexShape.vertices[1], capsuleShape.length * 0.5, -capsuleShape.radius);
    vec2.set(convexShape.vertices[2], capsuleShape.length * 0.5, capsuleShape.radius);
    vec2.set(convexShape.vertices[3], -capsuleShape.length * 0.5, capsuleShape.radius);
  }

  Rectangle convexCapsule_tempRect = new Rectangle(1, 1);
  List convexCapsule_tempVec = vec2.create();

  /**
   * Convex/capsule narrowphase
   * @method convexCapsule
   * @param  {Body}       convexBody
   * @param  {Convex}     convexShape
   * @param  {Array}      convexPosition
   * @param  {Number}     convexAngle
   * @param  {Body}       capsuleBody
   * @param  {Capsule}    capsuleShape
   * @param  {Array}      capsulePosition
   * @param  {Number}     capsuleAngle
   */
  num convexCapsule(Body convexBody, Convex convexShape, List convexPosition, num convexAngle, Body capsuleBody, Capsule capsuleShape, List capsulePosition, num capsuleAngle, bool justTest) {

    // Check the circles
    // Add offsets!
    List circlePos = convexCapsule_tempVec;
    vec2.set(circlePos, capsuleShape.length / 2, 0);
    vec2.rotate(circlePos, circlePos, capsuleAngle);
    vec2.add(circlePos, circlePos, capsulePosition);
    num result1 = this.circleConvex(capsuleBody, capsuleShape, circlePos, capsuleAngle, convexBody, convexShape, convexPosition, convexAngle, justTest, capsuleShape.radius);

    vec2.set(circlePos, -capsuleShape.length / 2, 0);
    vec2.rotate(circlePos, circlePos, capsuleAngle);
    vec2.add(circlePos, circlePos, capsulePosition);
    num result2 = this.circleConvex(capsuleBody, capsuleShape, circlePos, capsuleAngle, convexBody, convexShape, convexPosition, convexAngle, justTest, capsuleShape.radius);

    if (justTest && (result1 != 0 || result2 != 0)) {
      return 1;
    }

    // Check center rect
    Rectangle r = convexCapsule_tempRect;
    setConvexToCapsuleShapeMiddle(r, capsuleShape);
    int result = this.convexConvex(convexBody, convexShape, convexPosition, convexAngle, capsuleBody, r, capsulePosition, capsuleAngle, justTest);

    return result + result1 + result2;
  }

  /**
   * Capsule/line narrowphase
   * @method lineCapsule
   * @param  {Body}       lineBody
   * @param  {Line}       lineShape
   * @param  {Array}      linePosition
   * @param  {Number}     lineAngle
   * @param  {Body}       capsuleBody
   * @param  {Capsule}    capsuleShape
   * @param  {Array}      capsulePosition
   * @param  {Number}     capsuleAngle
   * @todo Implement me!
   */
  //Narrowphase.prototype[Shape.CAPSULE | Shape.LINE] =
  num lineCapsule(Body lineBody, Shape lineShape, linePosition, lineAngle, capsuleBody, capsuleShape, capsulePosition, capsuleAngle, justTest) {
    // TODO
    if (justTest) {
      return 0;
    } else {
      return 0;
    }
  }

  List capsuleCapsule_tempVec1 = vec2.create();
  List capsuleCapsule_tempVec2 = vec2.create();
  Rectangle capsuleCapsule_tempRect1 = new Rectangle(1, 1);

  /**
   * Capsule/capsule narrowphase
   * @method capsuleCapsule
   * @param  {Body}       bi
   * @param  {Capsule}    si
   * @param  {Array}      xi
   * @param  {Number}     ai
   * @param  {Body}       bj
   * @param  {Capsule}    sj
   * @param  {Array}      xj
   * @param  {Number}     aj
   */
  num capsuleCapsule(Body bi, Capsule si, List xi, num ai, Body bj, Capsule sj, List xj, num aj, bool justTest) {

    bool enableFrictionBefore;

    // Check the circles
    // Add offsets!
    List circlePosi = capsuleCapsule_tempVec1,
        circlePosj = capsuleCapsule_tempVec2;

    num numContacts = 0;


    // Need 4 circle checks, between all
    for (int i = 0; i < 2; i++) {

      vec2.set(circlePosi, (i == 0 ? -1 : 1) * si.length / 2, 0);
      vec2.rotate(circlePosi, circlePosi, ai);
      vec2.add(circlePosi, circlePosi, xi);

      for (int j = 0; j < 2; j++) {

        vec2.set(circlePosj, (j == 0 ? -1 : 1) * sj.length / 2, 0);
        vec2.rotate(circlePosj, circlePosj, aj);
        vec2.add(circlePosj, circlePosj, xj);

        // Temporarily turn off friction
        if (this.enableFrictionReduction) {
          enableFrictionBefore = this.enableFriction;
          this.enableFriction = false;
        }

        num result = this.circleCircle(bi, si, circlePosi, ai, bj, sj, circlePosj, aj, justTest, si.radius, sj.radius);

        if (this.enableFrictionReduction) {
          this.enableFriction = enableFrictionBefore;
        }

        if (justTest && result != 0) {
          return 1;
        }

        numContacts += result;
      }
    }

    if (this.enableFrictionReduction) {
      // Temporarily turn off friction
      enableFrictionBefore = this.enableFriction;
      this.enableFriction = false;
    }

    // Check circles against the center rectangles
    Rectangle rect = capsuleCapsule_tempRect1;
    setConvexToCapsuleShapeMiddle(rect, si);
    num result1 = this.convexCapsule(bi, rect, xi, ai, bj, sj, xj, aj, justTest);

    if (this.enableFrictionReduction) {
      this.enableFriction = enableFrictionBefore;
    }

    if (justTest && result1 != 0) {
      return 1;
    }
    numContacts += result1;

    if (this.enableFrictionReduction) {
      // Temporarily turn off friction
      enableFrictionBefore = this.enableFriction;
      this.enableFriction = false;
    }

    setConvexToCapsuleShapeMiddle(rect, sj);
    num result2 = this.convexCapsule(bj, rect, xj, aj, bi, si, xi, ai, justTest);

    if (this.enableFrictionReduction) {
      this.enableFriction = enableFrictionBefore;
    }

    if (justTest && result2 != 0) {
      return 1;
    }
    numContacts += result2;

    if (this.enableFrictionReduction) {
      if (numContacts != 0 && this.enableFriction) {
        this.frictionEquations.add(this.createFrictionFromAverage(numContacts));
      }
    }

    return numContacts;
  }

  /**
   * Line/line narrowphase
   * @method lineLine
   * @param  {Body}       bodyA
   * @param  {Line}       shapeA
   * @param  {Array}      positionA
   * @param  {Number}     angleA
   * @param  {Body}       bodyB
   * @param  {Line}       shapeB
   * @param  {Array}      positionB
   * @param  {Number}     angleB
   * @todo Implement me!
   */

  num lineLine(Body bodyA, Line shapeA, List positionA, num angleA, Body bodyB, Line shapeB, List positionB, num angleB, bool justTest) {
    // TODO
    if (justTest) {
      return 0;
    } else {
      return 0;
    }
  }

  /**
   * Plane/line Narrowphase
   * @method planeLine
   * @param  {Body}   planeBody
   * @param  {Plane}  planeShape
   * @param  {Array}  planeOffset
   * @param  {Number} planeAngle
   * @param  {Body}   lineBody
   * @param  {Line}   lineShape
   * @param  {Array}  lineOffset
   * @param  {Number} lineAngle
   */

  planeLine(Body planeBody, Plane planeShape, List planeOffset, num planeAngle, Body lineBody, Line lineShape, List lineOffset, num lineAngle, bool justTest) {
    var worldVertex0 = tmp1,
        worldVertex1 = tmp2,
        worldVertex01 = tmp3,
        worldVertex11 = tmp4,
        worldEdge = tmp5,
        worldEdgeUnit = tmp6,
        dist = tmp7,
        worldNormal = tmp8,
        worldTangent = tmp9,
        verts = tmpArray,
        numContacts = 0;

    // Get start and end points
    vec2.set(worldVertex0, -lineShape.length / 2, 0);
    vec2.set(worldVertex1, lineShape.length / 2, 0);

    // Not sure why we have to use worldVertex*1 here, but it won't work otherwise. Tired.
    vec2.rotate(worldVertex01, worldVertex0, lineAngle);
    vec2.rotate(worldVertex11, worldVertex1, lineAngle);

    vec2.add(worldVertex01, worldVertex01, lineOffset);
    vec2.add(worldVertex11, worldVertex11, lineOffset);

    vec2.copy(worldVertex0, worldVertex01);
    vec2.copy(worldVertex1, worldVertex11);

    // Get vector along the line
    vec2.sub(worldEdge, worldVertex1, worldVertex0);
    vec2.normalize(worldEdgeUnit, worldEdge);

    // Get tangent to the edge.
    vec2.rotate90cw(worldTangent, worldEdgeUnit);

    vec2.rotate(worldNormal, yAxis, planeAngle);

    // Check line ends
    verts[0] = worldVertex0;
    verts[1] = worldVertex1;
    for (var i = 0; i < verts.length; i++) {
      var v = verts[i];

      vec2.sub(dist, v, planeOffset);

      num d = vec2.dot(dist, worldNormal);

      if (d < 0) {

        if (justTest) {
          return 1;
        }

        ContactEquation c = this.createContactEquation(planeBody, lineBody, planeShape, lineShape);
        numContacts++;

        vec2.copy(c.normalA, worldNormal);
        vec2.normalize(c.normalA, c.normalA);

        // distance vector along plane normal
        vec2.scale(dist, worldNormal, d);

        // Vector from plane center to contact
        vec2.sub(c.contactPointA, v, dist);
        vec2.sub(c.contactPointA, c.contactPointA, planeBody.position);

        // From line center to contact
        vec2.sub(c.contactPointB, v, lineOffset);
        vec2.add(c.contactPointB, c.contactPointB, lineOffset);
        vec2.sub(c.contactPointB, c.contactPointB, lineBody.position);

        this.contactEquations.add(c);

        if (!this.enableFrictionReduction) {
          if (this.enableFriction) {
            this.frictionEquations.add(this.createFrictionFromContact(c));
          }
        }
      }
    }

    if (justTest) {
      return 0;
    }

    if (!this.enableFrictionReduction) {
      if (numContacts && this.enableFriction) {
        this.frictionEquations.add(this.createFrictionFromAverage(numContacts));
      }
    }

    return numContacts;
  }

  num particleCapsule(Body particleBody, Particle particleShape, List particlePosition, num particleAngle, Body capsuleBody, Capsule capsuleShape, List capsulePosition, num capsuleAngle, bool justTest) {
    return this.circleLine(particleBody, particleShape, particlePosition, particleAngle, capsuleBody, capsuleShape, capsulePosition, capsuleAngle, justTest, capsuleShape.radius, 0);
  }

  /**
   * Circle/line Narrowphase
   * @method circleLine
   * @param  {Body} circleBody
   * @param  {Circle} circleShape
   * @param  {Array} circleOffset
   * @param  {Number} circleAngle
   * @param  {Body} lineBody
   * @param  {Line} lineShape
   * @param  {Array} lineOffset
   * @param  {Number} lineAngle
   * @param {Boolean} justTest If set to true, this function will return the result (intersection or not) without adding equations.
   * @param {Number} lineRadius Radius to add to the line. Can be used to test Capsules.
   * @param {Number} circleRadius If set, this value overrides the circle shape radius.
   */
  num circleLine(Body circleBody, Shape circleShape, List circleOffset, num circleAngle, Body lineBody, lineShape, List lineOffset, num lineAngle, bool justTest, [num lineRadius = 0, num circleRadius]) {
    // var lineRadius = lineRadius || 0,
    circleRadius = circleRadius != null ? circleRadius : (circleShape as Circle).radius;

    List orthoDist = tmp1,
        lineToCircleOrthoUnit = tmp2,
        projectedPoint = tmp3,
        centerDist = tmp4,
        worldTangent = tmp5,
        worldEdge = tmp6,
        worldEdgeUnit = tmp7,
        worldVertex0 = tmp8,
        worldVertex1 = tmp9,
        worldVertex01 = tmp10,
        worldVertex11 = tmp11,
        dist = tmp12,
        lineToCircle = tmp13,
        lineEndToLineRadius = tmp14,

        verts = tmpArray;

    // Get start and end points
    vec2.set(worldVertex0, -lineShape.length / 2, 0);
    vec2.set(worldVertex1, lineShape.length / 2, 0);

    // Not sure why we have to use worldVertex*1 here, but it won't work otherwise. Tired.
    vec2.rotate(worldVertex01, worldVertex0, lineAngle);
    vec2.rotate(worldVertex11, worldVertex1, lineAngle);

    vec2.add(worldVertex01, worldVertex01, lineOffset);
    vec2.add(worldVertex11, worldVertex11, lineOffset);

    vec2.copy(worldVertex0, worldVertex01);
    vec2.copy(worldVertex1, worldVertex11);

    // Get vector along the line
    vec2.sub(worldEdge, worldVertex1, worldVertex0);
    vec2.normalize(worldEdgeUnit, worldEdge);

    // Get tangent to the edge.
    vec2.rotate90cw(worldTangent, worldEdgeUnit);

    // Check distance from the plane spanned by the edge vs the circle
    vec2.sub(dist, circleOffset, worldVertex0);
    num d = vec2.dot(dist, worldTangent); // Distance from center of line to circle center
    vec2.sub(centerDist, worldVertex0, lineOffset);

    vec2.sub(lineToCircle, circleOffset, lineOffset);

    num radiusSum = circleRadius + lineRadius;

    if (d.abs() < radiusSum) {

      // Now project the circle onto the edge
      vec2.scale(orthoDist, worldTangent, d);
      vec2.sub(projectedPoint, circleOffset, orthoDist);

      // Add the missing line radius
      vec2.scale(lineToCircleOrthoUnit, worldTangent, vec2.dot(worldTangent, lineToCircle));
      vec2.normalize(lineToCircleOrthoUnit, lineToCircleOrthoUnit);
      vec2.scale(lineToCircleOrthoUnit, lineToCircleOrthoUnit, lineRadius);
      vec2.add(projectedPoint, projectedPoint, lineToCircleOrthoUnit);

      // Check if the point is within the edge span
      num pos = vec2.dot(worldEdgeUnit, projectedPoint);
      num pos0 = vec2.dot(worldEdgeUnit, worldVertex0);
      num pos1 = vec2.dot(worldEdgeUnit, worldVertex1);

      if (pos > pos0 && pos < pos1) {
        // We got contact!

        if (justTest) {
          return 1;
        }

        ContactEquation c = this.createContactEquation(circleBody, lineBody, circleShape, lineShape);

        vec2.scale(c.normalA, orthoDist, -1);
        vec2.normalize(c.normalA, c.normalA);

        vec2.scale(c.contactPointA, c.normalA, circleRadius);
        vec2.add(c.contactPointA, c.contactPointA, circleOffset);
        vec2.sub(c.contactPointA, c.contactPointA, circleBody.position);

        vec2.sub(c.contactPointB, projectedPoint, lineOffset);
        vec2.add(c.contactPointB, c.contactPointB, lineOffset);
        vec2.sub(c.contactPointB, c.contactPointB, lineBody.position);

        this.contactEquations.add(c);

        if (this.enableFriction) {
          this.frictionEquations.add(this.createFrictionFromContact(c));
        }

        return 1;
      }
    }

    // Add corner
    verts[0] = worldVertex0;
    verts[1] = worldVertex1;

    for (var i = 0; i < verts.length; i++) {
      List v = verts[i];

      vec2.sub(dist, v, circleOffset);

      if (vec2.squaredLength(dist) < pow(radiusSum, 2)) {

        if (justTest) {
          return 1;
        }

        var c = this.createContactEquation(circleBody, lineBody, circleShape, lineShape);

        vec2.copy(c.normalA, dist);
        vec2.normalize(c.normalA, c.normalA);

        // Vector from circle to contact point is the normal times the circle radius
        vec2.scale(c.contactPointA, c.normalA, circleRadius);
        vec2.add(c.contactPointA, c.contactPointA, circleOffset);
        vec2.sub(c.contactPointA, c.contactPointA, circleBody.position);

        vec2.sub(c.contactPointB, v, lineOffset);
        vec2.scale(lineEndToLineRadius, c.normalA, -lineRadius);
        vec2.add(c.contactPointB, c.contactPointB, lineEndToLineRadius);
        vec2.add(c.contactPointB, c.contactPointB, lineOffset);
        vec2.sub(c.contactPointB, c.contactPointB, lineBody.position);

        this.contactEquations.add(c);

        if (this.enableFriction) {
          this.frictionEquations.add(this.createFrictionFromContact(c));
        }

        return 1;
      }
    }

    return 0;
  }

/**
 * Circle/capsule Narrowphase
 * @method circleCapsule
 * @param  {Body}   bi
 * @param  {Circle} si
 * @param  {Array}  xi
 * @param  {Number} ai
 * @param  {Body}   bj
 * @param  {Line}   sj
 * @param  {Array}  xj
 * @param  {Number} aj
 */
  num circleCapsule(bi, si, xi, ai, bj, sj, xj, aj, justTest) {
    return this.circleLine(bi, si, xi, ai, bj, sj, xj, aj, justTest, sj.radius);
  }

/**
 * Circle/convex Narrowphase.
 * @method circleConvex
 * @param  {Body} circleBody
 * @param  {Circle} circleShape
 * @param  {Array} circleOffset
 * @param  {Number} circleAngle
 * @param  {Body} convexBody
 * @param  {Convex} convexShape
 * @param  {Array} convexOffset
 * @param  {Number} convexAngle
 * @param  {Boolean} justTest
 * @param  {Number} circleRadius
 */

  num circleConvex(Body circleBody, circleShape, List circleOffset, num circleAngle, Body convexBody, convexShape, List convexOffset, num convexAngle, bool justTest, [num circleRadius]) {
    circleRadius = circleRadius == null ? (circleShape as Circle).radius : circleRadius;

    List worldVertex0 = tmp1,
        worldVertex1 = tmp2,
        worldEdge = tmp3,
        worldEdgeUnit = tmp4,
        worldNormal = tmp5,
        centerDist = tmp6,
        convexToCircle = tmp7,
        orthoDist = tmp8,
        projectedPoint = tmp9,
        dist = tmp10,
        worldVertex = tmp11;

    var closestEdge = -1,
        closestEdgeDistance = null,
        closestEdgeOrthoDist = tmp12,
        closestEdgeProjectedPoint = tmp13,
        candidate = tmp14,
        candidateDist = tmp15,
        minCandidate = tmp16,

        found = false,
        minCandidateDistance = double.MAX_FINITE;

    var numReported = 0;

// New algorithm:
// 1. Check so center of circle is not inside the polygon. If it is, this wont work...
// 2. For each edge
// 2. 1. Get point on circle that is closest to the edge (scale normal with -radius)
// 2. 2. Check if point is inside.

    List<List> verts = convexShape.vertices;

// Check all edges first
    for (var i = 0; i != verts.length + 1; i++) {
      var v0 = verts[i % verts.length],
          v1 = verts[(i + 1) % verts.length];

      vec2.rotate(worldVertex0, v0, convexAngle);
      vec2.rotate(worldVertex1, v1, convexAngle);
      vec2.add(worldVertex0, worldVertex0, convexOffset);
      vec2.add(worldVertex1, worldVertex1, convexOffset);
      vec2.sub(worldEdge, worldVertex1, worldVertex0);

      vec2.normalize(worldEdgeUnit, worldEdge);

// Get tangent to the edge. Points out of the Convex
      vec2.rotate90cw(worldNormal, worldEdgeUnit);

// Get point on circle, closest to the polygon
      vec2.scale(candidate, worldNormal, -circleShape.radius);
      vec2.add(candidate, candidate, circleOffset);

      if (pointInConvex(candidate, convexShape, convexOffset, convexAngle) != 0) {

        vec2.sub(candidateDist, worldVertex0, candidate);
        var candidateDistance = (vec2.dot(candidateDist, worldNormal)).abs();

        if (candidateDistance < minCandidateDistance) {
          vec2.copy(minCandidate, candidate);
          minCandidateDistance = candidateDistance;
          vec2.scale(closestEdgeProjectedPoint, worldNormal, candidateDistance);
          vec2.add(closestEdgeProjectedPoint, closestEdgeProjectedPoint, candidate);
          found = true;
        }
      }
    }

    if (found) {

      if (justTest) {
        return 1;
      }

      var c = this.createContactEquation(circleBody, convexBody, circleShape, convexShape);
      vec2.sub(c.normalA, minCandidate, circleOffset);
      vec2.normalize(c.normalA, c.normalA);

      vec2.scale(c.contactPointA, c.normalA, circleRadius);
      vec2.add(c.contactPointA, c.contactPointA, circleOffset);
      vec2.sub(c.contactPointA, c.contactPointA, circleBody.position);

      vec2.sub(c.contactPointB, closestEdgeProjectedPoint, convexOffset);
      vec2.add(c.contactPointB, c.contactPointB, convexOffset);
      vec2.sub(c.contactPointB, c.contactPointB, convexBody.position);

      this.contactEquations.add(c);

      if (this.enableFriction) {
        this.frictionEquations.add(this.createFrictionFromContact(c));
      }

      return 1;
    }

// Check all vertices
    if (circleRadius > 0) {
      for (var i = 0; i < verts.length; i++) {
        var localVertex = verts[i];
        vec2.rotate(worldVertex, localVertex, convexAngle);
        vec2.add(worldVertex, worldVertex, convexOffset);

        vec2.sub(dist, worldVertex, circleOffset);
        if (vec2.squaredLength(dist) < pow(circleRadius, 2)) {

          if (justTest) {
            return 1;
          }

          ContactEquation c = this.createContactEquation(circleBody, convexBody, circleShape, convexShape);

          vec2.copy(c.normalA, dist);
          vec2.normalize(c.normalA, c.normalA);

// Vector from circle to contact point is the normal times the circle radius
          vec2.scale(c.contactPointA, c.normalA, circleRadius);
          vec2.add(c.contactPointA, c.contactPointA, circleOffset);
          vec2.sub(c.contactPointA, c.contactPointA, circleBody.position);

          vec2.sub(c.contactPointB, worldVertex, convexOffset);
          vec2.add(c.contactPointB, c.contactPointB, convexOffset);
          vec2.sub(c.contactPointB, c.contactPointB, convexBody.position);

          this.contactEquations.add(c);

          if (this.enableFriction) {
            this.frictionEquations.add(this.createFrictionFromContact(c));
          }

          return 1;
        }
      }
    }

    return 0;
  }

  List pic_worldVertex0 = vec2.create(),
      pic_worldVertex1 = vec2.create(),
      pic_r0 = vec2.create(),
      pic_r1 = vec2.create();

/*
 * Check if a point is in a polygon
 */
  num pointInConvex(List worldPoint, Convex convexShape, List convexOffset, num convexAngle) {
    var worldVertex0 = pic_worldVertex0,
        worldVertex1 = pic_worldVertex1,
        r0 = pic_r0,
        r1 = pic_r1,
        point = worldPoint,
        verts = convexShape.vertices,
        lastCross = null;
    for (var i = 0; i != verts.length + 1; i++) {
      var v0 = verts[i % verts.length],
          v1 = verts[(i + 1) % verts.length];

      // Transform vertices to world
      // @todo The point should be transformed to local coordinates in the convex, no need to transform each vertex
      vec2.rotate(worldVertex0, v0, convexAngle);
      vec2.rotate(worldVertex1, v1, convexAngle);
      vec2.add(worldVertex0, worldVertex0, convexOffset);
      vec2.add(worldVertex1, worldVertex1, convexOffset);

      vec2.sub(r0, worldVertex0, point);
      vec2.sub(r1, worldVertex1, point);
      num cross = vec2.crossLength(r0, r1);

      if (lastCross == null) {
        lastCross = cross;
      }

      // If we got a different sign of the distance vector, the point is out of the polygon
      if (cross * lastCross <= 0) {
        return 0;
      }
      lastCross = cross;
    }
    return 1;
  }

/**
 * Particle/convex Narrowphase
 * @method particleConvex
 * @param  {Body} particleBody
 * @param  {Particle} particleShape
 * @param  {Array} particleOffset
 * @param  {Number} particleAngle
 * @param  {Body} convexBody
 * @param  {Convex} convexShape
 * @param  {Array} convexOffset
 * @param  {Number} convexAngle
 * @param {Boolean} justTest
 * @todo use pointInConvex and code more similar to circleConvex
 * @todo don't transform each vertex, but transform the particle position to convex-local instead
 */

  num particleConvex(particleBody, particleShape, particleOffset, particleAngle, convexBody, convexShape, convexOffset, convexAngle, justTest) {
    var worldVertex0 = tmp1,
        worldVertex1 = tmp2,
        worldEdge = tmp3,
        worldEdgeUnit = tmp4,
        worldTangent = tmp5,
        centerDist = tmp6,
        convexToparticle = tmp7,
        orthoDist = tmp8,
        projectedPoint = tmp9,
        dist = tmp10,
        worldVertex = tmp11,
        closestEdge = -1,
        closestEdgeDistance = null,
        closestEdgeOrthoDist = tmp12,
        closestEdgeProjectedPoint = tmp13,
        r0 = tmp14, // vector from particle to vertex0
        r1 = tmp15,
        localPoint = tmp16,
        candidateDist = tmp17,
        minEdgeNormal = tmp18,
        minCandidateDistance = double.MAX_FINITE;

    var numReported = 0,
        found = false,
        verts = convexShape.vertices;

    // Check if the particle is in the polygon at all
    if (pointInConvex(particleOffset, convexShape, convexOffset, convexAngle) == 0) {
      return 0;
    }

    if (justTest) {
      return 1;
    }

    // Check edges first
    var lastCross = null;
    for (var i = 0; i != verts.length + 1; i++) {
      var v0 = verts[i % verts.length],
          v1 = verts[(i + 1) % verts.length];

      // Transform vertices to world
      vec2.rotate(worldVertex0, v0, convexAngle);
      vec2.rotate(worldVertex1, v1, convexAngle);
      vec2.add(worldVertex0, worldVertex0, convexOffset);
      vec2.add(worldVertex1, worldVertex1, convexOffset);

      // Get world edge
      vec2.sub(worldEdge, worldVertex1, worldVertex0);
      vec2.normalize(worldEdgeUnit, worldEdge);

      // Get tangent to the edge. Points out of the Convex
      vec2.rotate90cw(worldTangent, worldEdgeUnit);

      // Check distance from the infinite line (spanned by the edge) to the particle
      vec2.sub(dist, particleOffset, worldVertex0);
      var d = vec2.dot(dist, worldTangent);
      vec2.sub(centerDist, worldVertex0, convexOffset);

      vec2.sub(convexToparticle, particleOffset, convexOffset);

      vec2.sub(candidateDist, worldVertex0, particleOffset);
      var candidateDistance = (vec2.dot(candidateDist, worldTangent)).abs();

      if (candidateDistance < minCandidateDistance) {
        minCandidateDistance = candidateDistance;
        vec2.scale(closestEdgeProjectedPoint, worldTangent, candidateDistance);
        vec2.add(closestEdgeProjectedPoint, closestEdgeProjectedPoint, particleOffset);
        vec2.copy(minEdgeNormal, worldTangent);
        found = true;
      }
    }

    if (found) {
      var c = this.createContactEquation(particleBody, convexBody, particleShape, convexShape);

      vec2.scale(c.normalA, minEdgeNormal, -1);
      vec2.normalize(c.normalA, c.normalA);

      // Particle has no extent to the contact point
      vec2.set(c.contactPointA, 0, 0);
      vec2.add(c.contactPointA, c.contactPointA, particleOffset);
      vec2.sub(c.contactPointA, c.contactPointA, particleBody.position);

      // From convex center to point
      vec2.sub(c.contactPointB, closestEdgeProjectedPoint, convexOffset);
      vec2.add(c.contactPointB, c.contactPointB, convexOffset);
      vec2.sub(c.contactPointB, c.contactPointB, convexBody.position);

      this.contactEquations.add(c);

      if (this.enableFriction) {
        this.frictionEquations.add(this.createFrictionFromContact(c));
      }

      return 1;
    }


    return 0;
  }

/**
 * Circle/circle Narrowphase
 * @method circleCircle
 * @param  {Body} bodyA
 * @param  {Circle} shapeA
 * @param  {Array} offsetA
 * @param  {Number} angleA
 * @param  {Body} bodyB
 * @param  {Circle} shapeB
 * @param  {Array} offsetB
 * @param  {Number} angleB
 * @param {Boolean} justTest
 * @param {Number} [radiusA] Optional radius to use for shapeA
 * @param {Number} [radiusB] Optional radius to use for shapeB
 */

  num circleCircle(Body bodyA, Shape shapeA, List offsetA, num angleA, Body bodyB, Shape shapeB, List offsetB, num angleB, bool justTest, [num radiusA, num radiusB]) {

    List dist = tmp1;
    radiusA = radiusA == null ? (shapeA as Circle).radius : radiusA;
    radiusB = radiusB == null ? (shapeB as Circle).radius : radiusB;

    vec2.sub(dist, offsetA, offsetB);
    num r = radiusA + radiusB;
    if (vec2.squaredLength(dist) > pow(r, 2)) {
      return 0;
    }

    if (justTest) {
      return 1;
    }

    ContactEquation c = this.createContactEquation(bodyA, bodyB, shapeA, shapeB);
    vec2.sub(c.normalA, offsetB, offsetA);
    vec2.normalize(c.normalA, c.normalA);

    vec2.scale(c.contactPointA, c.normalA, radiusA);
    vec2.scale(c.contactPointB, c.normalA, -radiusB);

    vec2.add(c.contactPointA, c.contactPointA, offsetA);
    vec2.sub(c.contactPointA, c.contactPointA, bodyA.position);

    vec2.add(c.contactPointB, c.contactPointB, offsetB);
    vec2.sub(c.contactPointB, c.contactPointB, bodyB.position);

    this.contactEquations.add(c);

    if (this.enableFriction) {
      this.frictionEquations.add(this.createFrictionFromContact(c));
    }
    return 1;
  }

/**
 * Plane/Convex Narrowphase
 * @method planeConvex
 * @param  {Body} planeBody
 * @param  {Plane} planeShape
 * @param  {Array} planeOffset
 * @param  {Number} planeAngle
 * @param  {Body} convexBody
 * @param  {Convex} convexShape
 * @param  {Array} convexOffset
 * @param  {Number} convexAngle
 * @param {Boolean} justTest
 */
  planeConvex(planeBody, planeShape, planeOffset, planeAngle, convexBody, convexShape, convexOffset, convexAngle, justTest) {
    var worldVertex = tmp1,
        worldNormal = tmp2,
        dist = tmp3;

    var numReported = 0;
    vec2.rotate(worldNormal, yAxis, planeAngle);

    for (var i = 0; i != convexShape.vertices.length; i++) {
      var v = convexShape.vertices[i];
      vec2.rotate(worldVertex, v, convexAngle);
      vec2.add(worldVertex, worldVertex, convexOffset);

      vec2.sub(dist, worldVertex, planeOffset);

      if (vec2.dot(dist, worldNormal) <= 0) {

        if (justTest) {
          return true;
        }

        // Found vertex
        numReported++;

        ContactEquation c = this.createContactEquation(planeBody, convexBody, planeShape, convexShape);

        vec2.sub(dist, worldVertex, planeOffset);

        vec2.copy(c.normalA, worldNormal);

        var d = vec2.dot(dist, c.normalA);
        vec2.scale(dist, c.normalA, d);

        // rj is from convex center to contact
        vec2.sub(c.contactPointB, worldVertex, convexBody.position);


        // ri is from plane center to contact
        vec2.sub(c.contactPointA, worldVertex, dist);
        vec2.sub(c.contactPointA, c.contactPointA, planeBody.position);

        this.contactEquations.add(c);

        if (!this.enableFrictionReduction) {
          if (this.enableFriction) {
            this.frictionEquations.add(this.createFrictionFromContact(c));
          }
        }
      }
    }

    if (this.enableFrictionReduction) {
      if (this.enableFriction && numReported != 0) {
        this.frictionEquations.add(this.createFrictionFromAverage(numReported));
      }
    }

    return numReported;
  }

/**
 * Narrowphase for particle vs plane
 * @method particlePlane
 * @param  {Body}       particleBody
 * @param  {Particle}   particleShape
 * @param  {Array}      particleOffset
 * @param  {Number}     particleAngle
 * @param  {Body}       planeBody
 * @param  {Plane}      planeShape
 * @param  {Array}      planeOffset
 * @param  {Number}     planeAngle
 * @param {Boolean}     justTest
 */
  num particlePlane(particleBody, particleShape, particleOffset, particleAngle, planeBody, planeShape, planeOffset, planeAngle, justTest) {
    var dist = tmp1,
        worldNormal = tmp2;

    //planeAngle = planeAngle || 0;

    vec2.sub(dist, particleOffset, planeOffset);
    vec2.rotate(worldNormal, yAxis, planeAngle);

    var d = vec2.dot(dist, worldNormal);

    if (d > 0) {
      return 0;
    }
    if (justTest) {
      return 1;
    }

    var c = this.createContactEquation(planeBody, particleBody, planeShape, particleShape);

    vec2.copy(c.normalA, worldNormal);
    vec2.scale(dist, c.normalA, d);
    // dist is now the distance vector in the normal direction

    // ri is the particle position projected down onto the plane, from the plane center
    vec2.sub(c.contactPointA, particleOffset, dist);
    vec2.sub(c.contactPointA, c.contactPointA, planeBody.position);

    // rj is from the body center to the particle center
    vec2.sub(c.contactPointB, particleOffset, particleBody.position);

    this.contactEquations.add(c);

    if (this.enableFriction) {
      this.frictionEquations.add(this.createFrictionFromContact(c));
    }
    return 1;
  }

/**
 * Circle/Particle Narrowphase
 * @method circleParticle
 * @param  {Body} circleBody
 * @param  {Circle} circleShape
 * @param  {Array} circleOffset
 * @param  {Number} circleAngle
 * @param  {Body} particleBody
 * @param  {Particle} particleShape
 * @param  {Array} particleOffset
 * @param  {Number} particleAngle
 * @param  {Boolean} justTest
 */
  num circleParticle(circleBody, circleShape, circleOffset, circleAngle, particleBody, particleShape, particleOffset, particleAngle, justTest) {
    var dist = tmp1;

    vec2.sub(dist, particleOffset, circleOffset);
    if (vec2.squaredLength(dist) > pow(circleShape.radius, 2)) {
      return 0;
    }
    if (justTest) {
      return 1;
    }

    ContactEquation c = this.createContactEquation(circleBody, particleBody, circleShape, particleShape);
    vec2.copy(c.normalA, dist);
    vec2.normalize(c.normalA, c.normalA);

    // Vector from circle to contact point is the normal times the circle radius
    vec2.scale(c.contactPointA, c.normalA, circleShape.radius);
    vec2.add(c.contactPointA, c.contactPointA, circleOffset);
    vec2.sub(c.contactPointA, c.contactPointA, circleBody.position);

    // Vector from particle center to contact point is zero
    vec2.sub(c.contactPointB, particleOffset, particleBody.position);

    this.contactEquations.add(c);

    if (this.enableFriction) {
      this.frictionEquations.add(this.createFrictionFromContact(c));
    }

    return 1;
  }

  Circle planeCapsule_tmpCircle = new Circle(1);
  List planeCapsule_tmp1 = vec2.create(),
      planeCapsule_tmp2 = vec2.create(),
      planeCapsule_tmp3 = vec2.create();

/**
 * @method planeCapsule
 * @param  {Body} planeBody
 * @param  {Circle} planeShape
 * @param  {Array} planeOffset
 * @param  {Number} planeAngle
 * @param  {Body} capsuleBody
 * @param  {Particle} capsuleShape
 * @param  {Array} capsuleOffset
 * @param  {Number} capsuleAngle
 * @param {Boolean} justTest
 */
  planeCapsule(planeBody, planeShape, planeOffset, planeAngle, capsuleBody, capsuleShape, capsuleOffset, capsuleAngle, justTest) {
    var end1 = planeCapsule_tmp1,
        end2 = planeCapsule_tmp2,
        circle = planeCapsule_tmpCircle,
        dst = planeCapsule_tmp3;

    // Compute world end positions
    vec2.set(end1, -capsuleShape.length / 2, 0);
    vec2.rotate(end1, end1, capsuleAngle);
    vec2.add(end1, end1, capsuleOffset);

    vec2.set(end2, capsuleShape.length / 2, 0);
    vec2.rotate(end2, end2, capsuleAngle);
    vec2.add(end2, end2, capsuleOffset);

    circle.radius = capsuleShape.radius;

    var enableFrictionBefore;

    // Temporarily turn off friction
    if (this.enableFrictionReduction) {
      enableFrictionBefore = this.enableFriction;
      this.enableFriction = false;
    }

    // Do Narrowphase as two circles
    var numContacts1 = this.circlePlane(capsuleBody, circle, end1, 0, planeBody, planeShape, planeOffset, planeAngle, justTest),
        numContacts2 = this.circlePlane(capsuleBody, circle, end2, 0, planeBody, planeShape, planeOffset, planeAngle, justTest);

    // Restore friction
    if (this.enableFrictionReduction) {
      this.enableFriction = enableFrictionBefore;
    }

    if (justTest) {
      return numContacts1 || numContacts2;
    } else {
      var numTotal = numContacts1 + numContacts2;
      if (this.enableFrictionReduction) {
        if (numTotal != 0) {
          this.frictionEquations.add(this.createFrictionFromAverage(numTotal));
        }
      }
      return numTotal;
    }
  }

/**
 * Creates ContactEquations and FrictionEquations for a collision.
 * @method circlePlane
 * @param  {Body}    bi     The first body that should be connected to the equations.
 * @param  {Circle}  si     The circle shape participating in the collision.
 * @param  {Array}   xi     Extra offset to take into account for the Shape, in addition to the one in circleBody.position. Will *not* be rotated by circleBody.angle (maybe it should, for sake of homogenity?). Set to null if none.
 * @param  {Body}    bj     The second body that should be connected to the equations.
 * @param  {Plane}   sj     The Plane shape that is participating
 * @param  {Array}   xj     Extra offset for the plane shape.
 * @param  {Number}  aj     Extra angle to apply to the plane
 */

  num circlePlane(bi, si, xi, ai, bj, sj, xj, aj, justTest) {
    var circleBody = bi,
        circleShape = si,
        circleOffset = xi, // Offset from body center, rotated!
        planeBody = bj,
        shapeB = sj,
        planeOffset = xj,
        planeAngle = aj;

    //planeAngle = planeAngle == 0? ;

    // Vector from plane to circle
    var planeToCircle = tmp1,
        worldNormal = tmp2,
        temp = tmp3;

    vec2.sub(planeToCircle, circleOffset, planeOffset);

    // World plane normal
    vec2.rotate(worldNormal, yAxis, planeAngle);

    // Normal direction distance
    var d = vec2.dot(worldNormal, planeToCircle);

    if (d > circleShape.radius) {
      return 0; // No overlap. Abort.
    }

    if (justTest) {
      return 1;
    }

    // Create contact
    var contact = this.createContactEquation(planeBody, circleBody, sj, si);

    // ni is the plane world normal
    vec2.copy(contact.normalA, worldNormal);

    // rj is the vector from circle center to the contact point
    vec2.scale(contact.contactPointB, contact.normalA, -circleShape.radius);
    vec2.add(contact.contactPointB, contact.contactPointB, circleOffset);
    vec2.sub(contact.contactPointB, contact.contactPointB, circleBody.position);

    // ri is the distance from plane center to contact.
    vec2.scale(temp, contact.normalA, d);
    vec2.sub(contact.contactPointA, planeToCircle, temp); // Subtract normal distance vector from the distance vector
    vec2.add(contact.contactPointA, contact.contactPointA, planeOffset);
    vec2.sub(contact.contactPointA, contact.contactPointA, planeBody.position);

    this.contactEquations.add(contact);

    if (this.enableFriction) {
      this.frictionEquations.add(this.createFrictionFromContact(contact));
    }

    return 1;
  }

/**
 * Convex/convex Narrowphase.See <a href="http://www.altdevblogaday.com/2011/05/13/contact-generation-between-3d-convex-meshes/">this article</a> for more info.
 * @method convexConvex
 * @param  {Body} bi
 * @param  {Convex} si
 * @param  {Array} xi
 * @param  {Number} ai
 * @param  {Body} bj
 * @param  {Convex} sj
 * @param  {Array} xj
 * @param  {Number} aj
 */
//Narrowphase.prototype[Shape.CONVEX] =
//Narrowphase.prototype[Shape.CONVEX | Shape.RECTANGLE] =
//Narrowphase.prototype[Shape.RECTANGLE] =
  num convexConvex(bi, si, xi, ai, bj, sj, xj, aj, justTest, [num precision = 0]) {
    var sepAxis = tmp1,
        worldPoint = tmp2,
        worldPoint0 = tmp3,
        worldPoint1 = tmp4,
        worldEdge = tmp5,
        projected = tmp6,
        penetrationVec = tmp7,
        dist = tmp8,
        worldNormal = tmp9,
        numContacts = 0;
    //precision = recision) == 'number' ? precision : 0;

    var found = Narrowphase.findSeparatingAxis(si, xi, ai, sj, xj, aj, sepAxis);
    if (!found) {
      return 0;
    }

// Make sure the separating axis is directed from shape i to shape j
    vec2.sub(dist, xj, xi);
    if (vec2.dot(sepAxis, dist) > 0) {
      vec2.scale(sepAxis, sepAxis, -1);
    }

// Find edges with normals closest to the separating axis
    var closestEdge1 = Narrowphase.getClosestEdge(si, ai, sepAxis, true), // Flipped axis
        closestEdge2 = Narrowphase.getClosestEdge(sj, aj, sepAxis);

    if (closestEdge1 == -1 || closestEdge2 == -1) {
      return 0;
    }

// Loop over the shapes
    for (var k = 0; k < 2; k++) {

      var closestEdgeA = closestEdge1,
          closestEdgeB = closestEdge2,
          shapeA = si,
          shapeB = sj,
          offsetA = xi,
          offsetB = xj,
          angleA = ai,
          angleB = aj,
          bodyA = bi,
          bodyB = bj;

      if (k == 0) {
// Swap!
        var tmp;
        tmp = closestEdgeA;
        closestEdgeA = closestEdgeB;
        closestEdgeB = tmp;

        tmp = shapeA;
        shapeA = shapeB;
        shapeB = tmp;

        tmp = offsetA;
        offsetA = offsetB;
        offsetB = tmp;

        tmp = angleA;
        angleA = angleB;
        angleB = tmp;

        tmp = bodyA;
        bodyA = bodyB;
        bodyB = tmp;
      }

// Loop over 2 points in convex B
      for (var j = closestEdgeB; j < closestEdgeB + 2; j++) {

// Get world point
        var v = shapeB.vertices[(j + shapeB.vertices.length) % shapeB.vertices.length];
        vec2.rotate(worldPoint, v, angleB);
        vec2.add(worldPoint, worldPoint, offsetB);

        var insideNumEdges = 0;

// Loop over the 3 closest edges in convex A
        for (var i = closestEdgeA - 1; i < closestEdgeA + 2; i++) {

          var v0 = shapeA.vertices[(i + shapeA.vertices.length) % shapeA.vertices.length],
              v1 = shapeA.vertices[(i + 1 + shapeA.vertices.length) % shapeA.vertices.length];

// Construct the edge
          vec2.rotate(worldPoint0, v0, angleA);
          vec2.rotate(worldPoint1, v1, angleA);
          vec2.add(worldPoint0, worldPoint0, offsetA);
          vec2.add(worldPoint1, worldPoint1, offsetA);

          vec2.sub(worldEdge, worldPoint1, worldPoint0);

          vec2.rotate90cw(worldNormal, worldEdge); // Normal points out of convex 1
          vec2.normalize(worldNormal, worldNormal);

          vec2.sub(dist, worldPoint, worldPoint0);

          var d = vec2.dot(worldNormal, dist);

          if ((i == closestEdgeA && d <= precision) || (i != closestEdgeA && d <= 0)) {
            insideNumEdges++;
          }
        }

        if (insideNumEdges >= 3) {

          if (justTest) {
            return 1;
          }

// worldPoint was on the "inside" side of each of the 3 checked edges.
// Project it to the center edge and use the projection direction as normal

// Create contact
          var c = this.createContactEquation(bodyA, bodyB, shapeA, shapeB);
          numContacts++;

// Get center edge from body A
          var v0 = shapeA.vertices[(closestEdgeA) % shapeA.vertices.length],
              v1 = shapeA.vertices[(closestEdgeA + 1) % shapeA.vertices.length];

// Construct the edge
          vec2.rotate(worldPoint0, v0, angleA);
          vec2.rotate(worldPoint1, v1, angleA);
          vec2.add(worldPoint0, worldPoint0, offsetA);
          vec2.add(worldPoint1, worldPoint1, offsetA);

          vec2.sub(worldEdge, worldPoint1, worldPoint0);

          vec2.rotate90cw(c.normalA, worldEdge); // Normal points out of convex A
          vec2.normalize(c.normalA, c.normalA);

          vec2.sub(dist, worldPoint, worldPoint0); // From edge point to the penetrating point
          var d = vec2.dot(c.normalA, dist); // Penetration
          vec2.scale(penetrationVec, c.normalA, d); // Vector penetration

          vec2.sub(c.contactPointA, worldPoint, offsetA);
          vec2.sub(c.contactPointA, c.contactPointA, penetrationVec);
          vec2.add(c.contactPointA, c.contactPointA, offsetA);
          vec2.sub(c.contactPointA, c.contactPointA, bodyA.position);

          vec2.sub(c.contactPointB, worldPoint, offsetB);
          vec2.add(c.contactPointB, c.contactPointB, offsetB);
          vec2.sub(c.contactPointB, c.contactPointB, bodyB.position);

          this.contactEquations.add(c);

// Todo reduce to 1 friction equation if we have 2 contact points
          if (!this.enableFrictionReduction) {
            if (this.enableFriction) {
              this.frictionEquations.add(this.createFrictionFromContact(c));
            }
          }
        }
      }
    }

    if (this.enableFrictionReduction) {
      if (this.enableFriction && numContacts != 0) {
        this.frictionEquations.add(this.createFrictionFromAverage(numContacts));
      }
    }

    return numContacts;
  }

// .projectConvex is called by other functions, need local tmp vectors
  static List pcoa_tmp1 = vec2.fromValues(0, 0);

/**
 * Project a Convex onto a world-oriented axis
 * @method projectConvexOntoAxis
 * @static
 * @param  {Convex} convexShape
 * @param  {Array} convexOffset
 * @param  {Number} convexAngle
 * @param  {Array} worldAxis
 * @param  {Array} result
 */
  static projectConvexOntoAxis(convexShape, convexOffset, convexAngle, worldAxis, result) {
    var max = null,
        min = null,
        v,
        value,
        localAxis = pcoa_tmp1;

    // Convert the axis to local coords of the body
    vec2.rotate(localAxis, worldAxis, -convexAngle);

    // Get projected position of all vertices
    for (var i = 0; i < convexShape.vertices.length; i++) {
      v = convexShape.vertices[i];
      value = vec2.dot(v, localAxis);
      if (max == null || value > max) {
        max = value;
      }
      if (min == null || value < min) {
        min = value;
      }
    }

    if (min > max) {
      var t = min;
      min = max;
      max = t;
    }

    // Project the position of the body onto the axis - need to add this to the result
    var offset = vec2.dot(convexOffset, worldAxis);

    vec2.set(result, min + offset, max + offset);
  }

// .findSeparatingAxis is called by other functions, need local tmp vectors
  static List fsa_tmp1 = vec2.fromValues(0, 0),
      fsa_tmp2 = vec2.fromValues(0, 0),
      fsa_tmp3 = vec2.fromValues(0, 0),
      fsa_tmp4 = vec2.fromValues(0, 0),
      fsa_tmp5 = vec2.fromValues(0, 0),
      fsa_tmp6 = vec2.fromValues(0, 0);

/**
 * Find a separating axis between the shapes, that maximizes the separating distance between them.
 * @method findSeparatingAxis
 * @static
 * @param  {Convex}     c1
 * @param  {Array}      offset1
 * @param  {Number}     angle1
 * @param  {Convex}     c2
 * @param  {Array}      offset2
 * @param  {Number}     angle2
 * @param  {Array}      sepAxis     The resulting axis
 * @return {Boolean}                Whether the axis could be found.
 */
  static findSeparatingAxis(c1, offset1, angle1, c2, offset2, angle2, sepAxis) {
    var maxDist = null,
        overlap = false,
        found = false,
        edge = fsa_tmp1,
        worldPoint0 = fsa_tmp2,
        worldPoint1 = fsa_tmp3,
        normal = fsa_tmp4,
        span1 = fsa_tmp5,
        span2 = fsa_tmp6;

    if (c1 is Rectangle && c2 is Rectangle) {

      for (var j = 0; j != 2; j++) {
        var c = c1,
            angle = angle1;
        if (j == 1) {
          c = c2;
          angle = angle2;
        }

        for (var i = 0; i != 2; i++) {

          // Get the world edge
          if (i == 0) {
            vec2.set(normal, 0, 1);
          } else if (i == 1) {
            vec2.set(normal, 1, 0);
          }
          if (angle != 0) {
            vec2.rotate(normal, normal, angle);
          }

          // Project hulls onto that normal
          Narrowphase.projectConvexOntoAxis(c1, offset1, angle1, normal, span1);
          Narrowphase.projectConvexOntoAxis(c2, offset2, angle2, normal, span2);

          // Order by span position
          var a = span1,
              b = span2,
              swapped = false;
          if (span1[0] > span2[0]) {
            b = span1;
            a = span2;
            swapped = true;
          }

          // Get separating distance
          var dist = b[0] - a[1];
          overlap = (dist <= 0);

          if (maxDist == null || dist > maxDist) {
            vec2.copy(sepAxis, normal);
            maxDist = dist;
            found = overlap;
          }
        }
      }

    } else {

      for (var j = 0; j != 2; j++) {
        var c = c1,
            angle = angle1;
        if (j == 1) {
          c = c2;
          angle = angle2;
        }

        for (var i = 0; i != c.vertices.length; i++) {
          // Get the world edge
          vec2.rotate(worldPoint0, c.vertices[i], angle);
          vec2.rotate(worldPoint1, c.vertices[(i + 1) % c.vertices.length], angle);

          vec2.sub(edge, worldPoint1, worldPoint0);

          // Get normal - just rotate 90 degrees since vertices are given in CCW
          vec2.rotate90cw(normal, edge);
          vec2.normalize(normal, normal);

          // Project hulls onto that normal
          Narrowphase.projectConvexOntoAxis(c1, offset1, angle1, normal, span1);
          Narrowphase.projectConvexOntoAxis(c2, offset2, angle2, normal, span2);

          // Order by span position
          var a = span1,
              b = span2,
              swapped = false;
          if (span1[0] > span2[0]) {
            b = span1;
            a = span2;
            swapped = true;
          }

          // Get separating distance
          var dist = b[0] - a[1];
          overlap = (dist <= 0);

          if (maxDist == null || dist > maxDist) {
            vec2.copy(sepAxis, normal);
            maxDist = dist;
            found = overlap;
          }
        }
      }
    }


    /*
    // Needs to be tested some more
    for(var j=0; j!==2; j++){
        var c = c1,
            angle = angle1;
        if(j===1){
            c = c2;
            angle = angle2;
        }

        for(var i=0; i!==c.axes.length; i++){

            var normal = c.axes[i];

            // Project hulls onto that normal
            Narrowphase.projectConvexOntoAxis(c1, offset1, angle1, normal, span1);
            Narrowphase.projectConvexOntoAxis(c2, offset2, angle2, normal, span2);

            // Order by span position
            var a=span1,
                b=span2,
                swapped = false;
            if(span1[0] > span2[0]){
                b=span1;
                a=span2;
                swapped = true;
            }

            // Get separating distance
            var dist = b[0] - a[1];
            overlap = (dist <= Narrowphase.convexPrecision);

            if(maxDist===null || dist > maxDist){
                vec2.copy(sepAxis, normal);
                maxDist = dist;
                found = overlap;
            }
        }
    }
    */

    return found;
  }

// .getClosestEdge is called by other functions, need local tmp vectors
  static List gce_tmp1 = vec2.fromValues(0, 0),
      gce_tmp2 = vec2.fromValues(0, 0),
      gce_tmp3 = vec2.fromValues(0, 0);

/**
 * Get the edge that has a normal closest to an axis.
 * @method getClosestEdge
 * @static
 * @param  {Convex}     c
 * @param  {Number}     angle
 * @param  {Array}      axis
 * @param  {Boolean}    flip
 * @return {Number}             Index of the edge that is closest. This index and the next spans the resulting edge. Returns -1 if failed.
 */
  static num getClosestEdge(c, angle, axis, [bool flip = false]) {
    var localAxis = gce_tmp1,
        edge = gce_tmp2,
        normal = gce_tmp3;

    // Convert the axis to local coords of the body
    vec2.rotate(localAxis, axis, -angle);
    if (flip) {
      vec2.scale(localAxis, localAxis, -1);
    }

    var closestEdge = -1,
        N = c.vertices.length,
        maxDot = -1;
    for (var i = 0; i != N; i++) {
      // Get the edge
      vec2.sub(edge, c.vertices[(i + 1) % N], c.vertices[i % N]);

      // Get normal - just rotate 90 degrees since vertices are given in CCW
      vec2.rotate90cw(normal, edge);
      vec2.normalize(normal, normal);

      var d = vec2.dot(normal, localAxis);
      if (closestEdge == -1 || d > maxDot) {
        closestEdge = i % N;
        maxDot = d;
      }
    }

    return closestEdge;
  }

  List circleHeightfield_candidate = vec2.create(),
      circleHeightfield_dist = vec2.create(),
      circleHeightfield_v0 = vec2.create(),
      circleHeightfield_v1 = vec2.create(),
      circleHeightfield_minCandidate = vec2.create(),
      circleHeightfield_worldNormal = vec2.create(),
      circleHeightfield_minCandidateNormal = vec2.create();

/**
 * @method circleHeightfield
 * @param  {Body}           bi
 * @param  {Circle}         si
 * @param  {Array}          xi
 * @param  {Body}           bj
 * @param  {Heightfield}    sj
 * @param  {Array}          xj
 * @param  {Number}         aj
 */

  num circleHeightfield(circleBody, circleShape, circlePos, circleAngle, hfBody, hfShape, hfPos, hfAngle, justTest, [radius]) {
    var data = hfShape.data,

        w = hfShape.elementWidth,
        dist = circleHeightfield_dist,
        candidate = circleHeightfield_candidate,
        minCandidate = circleHeightfield_minCandidate,
        minCandidateNormal = circleHeightfield_minCandidateNormal,
        worldNormal = circleHeightfield_worldNormal,
        v0 = circleHeightfield_v0,
        v1 = circleHeightfield_v1;

    radius = radius == null ? circleShape.radius : radius;

    // Get the index of the points to test against
    var idxA = ((circlePos[0] - radius - hfPos[0]) / w).floor(),
        idxB = ((circlePos[0] + radius - hfPos[0]) / w).ceil();

    /*if(idxB < 0 || idxA >= data.length)
        return justTest ? false : 0;*/

    if (idxA < 0) {
      idxA = 0;
    }
    if (idxB >= data.length) {
      idxB = data.length - 1;
    }

    // Get max and min
    var max = data[idxA],
        min = data[idxB];
    for (var i = idxA; i < idxB; i++) {
      if (data[i] < min) {
        min = data[i];
      }
      if (data[i] > max) {
        max = data[i];
      }
    }

    if (circlePos[1] - radius > max) {
      return justTest ? false : 0;
    }

    /*
    if(circlePos[1]+radius < min){
        // Below the minimum point... We can just guess.
        // TODO
    }
    */

    // 1. Check so center of circle is not inside the field. If it is, this wont work...
    // 2. For each edge
    // 2. 1. Get point on circle that is closest to the edge (scale normal with -radius)
    // 2. 2. Check if point is inside.

    var found = false;

    // Check all edges first
    for (var i = idxA; i < idxB; i++) {

      // Get points
      vec2.set(v0, i * w, data[i]);
      vec2.set(v1, (i + 1) * w, data[i + 1]);
      vec2.add(v0, v0, hfPos);
      vec2.add(v1, v1, hfPos);

      // Get normal
      vec2.sub(worldNormal, v1, v0);
      vec2.rotate(worldNormal, worldNormal, PI / 2);
      vec2.normalize(worldNormal, worldNormal);

      // Get point on circle, closest to the edge
      vec2.scale(candidate, worldNormal, -radius);
      vec2.add(candidate, candidate, circlePos);

      // Distance from v0 to the candidate point
      vec2.sub(dist, candidate, v0);

      // Check if it is in the element "stick"
      var d = vec2.dot(dist, worldNormal);
      if (candidate[0] >= v0[0] && candidate[0] < v1[0] && d <= 0) {

        if (justTest) {
          return 1;
        }

        found = true;

        // Store the candidate point, projected to the edge
        vec2.scale(dist, worldNormal, -d);
        vec2.add(minCandidate, candidate, dist);
        vec2.copy(minCandidateNormal, worldNormal);

        ContactEquation c = this.createContactEquation(hfBody, circleBody, hfShape, circleShape);

        // Normal is out of the heightfield
        vec2.copy(c.normalA, minCandidateNormal);

        // Vector from circle to heightfield
        vec2.scale(c.contactPointB, c.normalA, -radius);
        vec2.add(c.contactPointB, c.contactPointB, circlePos);
        vec2.sub(c.contactPointB, c.contactPointB, circleBody.position);

        vec2.copy(c.contactPointA, minCandidate);
        vec2.sub(c.contactPointA, c.contactPointA, hfBody.position);

        this.contactEquations.add(c);

        if (this.enableFriction) {
          this.frictionEquations.add(this.createFrictionFromContact(c));
        }
      }
    }

    // Check all vertices
    found = false;
    if (radius > 0) {
      for (var i = idxA; i <= idxB; i++) {

        // Get point
        vec2.set(v0, i * w, data[i]);
        vec2.add(v0, v0, hfPos);

        vec2.sub(dist, circlePos, v0);

        if (vec2.squaredLength(dist) < pow(radius, 2)) {

          if (justTest) {
            return 1;
          }

          found = true;

          var c = this.createContactEquation(hfBody, circleBody, hfShape, circleShape);

          // Construct normal - out of heightfield
          vec2.copy(c.normalA, dist);
          vec2.normalize(c.normalA, c.normalA);

          vec2.scale(c.contactPointB, c.normalA, -radius);
          vec2.add(c.contactPointB, c.contactPointB, circlePos);
          vec2.sub(c.contactPointB, c.contactPointB, circleBody.position);

          vec2.sub(c.contactPointA, v0, hfPos);
          vec2.add(c.contactPointA, c.contactPointA, hfPos);
          vec2.sub(c.contactPointA, c.contactPointA, hfBody.position);

          this.contactEquations.add(c);

          if (this.enableFriction) {
            this.frictionEquations.add(this.createFrictionFromContact(c));
          }
        }
      }
    }

    if (found) {
      return 1;
    }

    return 0;

  }

  List convexHeightfield_v0 = vec2.create(),
      convexHeightfield_v1 = vec2.create(),
      convexHeightfield_tilePos = vec2.create();
  Convex convexHeightfield_tempConvexShape = new Convex([vec2.create(), vec2.create(), vec2.create(), vec2.create()]);
/**
 * @method circleHeightfield
 * @param  {Body}           bi
 * @param  {Circle}         si
 * @param  {Array}          xi
 * @param  {Body}           bj
 * @param  {Heightfield}    sj
 * @param  {Array}          xj
 * @param  {Number}         aj
 */
//Narrowphase.prototype[Shape.RECTANGLE | Shape.HEIGHTFIELD] =
//Narrowphase.prototype[Shape.CONVEX | Shape.HEIGHTFIELD] =
  num convexHeightfield(convexBody, convexShape, convexPos, convexAngle, hfBody, hfShape, hfPos, hfAngle, justTest) {
    var data = hfShape.data,
        w = hfShape.elementWidth,
        v0 = convexHeightfield_v0,
        v1 = convexHeightfield_v1,
        tilePos = convexHeightfield_tilePos,
        tileConvex = convexHeightfield_tempConvexShape;

    // Get the index of the points to test against
    var idxA = ((convexBody.aabb.lowerBound[0] - hfPos[0]) / w).floor(),
        idxB = ((convexBody.aabb.upperBound[0] - hfPos[0]) / w).ceil();

    if (idxA < 0) {
      idxA = 0;
    }
    if (idxB >= data.length) {
      idxB = data.length - 1;
    }

    // Get max and min
    var max = data[idxA],
        min = data[idxB];
    for (var i = idxA; i < idxB; i++) {
      if (data[i] < min) {
        min = data[i];
      }
      if (data[i] > max) {
        max = data[i];
      }
    }

    if (convexBody.aabb.lowerBound[1] > max) {
      return 0;
    }

    bool found = false;
    num numContacts = 0;

    // Loop over all edges
    // TODO: If possible, construct a convex from several data points (need o check if the points make a convex shape)
    for (int i = idxA; i < idxB; i++) {

      // Get points
      vec2.set(v0, i * w, data[i]);
      vec2.set(v1, (i + 1) * w, data[i + 1]);
      vec2.add(v0, v0, hfPos);
      vec2.add(v1, v1, hfPos);

      // Construct a convex
      num tileHeight = 100; // todo
      vec2.set(tilePos, (v1[0] + v0[0]) * 0.5, (v1[1] + v0[1] - tileHeight) * 0.5);

      vec2.sub(tileConvex.vertices[0], v1, tilePos);
      vec2.sub(tileConvex.vertices[1], v0, tilePos);
      vec2.copy(tileConvex.vertices[2], tileConvex.vertices[1]);
      vec2.copy(tileConvex.vertices[3], tileConvex.vertices[0]);
      tileConvex.vertices[2][1] -= tileHeight;
      tileConvex.vertices[3][1] -= tileHeight;

      // Do convex collision
      numContacts += this.convexConvex(convexBody, convexShape, convexPos, convexAngle, hfBody, tileConvex, tilePos, 0, justTest);
    }

    return numContacts;
  }
}
