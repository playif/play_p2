part of p2;

class Polyk {
  static num GetArea(List p) {
    if (p.length < 6) return 0;
    int l = p.length - 2;
    num sum = 0;
    for (var i = 0; i < l; i += 2)
      sum += (p[i + 2] - p[i]) * (p[i + 1] + p[i + 3]);
    sum += (p[0] - p[l]) * (p[l + 1] + p[1]);
    return -sum * 0.5;
  }

  static List Triangulate(List p) {
    num n = p.length >> 1;
    if (n < 3) return [];
    List tgs = [];
    List avl = [];
    for (int i = 0; i < n; i++)
      avl.add(i);

    int i = 0;
    int al = n;
    while (al > 3) {
      var i0 = avl[(i + 0) % al];
      var i1 = avl[(i + 1) % al];
      var i2 = avl[(i + 2) % al];

      var ax = p[2 * i0], ay = p[2 * i0 + 1];
      var bx = p[2 * i1], by = p[2 * i1 + 1];
      var cx = p[2 * i2], cy = p[2 * i2 + 1];

      var earFound = false;
      if (PolyK._convex(ax, ay, bx, by, cx, cy)) {
        earFound = true;
        for (var j = 0; j < al; j++) {
          var vi = avl[j];
          if (vi == i0 || vi == i1 || vi == i2) continue;
          if (PolyK._PointInTriangle(p[2 * vi], p[2 * vi + 1], ax, ay, bx, by, cx, cy)) {
            earFound = false;
            break;
          }
        }
      }
      if (earFound) {
        tgs.addAll([i0, i1, i2]);
        avl.removeAt((i + 1) % al);
        al--;
        i = 0;
      }
      else if (i++ > 3 * al) break;
      // no convex angles :(
    }
    tgs.addAll([avl[0], avl[1], avl[2]]);
    return tgs;
  }

  static bool _PointInTriangle(num px, num py, num ax, num ay, num bx, num by, num cx, num cy) {
    num v0x = cx - ax;
    num v0y = cy - ay;
    num v1x = bx - ax;
    num v1y = by - ay;
    num v2x = px - ax;
    num v2y = py - ay;

    num dot00 = v0x * v0x + v0y * v0y;
    num dot01 = v0x * v1x + v0y * v1y;
    num dot02 = v0x * v2x + v0y * v2y;
    num dot11 = v1x * v1x + v1y * v1y;
    num dot12 = v1x * v2x + v1y * v2y;

    num invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
    num u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    num v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    // Check if point is in triangle
    return (u >= 0) && (v >= 0) && (u + v < 1);
  }

  static bool _convex(num ax, num ay, num bx, num by, num cx, num cy) {
    return (ay - by) * (cx - bx) + (bx - ax) * (cy - by) >= 0;
  }
}
