part of poly_decomp;

class Polygon {
  List<vec2> vertices=new List<vec2>();

  Polygon() {
  }

  /**
   * Get a vertex at position i. It does not matter if i is out of bounds, this function will just cycle.
   * @method at
   * @param  {Number} i
   * @return {Array}
   */

  vec2 at(int i) {
    List<vec2> v = this.vertices;
    int s = v.length;
    if (i < 0) i += s;
    return v[i < 0 ? (i % s) + s : i % s];
  }

  /**
   * Get first vertex
   * @method first
   * @return {Array}
   */

  first() {
    return this.vertices.first;
  }

  /**
   * Get last vertex
   * @method last
   * @return {Array}
   */

  vec2 last() {
    return this.vertices.last;
  }

  /**
   * Clear the polygon data
   * @method clear
   * @return {Array}
   */

  List<vec2> clear() {
    this.vertices.clear();
    return this.vertices;
  }

  /**
   * Append points "from" to "to"-1 from an other polygon "poly" onto this one.
   * @method append
   * @param {Polygon} poly The polygon to get points from.
   * @param {Number}  from The vertex index in "poly".
   * @param {Number}  to The end vertex index in "poly". Note that this vertex is NOT included when appending.
   * @return {Array}
   */

  List<vec2> append(Polygon poly, num from, num to) {
//    if(from == null) throw new Exception("From is not given!");
//    if(typeof(to) == "undefined")   throw new Exception("To is not given!");

    if (to - 1 < from) throw new Exception("lol1");
    if (to > poly.vertices.length) throw new Exception("lol2");
    if (from < 0) throw new Exception("lol3");

    for (int i = from; i < to; i++) {
      this.vertices.add(poly.vertices[i]);
    }

    return this.vertices;
  }

  /**
   * Make sure that the polygon vertices are ordered counter-clockwise.
   * @method makeCCW
   */

  makeCCW() {
    num br = 0;
    List<vec2>    v = this.vertices;

    // find bottom right point
    for (int i = 1; i < this.vertices.length; ++i) {
      if (v[i].y < v[br].y || (v[i].y == v[br].y && v[i].x > v[br].x)) {
        br = i;
      }
    }

    // reverse poly if clockwise
    if (!Point.left(this.at(br - 1), this.at(br), this.at(br + 1))) {
      this.reverse();
    }
  }

  /**
   * Reverse the vertices in the polygon
   * @method reverse
   */

  reverse() {
    this.vertices = this.vertices.reversed.toList();
  }

  /**
   * Check if a point in the polygon is a reflex point
   * @method isReflex
   * @param  {Number}  i
   * @return {Boolean}
   */

  bool isReflex(int i) {
    return Point.right(this.at(i - 1), this.at(i), this.at(i + 1));
  }

  static final List<vec2> tmpLine1 = new List<vec2>(),
      tmpLine2 = new List<vec2>();

  /**
   * Check if two vertices in the polygon can see each other
   * @method canSee
   * @param  {Number} a Vertex index 1
   * @param  {Number} b Vertex index 2
   * @return {Boolean}
   */

  bool canSee(int a, int b) {
    vec2 p, dist;
    List<vec2> l1 = tmpLine1,
        l2 = tmpLine2;

    if (Point.leftOn(this.at(a + 1), this.at(a), this.at(b)) && Point.rightOn(this.at(a - 1), this.at(a), this.at(b))) {
      return false;
    }
    dist = Point.sqdist(this.at(a), this.at(b));
    for (int i = 0; i != this.vertices.length; ++i) {
      // for each edge
      if ((i + 1) % this.vertices.length == a || i == a) // ignore incident edges
      continue;
      if (Point.leftOn(this.at(a), this.at(b), this.at(i + 1)) && Point.rightOn(this.at(a), this.at(b), this.at(i))) {
        // if diag intersects an edge
        l1[0] = this.at(a);
        l1[1] = this.at(b);
        l2[0] = this.at(i);
        l2[1] = this.at(i + 1);
        p = Line.lineInt(l1, l2);
        if (Point.sqdist(this.at(a), p) < dist) {
          // if edge is blocking visibility to b
          return false;
        }
      }
    }

    return true;
  }

