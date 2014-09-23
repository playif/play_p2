part of p2;

/**
 * Base constraint class.
 */
abstract class Constraint {
  /// The type of constraint. May be one of Constraint.DISTANCE, Constraint.GEAR, Constraint.LOCK, Constraint.PRISMATIC or Constraint.REVOLUTE.
  int type;

  /// Equations to be solved in this constraint
  List<Equation> equations;

  /// First body participating in the constraint.
  Body bodyA;

  /// Second body participating in the constraint.
  Body bodyB;


  /// Set to true if you want the connected bodies to collide.
  bool collideConnected;

  Constraint(Body bodyA, Body bodyB, num type, {bool collideConnected: true, bool wakeUpBodies: true}) {


    this.type = type;

//    options = Utils.defaults(options, {
//        collideConnected : true,
//        wakeUpBodies : true,
//    });

    this.equations = [];

    this.bodyA = bodyA;

    this.bodyB = bodyB;

    this.collideConnected = collideConnected;

    // Wake up bodies when connected
    if (wakeUpBodies) {
      if (bodyA != null) {
        bodyA.wakeUp();
      }
      if (bodyB != null) {
        bodyB.wakeUp();
      }
    }
  }


  /// Updates the internal constraint parameters before solve.
  update() {
    throw new Exception("method update() not implmemented in this Constraint subclass!");
  }

  static const int DISTANCE = 1;

  static const int GEAR = 2;

  static const int LOCK = 3;

  static const int PRISMATIC = 4;

  static const int REVOLUTE = 5;

  /// Set stiffness for this constraint.
  setStiffness(num stiffness) {
    List<Equation> eqs = this.equations;
    for (int i = 0; i != eqs.length; i++) {
      Equation eq = eqs[i];
      eq.stiffness = stiffness;
      eq.needsUpdate = true;
    }
  }

  /// Set relaxation for this constraint.
  setRelaxation(num relaxation) {
    List<Equation> eqs = this.equations;
    for (int i = 0; i != eqs.length; i++) {
      Equation eq = eqs[i];
      eq.relaxation = relaxation;
      eq.needsUpdate = true;
    }
  }

}
