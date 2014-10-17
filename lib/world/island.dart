part of p2;

class Island {
  /// Current equations in this island.
  List<Equation> equations;

  /// Current bodies in this island.
  List<Body> bodies;

  Island() {
    this.equations = new List<Equation>();
    this.bodies = new List<Body>();
  }

  /// Clean this island from bodies and equations.

  reset() {
    this.equations.clear();
    this.bodies.clear();
  }

  List<int> bodyIds = new List<int>();

  /// Get all unique bodies in this island.

  List<Body> getBodies(List<Body> result) {
    List<Body> bodies = result == null ? new List<Body>() : result;
    List<Equation> eqs = this.equations;
    bodyIds.clear();
    
    for (int i = 0; i != eqs.length; i++) {
      Equation eq = eqs[i];
      if (!bodyIds.contains(eq.bodyA.id)) {
        bodies.add(eq.bodyA);
        bodyIds.add(eq.bodyA.id);
      }
      if (!bodyIds.contains(eq.bodyB.id)) {
        bodies.add(eq.bodyB);
        bodyIds.add(eq.bodyB.id);
      }
    }
    return bodies;
  }

  /**
   * Check if the entire island wants to sleep.
   * @method wantsToSleep
   * @return {Boolean}
   */

  bool wantsToSleep() {
    for (int i = 0; i < this.bodies.length; i++) {
      Body b = this.bodies[i];
      if (b.type == Body.DYNAMIC && !b.wantsToSleep) {
        return false;
      }
    }
    return true;
  }

  /// Make all bodies in the island sleep.

  bool sleep() {
    for (int i = 0; i < this.bodies.length; i++) {
      Body b = this.bodies[i];
      b.sleep();
    }
    return true;
  }
}