  /**
   * Copy the polygon from vertex i to vertex j.
   * @method copy
   * @param  {Number} i
   * @param  {Number} j
   * @param  {Polygon} [targetPoly]   Optional target polygon to save in.
   * @return {Polygon}                The resulting copy.
   */

  Polygon copy(i, j, [Polygon targetPoly]) {
    Polygon p = targetPoly == null ? new Polygon() : targetPoly;
    p.clear();
    if (i < j) {
      // Insert all vertices from i to j
      for (int k = i; k <= j; k++) p.vertices.add(this.vertices[k]);

    } else {

      // Insert vertices 0 to j
      for (int k = 0; k <= j; k++) p.vertices.add(this.vertices[k]);

      // Insert vertices i to end
      for (int k = i; k < this.vertices.length; k++) p.vertices.add(this.vertices[k]);
    }

    return p;
  }

  /**
   * Decomposes the polygon into convex pieces. Returns a list of edges [[p1,p2],[p2,p3],...] that cuts the polygon.
   * Note that this algorithm has complexity O(N^4) and will be very slow for polygons with many vertices.
   * @method getCutEdges
   * @return {Array}
   */

  List getCutEdges() {
    List min = new List(),
        tmp1 = new List<vec2>(),
        tmp2 = new List<vec2>();
    Polygon tmpPoly = new Polygon();
    num nDiags = double.MAX_FINITE;

    for (int i = 0; i < this.vertices.length; ++i) {
      if (this.isReflex(i)) {
        for (int j = 0; j < this.vertices.length; ++j) {
          if (this.canSee(i, j)) {
            tmp1 = this.copy(i, j, tmpPoly).getCutEdges();
            tmp2 = this.copy(j, i, tmpPoly).getCutEdges();

            for (int k = 0; k < tmp2.length; k++) tmp1.add(tmp2[k]);

            if (tmp1.length < nDiags) {
              min = tmp1;
              nDiags = tmp1.length;
              min.add([this.at(i), this.at(j)]);
            }
          }
        }
      }
    }

    return min;
  }

  /**
   * Decomposes the polygon into one or more convex sub-Polygons.
   * @method decomp
   * @return {Array} An array or Polygon objects.
   */

  decomp() {
    List<vec2> edges = this.getCutEdges();
    if (edges.length > 0) return this.slice(edges); else return [this];
  }

  /**
   * Slices the polygon given one or more cut edges. If given one, this function will return two polygons (false on failure). If many, an array of polygons.
   * @method slice
   * @param {Array} cutEdges A list of edges, as returned by .getCutEdges()
   * @return {Array}
   */

  List slice(List cutEdges) {
    if (cutEdges.length == 0) return [this];
    if (cutEdges is List && cutEdges.isNotEmpty && cutEdges[0] is List && cutEdges[0].length == 2 && cutEdges[0][0] is List) {

      List polys = [this];

      for (int i = 0; i < cutEdges.length; i++) {
        List cutEdge = cutEdges[i];
        // Cut all polys
        for (int j = 0; j < polys.length; j++) {
          Polygon poly = polys[j];
          List result = poly.slice(cutEdge);
          if (result != null) {
            // Found poly! Cut and quit
            polys.removeAt(j);
            polys.addAll([result[0], result[1]]);
            break;
          }
        }
      }

      return polys;
    } else {

      // Was given one edge
      List cutEdge = cutEdges;
      int i = this.vertices.indexOf(cutEdge[0]);
      int j = this.vertices.indexOf(cutEdge[1]);

      if (i != -1 && j != -1) {
        return [this.copy(i, j), this.copy(j, i)];
      } else {
        return null;
      }
    }
  }

  /**
   * Checks that the line segments of this polygon do not intersect each other.
   * @method isSimple
   * @param  {Array} path An array of vertices e.g. [[0,0],[0,1],...]
   * @return {Boolean}
   * @todo Should it check all segments with all others?
   */

  bool isSimple() {
    List<vec2> path = this.vertices;
    // Check
    for (int i = 0; i < path.length - 1; i++) {
      for (int j = 0; j < i - 1; j++) {
        if (Line.segmentsIntersect(path[i], path[i + 1], path[j], path[j + 1])) {
          return false;
        }
      }
    }

    // Check the segment between the last and the first point to all others
    for (int i = 1; i < path.length - 2; i++) {
      if (Line.segmentsIntersect(path[0], path[path.length - 1], path[i], path[i + 1])) {
        return false;
      }
    }

    return true;
  }

