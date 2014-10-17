part of p2;


abstract class Shape {
  static int idCounter = 0;

  int type;
  int id;

  /// ounding circle radius of this shape
  num boundingRadius;

  /**
   * Collision group that this shape belongs to (bit mask). See <a href="http://www.aurelienribon.com/blog/2011/07/box2d-tutorial-collision-filtering/">this tutorial</a>.
   * @property collisionGroup
   * @type {Number}
   * @example
   *     // Setup bits for each available group
   *     var PLAYER = Math.pow(2,0),
   *         ENEMY =  Math.pow(2,1),
   *         GROUND = Math.pow(2,2)
   *
   *     // Put shapes into their groups
   *     player1Shape.collisionGroup = PLAYER;
   *     player2Shape.collisionGroup = PLAYER;
   *     enemyShape  .collisionGroup = ENEMY;
   *     groundShape .collisionGroup = GROUND;
   *
   *     // Assign groups that each shape collide with.
   *     // Note that the players can collide with ground and enemies, but not with other players.
   *     player1Shape.collisionMask = ENEMY | GROUND;
   *     player2Shape.collisionMask = ENEMY | GROUND;
   *     enemyShape  .collisionMask = PLAYER | GROUND;
   *     groundShape .collisionMask = PLAYER | ENEMY;
   *
   * @example
   *     // How collision check is done
   *     if(shapeA.collisionGroup & shapeB.collisionMask)!=0 && (shapeB.collisionGroup & shapeA.collisionMask)!=0){
   *         // The shapes will collide
   *     }
   */
  int collisionGroup;

  /// Collision mask of this shape. See .collisionGroup.
  int collisionMask;

  /// Material to use in collisions for this Shape. If this is set to null, the world will use default material properties instead.
  Material material;

  /// Area of this shape.
  num area;

  /// Set to true if you want this shape to be a sensor. A sensor does not generate contacts, but it still reports contact events. This is good if you want to know if a shape is overlapping another shape, without them generating contacts.
  bool sensor;

  Shape(int type) {
    this.type = type;
    id = idCounter++;


    this.boundingRadius = 0;


    this.collisionGroup = 1;


    this.collisionMask = 1;



    this.material = null;


    this.area = 0;


    this.sensor = false;

    
  }

  /**
   * @static
   * @property {Number} CIRCLE
   */
  static const int CIRCLE = 1;

  /**
   * @static
   * @property {Number} PARTICLE
   */
  static const int PARTICLE = 2;

  /**
   * @static
   * @property {Number} PLANE
   */
  static const int PLANE = 4;

  /**
   * @static
   * @property {Number} CONVEX
   */
  static const int CONVEX = 8;

  /**
   * @static
   * @property {Number} LINE
   */
  static const int LINE = 16;

  /**
   * @static
   * @property {Number} RECTANGLE
   */
  static const int RECTANGLE = 32;

  /**
   * @static
   * @property {Number} CAPSULE
   */
  static const int CAPSULE = 64;

  /**
   * @static
   * @property {Number} HEIGHTFIELD
   */
  static const int HEIGHTFIELD = 128;


  /**
   * Should return the moment of inertia around the Z axis of the body given the total mass. See <a href="http://en.wikipedia.org/wiki/List_of_moments_of_inertia">Wikipedia's list of moments of inertia</a>.
   * @method computeMomentOfInertia
   * @param  {Number} mass
   * @return {Number} If the inertia is infinity or if the object simply isn't possible to rotate, return 0.
   */
  computeMomentOfInertia (num mass){
    throw new Exception("Shape.computeMomentOfInertia is not implemented in this Shape...");
  }

  /**
   * Returns the bounding circle radius of this shape.
   * @method updateBoundingRadius
   * @return {Number}
   */
  updateBoundingRadius(){
    throw new Exception("Shape.updateBoundingRadius is not implemented in this Shape...");
  }

  /**
   * Update the .area property of the shape.
   * @method updateArea
   */
  updateArea();

  /**
   * Compute the world axis-aligned bounding box (AABB) of this shape.
   * @method computeAABB
   * @param  {AABB}   out      The resulting AABB.
   * @param  {Array}  position
   * @param  {Number} angle
   */
  computeAABB (AABB out, [vec2 position, num angle]);
}
