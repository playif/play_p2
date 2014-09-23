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
  List getCollisionPairs(World world) {
    var result = [],
        bodies = world.bodies,
        Ncolliding = bodies.length,
        binsizeX = this.binsizeX,
        binsizeY = this.binsizeY,
        nx = this.nx,
        ny = this.ny,
        xmin = this.xmin,
        ymin = this.ymin,
        xmax = this.xmax,
        ymax = this.ymax;

    // Todo: make garbage free
    var bins = [],
        Nbins = nx * ny;
    for (var i = 0; i < Nbins; i++) {
      bins.add([]);
    }

    var xmult = nx / (xmax - xmin);
    var ymult = ny / (ymax - ymin);

    // Put all bodies into bins
    for (var i = 0; i != Ncolliding; i++) {
      var bi = bodies[i];
      var aabb = bi.aabb;
      var lowerX = max(aabb.lowerBound[0], xmin);
      var lowerY = max(aabb.lowerBound[1], ymin);
      var upperX = min(aabb.upperBound[0], xmax);
      var upperY = min(aabb.upperBound[1], ymax);
      var xi1 = (xmult * (lowerX - xmin)).floor();
      var yi1 = (ymult * (lowerY - ymin)).floor();
      var xi2 = (xmult * (upperX - xmin)).floor();
      var yi2 = (ymult * (upperY - ymin)).floor();

      // Put in bin
      for (var j = xi1; j <= xi2; j++) {
        for (var k = yi1; k <= yi2; k++) {
          var xi = j;
          var yi = k;
          var idx = xi * (ny - 1) + yi;
          if (idx >= 0 && idx < Nbins) {
            bins[idx].push(bi);
          }
        }
      }
    }

    // Check each bin
    for (var i = 0; i != Nbins; i++) {
      var bin = bins[i];

      for (var j = 0,
          NbodiesInBin = bin.length; j != NbodiesInBin; j++) {
        var bi = bin[j];
        for (var k = 0; k != j; k++) {
          var bj = bin[k];
          if (Broadphase.canCollide(bi, bj) && this.boundingVolumeCheck(bi, bj)) {
            result.addAll([bi, bj]);
          }
        }
      }
    }
    return result;
  }
}
