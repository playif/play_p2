part of p2;

class OverlapKeeperRecord {
  Shape shapeA;
  Shape shapeB;
  Body bodyA;
  Body bodyB;

  /// Overlap data container for the OverlapKeeper

  OverlapKeeperRecord(Body bodyA, Shape shapeA, Body bodyB, Shape shapeB) {
    set(bodyA, shapeA, bodyB, shapeB);
  }

  /// Set the data for the record
  set(Body bodyA, Shape shapeA, Body bodyB, Shape shapeB) {
    this.shapeA = shapeA;
    this.shapeB = shapeB;
    this.bodyA = bodyA;
    this.bodyB = bodyB;
  }
}


class OverlapKeeper {
  TupleDictionary overlappingShapesLastState;
  TupleDictionary overlappingShapesCurrentState;
  List recordPool;
  TupleDictionary tmpDict;
  List tmpArray1;

  OverlapKeeper() {
    this.overlappingShapesLastState = new TupleDictionary();
    this.overlappingShapesCurrentState = new TupleDictionary();
    this.recordPool = [];
    this.tmpDict = new TupleDictionary();
    this.tmpArray1 = [];
  }

  /**
   * Ticks one step forward in time. This will move the current overlap state to the "old" overlap state, and create a new one as current.
   * @method tick
   */

  tick() {
    TupleDictionary last = this.overlappingShapesLastState;
    TupleDictionary current = this.overlappingShapesCurrentState;

    // Save old objects into pool
    int l = last.keys.length;
    while (l-- > 0) {
      var key = last.keys[l];
      var lastObject = last.getByKey(key);
      var currentObject = current.getByKey(key);
      if (lastObject && !currentObject) {
        // The record is only used in the "last" dict, and will be removed. We might as well pool it.
        this.recordPool.add(lastObject);
      }
    }

    // Clear last object
    last.reset();

    // Transfer from new object to old
    last.copy(current);

    // Clear current object
    current.reset();
  }

  /**
   * @method setOverlapping
   * @param {Body} bodyA
   * @param {Body} shapeA
   * @param {Body} bodyB
   * @param {Body} shapeB
   */

  setOverlapping(Body bodyA, Shape shapeA, Body bodyB, Shape shapeB) {
    var last = this.overlappingShapesLastState;
    var current = this.overlappingShapesCurrentState;

    // Store current contact state
    if (current.get(shapeA.id, shapeB.id) == null) {

      var data;
      if (this.recordPool.isNotEmpty) {
        data = this.recordPool.removeLast();
        data.set(bodyA, shapeA, bodyB, shapeB);
      } else {
        data = new OverlapKeeperRecord(bodyA, shapeA, bodyB, shapeB);
      }

      current.set(shapeA.id, shapeB.id, data);
    }
  }

  getNewOverlaps(List result) {
    return this.getDiff(this.overlappingShapesLastState, this.overlappingShapesCurrentState, result);
  }

  getEndOverlaps(List result) {
    return this.getDiff(this.overlappingShapesCurrentState, this.overlappingShapesLastState, result);
  }

  /**
   * Checks if two bodies are currently overlapping.
   * @method bodiesAreOverlapping
   * @param  {Body} bodyA
   * @param  {Body} bodyB
   * @return {boolean}
   */

  bodiesAreOverlapping(Body bodyA, Body bodyB) {
    var current = this.overlappingShapesCurrentState;
    var l = current.keys.length;
    while (l--) {
      var key = current.keys[l];
      var data = current.data[key];
      if ((data.bodyA == bodyA && data.bodyB == bodyB) || data.bodyA == bodyB && data.bodyB == bodyA) {
        return true;
      }
    }
    return false;
  }

  getDiff(TupleDictionary dictA, TupleDictionary dictB, [List result]) {
    if (result == null) result = [];
    //var result = result || [];
    TupleDictionary last = dictA;
    TupleDictionary current = dictB;

    result.length = 0;

    int l = current.keys.length;
    while (l-- > 0) {
      var key = current.keys[l];
      var data = current.data[key];

      if (!data) {
        throw new Exception('Key $key had no data!');
      }

      var lastData = last.data[key];
      if (!lastData) {
        // Not overlapping in last state, but in current.
        result.add(data);
      }
    }

    return result;
  }

  isNewOverlap(Shape shapeA, Shape shapeB) {
    var idA = shapeA.id | 0,
        idB = shapeB.id | 0;
    var last = this.overlappingShapesLastState;
    var current = this.overlappingShapesCurrentState;
    // Not in last but in new
    return !!!last.get(idA, idB) && !!current.get(idA, idB);
  }

  getNewBodyOverlaps(List result) {
    this.tmpArray1.length = 0;
    var overlaps = this.getNewOverlaps(this.tmpArray1);
    return this.getBodyDiff(overlaps, result);
  }

  getEndBodyOverlaps(List result) {
    this.tmpArray1.length = 0;
    var overlaps = this.getEndOverlaps(this.tmpArray1);
    return this.getBodyDiff(overlaps, result);
  }

  getBodyDiff(List overlaps, [List result]) {
    if (result == null) result = [];
    var accumulator = this.tmpDict;

    int l = overlaps.length;

    while (l-- > 0) {
      var data = overlaps[l];

      // Since we use body id's for the accumulator, these will be a subset of the original one
      accumulator.set(data.bodyA.id | 0, data.bodyB.id | 0, data);
    }

    l = accumulator.keys.length;
    while (l-- > 0) {
      var data = accumulator.getByKey(accumulator.keys[l]);
      if (data != null) {
        result.addAll([data.bodyA, data.bodyB]);
      }
    }

    accumulator.reset();

    return result;
  }



}