  vec2 getIntersectionPoint(vec2 p1, vec2 p2, vec2 q1, vec2 q2, [num delta = 0]) {
    //delta = delta || 0;
    num a1 = p2.y - p1.y;
    num b1 = p1.x - p2.x;
    num c1 = (a1 * p1.x) + (b1 * p1.y);
    num a2 = q2.y - q1.y;
    num b2 = q1.x - q2.x;
    num c2 = (a2 * q1.x) + (b2 * q1.y);
    num det = (a1 * b2) - (a2 * b1);

    if (!Scalar.eq(det, 0, delta)) return new vec2(((b2 * c1) - (b1 * c2)) / det, ((a1 * c2) - (a2 * c1)) / det); else return new vec2(0.0,0.0);
  }

  /**
   * Quickly decompose the Polygon into convex sub-polygons.
   * @method quickDecomp
   * @param  {Array} result
   * @param  {Array} [reflexVertices]
   * @param  {Array} [steinerPoints]
   * @param  {Number} [delta]
   * @param  {Number} [maxlevel]
   * @param  {Number} [level]
   * @return {Array}
   */

  List<Polygon> quickDecomp([List<Polygon> result, List<vec2> reflexVertices, List<vec2> steinerPoints, num delta = 25, num maxlevel = 100, num level = 0]) {

    result = result != null ? result : new List<Polygon>();
    reflexVertices = reflexVertices != null ? reflexVertices : new List<vec2>();
    steinerPoints = steinerPoints != null ? steinerPoints : new List<vec2>();

    vec2 upperInt = new vec2(0.0,0.0),
        lowerInt = new vec2(0.0,0.0),
        p = new vec2(0.0,0.0); // Points
    num upperDist = 0,
        lowerDist = 0,
        d = 0,
        closestDist = 0; // scalars
    int upperIndex = 0,
        lowerIndex = 0,
        closestIndex = 0; // Integers
    Polygon lowerPoly = new Polygon(),
        upperPoly = new Polygon(); // polygons
    Polygon poly = this;
    List<vec2> v = this.vertices;

    if (v.length < 3) return result;

    level++;
    if (level > maxlevel) {
      print("quickDecomp: max level (" + maxlevel.toString() + ") reached.");
      return result;
    }

    for (int i = 0; i < this.vertices.length; ++i) {
      if (poly.isReflex(i)) {
        reflexVertices.add(poly.vertices[i]);
        upperDist = lowerDist = double.MAX_FINITE;


        for (int j = 0; j < this.vertices.length; ++j) {
          if (Point.left(poly.at(i - 1), poly.at(i), poly.at(j)) && Point.rightOn(poly.at(i - 1), poly.at(i), poly.at(j - 1))) {
            // if line intersects with an edge
            p = getIntersectionPoint(poly.at(i - 1), poly.at(i), poly.at(j), poly.at(j - 1)); // find the point of intersection
            if (Point.right(poly.at(i + 1), poly.at(i), p)) {
              // make sure it's inside the poly
              d = Point.sqdist(poly.vertices[i], p);
              if (d < lowerDist) {
                // keep only the closest intersection
                lowerDist = d;
                lowerInt = p;
                lowerIndex = j;
              }
            }
          }
          if (Point.left(poly.at(i + 1), poly.at(i), poly.at(j + 1)) && Point.rightOn(poly.at(i + 1), poly.at(i), poly.at(j))) {
            p = getIntersectionPoint(poly.at(i + 1), poly.at(i), poly.at(j), poly.at(j + 1));
            if (Point.left(poly.at(i - 1), poly.at(i), p)) {
              d = Point.sqdist(poly.vertices[i], p);
              if (d < upperDist) {
                upperDist = d;
                upperInt = p;
                upperIndex = j;
              }
            }
          }
        }

        // if there are no vertices to connect to, choose a point in the middle
        if (lowerIndex == (upperIndex + 1) % this.vertices.length) {
          //console.log("Case 1: Vertex("+i+"), lowerIndex("+lowerIndex+"), upperIndex("+upperIndex+"), poly.size("+this.vertices.length+")");
          p.x = (lowerInt.x + upperInt.x) / 2;
          p.y = (lowerInt.y + upperInt.y) / 2;
          steinerPoints.add(p);

          if (i < upperIndex) {
            //lowerPoly.insert(lowerPoly.end(), poly.begin() + i, poly.begin() + upperIndex + 1);
            lowerPoly.append(poly, i, upperIndex + 1);
            lowerPoly.vertices.add(p);
            upperPoly.vertices.add(p);
            if (lowerIndex != 0) {
              //upperPoly.insert(upperPoly.end(), poly.begin() + lowerIndex, poly.end());
              upperPoly.append(poly, lowerIndex, poly.vertices.length);
            }
            //upperPoly.insert(upperPoly.end(), poly.begin(), poly.begin() + i + 1);
            upperPoly.append(poly, 0, i + 1);
          } else {
            if (i != 0) {
              //lowerPoly.insert(lowerPoly.end(), poly.begin() + i, poly.end());
              lowerPoly.append(poly, i, poly.vertices.length);
            }
            //lowerPoly.insert(lowerPoly.end(), poly.begin(), poly.begin() + upperIndex + 1);
            lowerPoly.append(poly, 0, upperIndex + 1);
            lowerPoly.vertices.add(p);
            upperPoly.vertices.add(p);
            //upperPoly.insert(upperPoly.end(), poly.begin() + lowerIndex, poly.begin() + i + 1);
            upperPoly.append(poly, lowerIndex, i + 1);
          }
        } else {
          // connect to the closest point within the triangle
          //console.log("Case 2: Vertex("+i+"), closestIndex("+closestIndex+"), poly.size("+this.vertices.length+")\n");

          if (lowerIndex > upperIndex) {
            upperIndex += this.vertices.length;
          }
          closestDist = double.MAX_FINITE;

          if (upperIndex < lowerIndex) {
            return result;
          }

          for (int j = lowerIndex; j <= upperIndex; ++j) {
            if (Point.leftOn(poly.at(i - 1), poly.at(i), poly.at(j)) && Point.rightOn(poly.at(i + 1), poly.at(i), poly.at(j))) {
              d = Point.sqdist(poly.at(i), poly.at(j));
              if (d < closestDist) {
                closestDist = d;
                closestIndex = j % this.vertices.length;
              }
            }
          }

          if (i < closestIndex) {
            lowerPoly.append(poly, i, closestIndex + 1);
            if (closestIndex != 0) {
              upperPoly.append(poly, closestIndex, v.length);
            }
            upperPoly.append(poly, 0, i + 1);
          } else {
            if (i != 0) {
              lowerPoly.append(poly, i, v.length);
            }
            lowerPoly.append(poly, 0, closestIndex + 1);
            upperPoly.append(poly, closestIndex, i + 1);
          }
        }

        // solve smallest poly first
        if (lowerPoly.vertices.length < upperPoly.vertices.length) {
          lowerPoly.quickDecomp(result, reflexVertices, steinerPoints, delta, maxlevel, level);
          upperPoly.quickDecomp(result, reflexVertices, steinerPoints, delta, maxlevel, level);
        } else {
          upperPoly.quickDecomp(result, reflexVertices, steinerPoints, delta, maxlevel, level);
          lowerPoly.quickDecomp(result, reflexVertices, steinerPoints, delta, maxlevel, level);
        }

        return result;
      }
    }
    result.add(this);

    return result;
  }

  /**
   * Remove collinear points in the polygon.
   * @method removeCollinearPoints
   * @param  {Number} [precision] The threshold angle to use when determining whether two edges are collinear. Use zero for finest precision.
   * @return {Number}           The number of points removed
   */

  num removeCollinearPoints([num precision]) {
    int num = 0;
    for (int i = this.vertices.length - 1; this.vertices.length > 3 && i >= 0; --i) {
      if (Point.collinear(this.at(i - 1), this.at(i), this.at(i + 1), precision)) {
        // Remove the middle point
        this.vertices.removeAt(i % this.vertices.length);
        i--; // Jump one point forward. Otherwise we may get a chain removal
        num++;
      }
    }
    return num;
  }
}
