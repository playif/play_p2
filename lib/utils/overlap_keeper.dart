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
  TupleDictionary<OverlapKeeperRecord> overlappingShapesLastState;
  TupleDictionary<OverlapKeeperRecord> overlappingShapesCurrentState;
  List<OverlapKeeperRecord> recordPool;
  TupleDictionary<OverlapKeeperRecord> tmpDict;
  List<OverlapKeeperRecord> tmpArray1;

  OverlapKeeper() {
    this.overlappingShapesLastState = new TupleDictionary<OverlapKeeperRecord>();
    this.overlappingShapesCurrentState = new TupleDictionary<OverlapKeeperRecord>();
    this.recordPool = new List<OverlapKeeperRecord>();
    this.tmpDict = new TupleDictionary<OverlapKeeperRecord>();
    this.tmpArray1 = new List<OverlapKeeperRecord>();
  }

  /**
   * Ticks one step forward in time. This will move the current overlap state to the "old" overlap state, and create a new one as current.
   * @method tick
   */

  tick() {
    TupleDictionary<OverlapKeeperRecord> last = this.overlappingShapesLastState;
    TupleDictionary<OverlapKeeperRecord> current = this.overlappingShapesCurrentState;

    // Save old objects into pool
    int l = last.keys.length;
    while (l-- > 0) {
      int key = last.keys[l];
      OverlapKeeperRecord lastObject = last.getByKey(key);
      OverlapKeeperRecord currentObject = current.getByKey(key);
      if (lastObject != null && currentObject == null) {
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
    TupleDictionary<OverlapKeeperRecord> last = this.overlappingShapesLastState;
    TupleDictionary<OverlapKeeperRecord> current = this.overlappingShapesCurrentState;

    // Store current contact state
    if (current.get(shapeA.id, shapeB.id) == null) {

      OverlapKeeperRecord data;
      if (this.recordPool.isNotEmpty) {
        data = this.recordPool.removeLast();
        data.set(bodyA, shapeA, bodyB, shapeB);
      } else {
        data = new OverlapKeeperRecord(bodyA, shapeA, bodyB, shapeB);
      }

      current.set(shapeA.id, shapeB.id, data);
    }
  }

  getNewOverlaps(List<OverlapKeeperRecord> result) {
    return this.getDiff(this.overlappingShapesLastState, this.overlappingShapesCurrentState, result);
  }

  getEndOverlaps(List<OverlapKeeperRecord> result) {
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
    TupleDictionary<OverlapKeeperRecord> current = this.overlappingShapesCurrentState;
    int l = current.keys.length;
    while (l-- > 0) {
      int key = current.keys[l];
      OverlapKeeperRecord data = current.data[key];
      if ((data.bodyA == bodyA && data.bodyB == bodyB) || data.bodyA == bodyB && data.bodyB == bodyA) {
        return true;
      }
    }
    return false;
  }

  getDiff(TupleDictionary<OverlapKeeperRecord> dictA, TupleDictionary<OverlapKeeperRecord> dictB, [List<OverlapKeeperRecord> result]) {
    if (result == null) result = new List<OverlapKeeperRecord>();
    TupleDictionary<OverlapKeeperRecord> last = dictA;
    TupleDictionary<OverlapKeeperRecord> current = dictB;

    result.length = 0;

    int l = current.keys.length;
    while (l-- > 0) {
      int key = current.keys[l];
      OverlapKeeperRecord data = current.data[key];

      if (data == null) {
        throw new Exception('Key $key had no data!');
      }

      OverlapKeeperRecord lastData = last.data[key];
      if (lastData == null) {
        // Not overlapping in last state, but in current.
        result.add(data);
      }
    }

    return result;
  }

  isNewOverlap(Shape shapeA, Shape shapeB) {
    int idA = shapeA.id | 0,
        idB = shapeB.id | 0;
    TupleDictionary<OverlapKeeperRecord> last = this.overlappingShapesLastState;
    TupleDictionary<OverlapKeeperRecord> current = this.overlappingShapesCurrentState;
    // Not in last but in new
    return last.get(idA, idB) == null && current.get(idA, idB) != null;
  }

  getNewBodyOverlaps(List<OverlapKeeperRecord> result) {
    this.tmpArray1.length = 0;
    List<OverlapKeeperRecord> overlaps = this.getNewOverlaps(this.tmpArray1);
    return this.getBodyDiff(overlaps, result);
  }

  getEndBodyOverlaps(List<OverlapKeeperRecord> result) {
    this.tmpArray1.length = 0;
    List<OverlapKeeperRecord> overlaps = this.getEndOverlaps(this.tmpArray1);
    return this.getBodyDiff(overlaps, result);
  }

  getBodyDiff(List<OverlapKeeperRecord> overlaps, [List<OverlapKeeperRecord> result]) {
    if (result == null) result = new List<OverlapKeeperRecord>();
    TupleDictionary<OverlapKeeperRecord> accumulator = this.tmpDict;

    int l = overlaps.length;

    while (l-- > 0) {
      OverlapKeeperRecord data = overlaps[l];

      // Since we use body id's for the accumulator, these will be a subset of the original one
      accumulator.set(data.bodyA.id | 0, data.bodyB.id | 0, data);
    }

    l = accumulator.keys.length;
    while (l-- > 0) {
      OverlapKeeperRecord data = accumulator.getByKey(accumulator.keys[l]);
      if (data != null) {
        result.addAll([data.bodyA, data.bodyB]);
      }
    }

    accumulator.reset();

    return result;
  }



}
