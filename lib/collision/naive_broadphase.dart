part of p2;

/// Naive broadphase implementation. Does N^2 tests.
class NaiveBroadphase extends Broadphase {
  NaiveBroadphase() :super(Broadphase.NAIVE);

  /// Get the colliding pairs
  List getCollisionPairs (World world){
    var bodies = world.bodies,
    result = this.result;

    result.length = 0;

    for(var i=0, Ncolliding=bodies.length; i!=Ncolliding; i++){
      var bi = bodies[i];

      for(var j=0; j<i; j++){
        var bj = bodies[j];

        if(Broadphase.canCollide(bi,bj) && this.boundingVolumeCheck(bi,bj)){
          result.addAll([bi,bj]);
        }
      }
    }

    return result;
  }
}
