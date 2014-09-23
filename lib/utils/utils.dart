part of p2;


class Utils {

  /// Append the values in array b to the array a.
  static appendArray(List a, List b) {
    a.addAll(b);
  }

  /// Garbage free Array.splice(). Does not allocate a new array.
  static splice(List array, int index, [int howmany = 1]) {
//    int len=array.length-howmany;
//    for (int i=index; i < len; i++){
//      array[i] = array[i + howmany];
//    }
    array.removeRange(index, index + howmany);
  }

  /// The array type to use for internal numeric computations throughout the library. [Float32List] is used if it is available, but falls back on Array. If you want to set array type manually, inject it via the global variable P2_ARRAY_TYPE. See example below.

  /// Extend an object with the properties of another

  /// Extend an options object with default values.


}
