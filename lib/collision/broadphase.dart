part of p2;

abstract class Broadphase {
  int type;

  /// The resulting overlapping pairs. Will be filled with results during .getCollisionPairs().
  List result;

  /// The world to search for collision pairs in. To change it, use .setWorld()
  World world;

  /// The bounding volume type to use in the broadphase algorithms.
  int boundingVolumeType;

  Broadphase([int type]) {
    this.type = type;
    this.result = [];
    this.world = null;
    this.boundingVolumeType = Broadphase.AABB;
  }

  /// Axis aligned bounding box type.
  static const int AABB = 1;

  /// Bounding circle type.
  static const int BOUNDING_CIRCLE = 2;

  /// Set the world that we are searching for collision pairs in
  setWorld (World world){
    this.world = world;
  }

  /// Get all potential intersecting body pairs.
  List getCollisionPairs (World world){
    throw new Exception("getCollisionPairs must be implemented in a subclass!");
  }

  static List  dist = vec2.create();

  /// Check whether the bounding radius of two bodies overlap.
  static bool boundingRadiusCheck (Body bodyA, Body bodyB){
    vec2.sub(dist, bodyA.position, bodyB.position);
    var d2 = vec2.squaredLength(dist),
    r = bodyA.boundingRadius + bodyB.boundingRadius;
    return d2 <= r*r;
  }

  /// Check whether the bounding radius of two bodies overlap.
  static bool aabbCheck(Body bodyA, Body bodyB){
    return bodyA.getAABB().overlaps(bodyB.getAABB());
  }

  /// Check whether the bounding radius of two bodies overlap.
  bool boundingVolumeCheck( Body bodyA, Body bodyB){
    var result;

    switch(this.boundingVolumeType){
      case Broadphase.BOUNDING_CIRCLE:
        result =  Broadphase.boundingRadiusCheck(bodyA,bodyB);
        break;
      case Broadphase.AABB:
        result = Broadphase.aabbCheck(bodyA,bodyB);
        break;
      default:
        throw new Exception('Bounding volume type not recognized: ${this.boundingVolumeType}');
    }
    return result;
  }

  /**
   * Check whether two bodies are allowed to collide at all.
   * @method  canCollide
   * @param  {Body} bodyA
   * @param  {Body} bodyB
   * @return {Boolean}
   */
  static bool canCollide (Body bodyA,Body bodyB){

    // Cannot collide static bodies
    if(bodyA.type == Body.STATIC && bodyB.type == Body.STATIC){
      return false;
    }

    // Cannot collide static vs kinematic bodies
    if( (bodyA.type == Body.KINEMATIC && bodyB.type == Body.STATIC) ||
        (bodyA.type == Body.STATIC    && bodyB.type == Body.KINEMATIC)){
      return false;
    }

    // Cannot collide kinematic vs kinematic
    if(bodyA.type == Body.KINEMATIC && bodyB.type == Body.KINEMATIC){
      return false;
    }

    // Cannot collide both sleeping bodies
    if(bodyA.sleepState == Body.SLEEPING && bodyB.sleepState == Body.SLEEPING){
      return false;
    }

    // Cannot collide if one is static and the other is sleeping
    if( (bodyA.sleepState == Body.SLEEPING && bodyB.type == Body.STATIC) ||
        (bodyB.sleepState == Body.SLEEPING && bodyA.type == Body.STATIC)){
      return false;
    }

    return true;
  }

  static const int NAIVE = 1;
  static const int SAP = 2;
}
