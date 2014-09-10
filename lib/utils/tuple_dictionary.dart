part of p2;

class TupleDictionary {
  /// The data storage
  Map data;

  /// Keys that are currently used.
  List keys;

  TupleDictionary() {
    this.data = {
    };
    this.keys = [];
  }

  /**
   * Generate a key given two integers
   * @method getKey
   * @param  {number} i
   * @param  {number} j
   * @return {string}
   */

  getKey(num id1, num id2) {
    id1 = id1.toInt();
    id2 = id2.toInt();

    if ((id1) == (id2)) {
      return -1;
    }

    // valid for values < 2^16
    return ((id1) > (id2) ?
    (id1.toInt() << 16) | (id2.toInt() & 0xFFFF) :
    (id2.toInt() << 16) | (id1.toInt() & 0xFFFF)) | 0
    ;
  }

  getByKey(num key) {
    key = key.toInt();
    return this.data[key];
  }


  get(num i, num j) {
    return this.data[this.getKey(i, j)];
  }

  /// Set a value.

  set(int i, int j, value) {
    if (value == null) {
      throw new Exception("No data!");
    }

    int key = this.getKey(i, j);

    // Check if key already exists
    if (this.data.containsKey(key)) {
      this.keys.add(key);
    }

    this.data[key] = value;

    return key;
  }

  /// Remove all data.

  reset() {
    //var data = this.data,
    //keys = this.keys;

    int l = keys.length;
    while (l-- > 0) {
      data.remove(keys[l]);
    }

    keys.clear();
  }

  /// Copy another TupleDictionary. Note that all data in this dictionary will be removed.
  copy(TupleDictionary dict) {
    this.reset();
    Utils.appendArray(this.keys, dict.keys);
    var l = dict.keys.length;
    while (l-- > 0) {
      var key = dict.keys[l];
      this.data[key] = dict.data[key];
    }
  }
}
