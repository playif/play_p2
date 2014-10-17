part of p2;

class Convex extends Shape {

  /// Vertices defined in the local frame.
  final List<vec2> vertices=new List<vec2>();

  /// Axes defined in the local frame.
  final List<vec2> axes= new List<vec2>();

  /// The center of mass of the Convex
  final vec2 centerOfMass=vec2.create();

  /// Triangulated version of this convex. The structure is Array of 3-Arrays, and each subarray contains 3 integers, referencing the vertices.
  final List triangles= new List();

  Convex._() : super(Shape.CONVEX);

  Convex([List<vec2> vertices, List<vec2> axes]) : super(Shape.CONVEX) {
    init(vertices, axes);
  }

  init(List<vec2> vertices, List<vec2> axes) {

    // Copy the verts
    for (int i = 0; i < vertices.length; i++) {
      vec2 v = vec2.create();
      vec2.copy(v, vertices[i]);
      this.vertices.add(v);
    }

    if (axes != null) {
      // Copy the axes
      for (int i = 0; i < axes.length; i++) {
        vec2 axis = vec2.create();
        vec2.copy(axis, axes[i]);
        this.axes.add(axis);
      }
    } else {
      // Construct axes from the vertex data
      for (int i = 0; i < this.vertices.length; i++) {
        // Get the world edge
        vec2 worldPoint0 = this.vertices[i];
        vec2 worldPoint1 = this.vertices[(i + 1) % vertices.length];

        vec2 normal = vec2.create();
        vec2.sub(normal, worldPoint1, worldPoint0);

        // Get normal - just rotate 90 degrees since vertices are given in CCW
        vec2.rotate90cw(normal, normal);
        vec2.normalize(normal, normal);

        this.axes.add(normal);
      }
    }

    if (this.vertices.isNotEmpty) {
      this.updateTriangles();
      this.updateCenterOfMass();
    }

    /**
         * The bounding radius of the convex
         * @property boundingRadius
         * @type {Number}
         */
    this.boundingRadius = 0;

    //Shape.call(this, Shape.CONVEX);

    this.updateBoundingRadius();
    this.updateArea();
    if (this.area < 0) {
      throw new Exception("Convex vertices must be given in conter-clockwise winding.");
    }
  }

  static final vec2 tmpVec1 = vec2.create();
  static final vec2 tmpVec2 = vec2.create();

  /**
   * Project a Convex onto a world-oriented axis
   * @method projectOntoAxis
   * @static
   * @param  {Array} offset
   * @param  {Array} localAxis
   * @param  {Array} result
   */

  projectOntoLocalAxis(vec2 localAxis, vec2 result) {
    num max = null,
        min = null;
    vec2 v;
    num value;
    vec2 localAxis = tmpVec1;

    // Get projected position of all vertices
    for (int i = 0; i < this.vertices.length; i++) {
      v = this.vertices[i];
      value = vec2.dot(v, localAxis);
      if (max == null || value > max) {
        max = value;
      }
      if (min == null || value < min) {
        min = value;
      }
    }

    if (min > max) {
      num t = min;
      min = max;
      max = t;
    }

    vec2.set(result, min, max);
  }

  projectOntoWorldAxis(vec2 localAxis,vec2 shapeOffset,num shapeAngle,vec2 result) {
    vec2 worldAxis = tmpVec2;

    this.projectOntoLocalAxis(localAxis, result);

    // Project the position of the body onto the axis - need to add this to the result
    if (shapeAngle != 0) {
      vec2.rotate(worldAxis, localAxis, shapeAngle);
    } else {
      worldAxis = localAxis;
    }
    num offset = vec2.dot(shapeOffset, worldAxis);

    vec2.set(result, result.x + offset, result.y + offset);
  }


  /**
   * Update the .triangles property
   * @method updateTriangles
   */

  updateTriangles() {

    this.triangles.clear();

    // Rewrite on polyk notation, array of numbers
    List polykVerts = new List();
    for (int i = 0; i < this.vertices.length; i++) {
      vec2 v = this.vertices[i];
      polykVerts.addAll([v.x, v.y]);
    }

    // Triangulate
    List triangles = Polyk.Triangulate(polykVerts);

    // Loop over all triangles, add their inertia contributions to I
    for (int i = 0; i < triangles.length; i += 3) {
      num id1 = triangles[i],
          id2 = triangles[i + 1],
          id3 = triangles[i + 2];

      // Add to triangles
      this.triangles.add([id1, id2, id3]);
    }
  }

