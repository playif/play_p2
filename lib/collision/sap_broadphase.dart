part of p2;

/// Sweep and prune broadphase along one axis.
class SAPBroadphase extends Broadphase {
  /// List of bodies currently in the broadphase.
  List axisList;

  /// The axis to sort along. 0 means x-axis and 1 y-axis. If your bodies are more spread out over the X axis, set axisIndex to 0, and you will gain some performance.
  num axisIndex;

  Function _addBodyHandler;
  Function _removeBodyHandler;



  SAPBroadphase() : super(Broadphase.SAP) {
    this.axisList = [];

    this.axisIndex = 0;

    this._addBodyHandler = (Map e) {
      axisList.add(e['body']);
    };

    this._removeBodyHandler = (Map e) {
      // Remove from list
      int idx = axisList.indexOf(e['body']);
      if (idx != -1) {
        axisList.removeAt(idx);
      }
    };
  }

  /// Change the world
  setWorld(World world) {
    // Clear the old axis array
    this.axisList.clear();

    // Add all bodies from the new world
    Utils.appendArray(this.axisList, world.bodies);
    //this.axisList=world.bodies;
    
    // Remove old handlers, if any
    world.off("addBody", this._addBodyHandler).off("removeBody", this._removeBodyHandler);

    // Add handlers to update the list of bodies.
    world.on("addBody", this._addBodyHandler).on("removeBody", this._removeBodyHandler);

    this.world = world;
  }

  /// Sorts bodies along an axis.
  static List sortAxisList(List a, [num axisIndex = 0]) {
    int j;
    for (int i = 1,
        l = a.length; i < l; i++) {
      Body v = a[i];
      for (j = i - 1; j >= 0; j--) {
        if (a[j].aabb.lowerBound[axisIndex] <= v.aabb.lowerBound[axisIndex]) {
          break;
        }
        a[j + 1] = a[j];
      }
      a[j + 1] = v;
    }
    return a;
  }

  /// Get the colliding pairs
  List getCollisionPairs(World world) {
    List bodies = this.axisList,
        result = this.result;
    int axisIndex = this.axisIndex;

    result.clear();

    // Update all AABBs if needed
    int l = bodies.length;
    while (l-- > 0) {
      Body b = bodies[l];
      if (b.aabbNeedsUpdate) {
        b.updateAABB();
      }
    }

    // Sort the lists
    SAPBroadphase.sortAxisList(bodies, axisIndex);

    // Look through the X list
    for (int i = 0,
        N = bodies.length | 0; i != N; i++) {
      Body bi = bodies[i];

      for (int j = i + 1; j < N; j++) {
        Body bj = bodies[j];

        // Bounds overlap?
        bool overlaps = (bj.aabb.lowerBound[axisIndex] <= bi.aabb.upperBound[axisIndex]);
        if (!overlaps) {
          break;
        }

        if (Broadphase.canCollide(bi, bj) && this.boundingVolumeCheck(bi, bj)) {
          result.addAll([bi, bj]);
        }
      }
    }

    return result;
  }

}
