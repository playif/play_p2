part of poly_decomp;

class Scalar {
  static num eq (num a,num b,[num precision=0]){
    return (a-b).abs() < precision;
  }
}