  static final vec2 updateCenterOfMass_centroid = vec2.create(),
      updateCenterOfMass_centroid_times_mass = vec2.create(),
      updateCenterOfMass_a = vec2.create(),
      updateCenterOfMass_b = vec2.create(),
      updateCenterOfMass_c = vec2.create(),
      updateCenterOfMass_ac = vec2.create(),
      updateCenterOfMass_ca = vec2.create(),
      updateCenterOfMass_cb = vec2.create(),
      updateCenterOfMass_n = vec2.create();

  /**
   * Update the .centerOfMass property.
   * @method updateCenterOfMass
   */

  updateCenterOfMass() {
    List triangles = this.triangles;
    List<vec2> verts = this.vertices;
    vec2 cm = this.centerOfMass,
        centroid = updateCenterOfMass_centroid,
        n = updateCenterOfMass_n,
        a = updateCenterOfMass_a,
        b = updateCenterOfMass_b,
        c = updateCenterOfMass_c,
        ac = updateCenterOfMass_ac,
        ca = updateCenterOfMass_ca,
        cb = updateCenterOfMass_cb,
        centroid_times_mass = updateCenterOfMass_centroid_times_mass;

    vec2.set(cm, 0.0, 0.0);
    num totalArea = 0;

    for (int i = 0; i != triangles.length; i++) {
      List t = triangles[i];
      vec2 a = verts[t[0]],
          b = verts[t[1]],
          c = verts[t[2]];

      vec2.centroid(centroid, a, b, c);

      // Get mass for the triangle (density=1 in this case)
      // http://math.stackexchange.com/questions/80198/area-of-triangle-via-vectors
      num m = Convex.triangleArea(a, b, c);
      totalArea += m;

      // Add to center of mass
      vec2.scale(centroid_times_mass, centroid, m);
      vec2.add(cm, cm, centroid_times_mass);
    }

    vec2.scale(cm, cm, 1 / totalArea);
  }

  /**
   * Compute the mass moment of inertia of the Convex.
   * @method computeMomentOfInertia
   * @param  {Number} mass
   * @return {Number}
   * @see http://www.gamedev.net/topic/342822-moment-of-inertia-of-a-polygon-2d/
   */

  computeMomentOfInertia(num mass) {
    num denom = 0.0,
        numer = 0.0,
        N = this.vertices.length;
    for (int j = N - 1,
        i = 0; i < N; j = i, i++) {
      vec2 p0 = this.vertices[j];
      vec2 p1 = this.vertices[i];
      num a = (vec2.crossLength(p0, p1)).abs();
      num b = vec2.dot(p1, p1) + vec2.dot(p1, p0) + vec2.dot(p0, p0);
      denom += a * b;
      numer += a;
    }
    return (mass / 6.0) * (denom / numer);
  }

  /**
   * Updates the .boundingRadius property
   * @method updateBoundingRadius
   */

  updateBoundingRadius() {
    List<vec2> verts = this.vertices;
    num    r2 = 0;

    for (int i = 0; i != verts.length; i++) {
      num l2 = vec2.squaredLength(verts[i]);
      if (l2 > r2) {
        r2 = l2;
      }
    }

    this.boundingRadius = sqrt(r2);
  }

  /**
   * Get the area of the triangle spanned by the three points a, b, c. The area is positive if the points are given in counter-clockwise order, otherwise negative.
   * @static
   * @method triangleArea
   * @param {Array} a
   * @param {Array} b
   * @param {Array} c
   * @return {Number}
   */

  static num triangleArea(vec2 a, vec2 b, vec2 c) {
    return (((b.x - a.x) * (c.y - a.y)) - ((c.x - a.x) * (b.y - a.y))) * 0.5;
  }

  /**
   * Update the .area
   * @method updateArea
   */

  updateArea() {
    this.updateTriangles();
    this.area = 0;

    List triangles = this.triangles,
        verts = this.vertices;
    for (int i = 0; i != triangles.length; i++) {
      List t = triangles[i];
      vec2    a = verts[t[0]],
          b = verts[t[1]],
          c = verts[t[2]];

      // Get mass for the triangle (density=1 in this case)
      num m = Convex.triangleArea(a, b, c);
      this.area += m;
    }
  }

  /**
   * @method computeAABB
   * @param  {AABB}   out
   * @param  {Array}  position
   * @param  {Number} angle
   */

  computeAABB(AABB out, [vec2 position, num angle]) {
    out.setFromPoints(this.vertices, position, angle, 0);
  }
}
