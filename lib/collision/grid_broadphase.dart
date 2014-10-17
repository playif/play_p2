part of p2;

class GridBroadphase extends Broadphase {
  num xmin, ymin, xmax, ymax, nx, ny, binsizeX, binsizeY;

  GridBroadphase({num xmin, num ymin, num xmax, num ymax, num nx, num ny, num binsizeX, num binsizeY}) : super() {
    this.xmin = xmin;
    this.ymin = ymin;
    this.xmax = xmax;
    this.ymax = ymax;
    this.nx = nx;
    this.ny = ny;

    this.binsizeX = (this.xmax - this.xmin) / this.nx;
    this.binsizeY = (this.ymax - this.ymin) / this.ny;
  }

  /**
   * Get collision pairs.
   * @method getCollisionPairs
   * @param  {World} world
   * @return {Array}
   */
  List<Body> getCollisionPairs(World world) {
    List<Body> result = new List<Body>();
    List<Body> bodies = world.bodies;
    num Ncolliding = bodies.length,
        binsizeX = this.binsizeX,
        binsizeY = this.binsizeY,
        nx = this.nx,
        ny = this.ny,
        xmin = this.xmin,
        ymin = this.ymin,
        xmax = this.xmax,
        ymax = this.ymax;

    // Todo: make garbage free
    List<List<Body>> bins = new List<List<Body>>();
    num Nbins = nx * ny;
    for (int i = 0; i < Nbins; i++) {
      bins.add(new List<Body>());
    }

    num xmult = nx / (xmax - xmin);
    num ymult = ny / (ymax - ymin);

    // Put all bodies into bins
    for (int i = 0; i != Ncolliding; i++) {
      Body bi = bodies[i];
      AABB aabb = bi.aabb;
      num lowerX = max(aabb.lowerBound.x, xmin);
      num lowerY = max(aabb.lowerBound.y, ymin);
      num upperX = min(aabb.upperBound.x, xmax);
      num upperY = min(aabb.upperBound.y, ymax);
      num xi1 = (xmult * (lowerX - xmin)).floor();
      num yi1 = (ymult * (lowerY - ymin)).floor();
      num xi2 = (xmult * (upperX - xmin)).floor();
      num yi2 = (ymult * (upperY - ymin)).floor();

      // Put in bin
      for (int j = xi1; j <= xi2; j++) {
        for (int k = yi1; k <= yi2; k++) {
          int xi = j;
          int yi = k;
          int idx = xi * (ny - 1) + yi;
          if (idx >= 0 && idx < Nbins) {
            bins[idx].add(bi);
          }
        }
      }
    }

    // Check each bin
    for (int i = 0; i != Nbins; i++) {
      List<Body> bin = bins[i];

      for (int j = 0,
          NbodiesInBin = bin.length; j != NbodiesInBin; j++) {
        Body bi = bin[j];
        for (int k = 0; k != j; k++) {
          Body bj = bin[k];
          if (Broadphase.canCollide(bi, bj) && this.boundingVolumeCheck(bi, bj)) {
            result.addAll([bi, bj]);
          }
        }
      }
    }
    return result;
  }
}
