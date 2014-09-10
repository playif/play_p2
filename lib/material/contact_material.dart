part of p2;

class ContactMaterial {
  /// The contact material identifier
  num id;

  /// First material participating in the contact material
  Material materialA;

  /// Second material participating in the contact material
  Material materialB;

  /// Friction to use in the contact of these two materials
  num friction;

  /// Restitution to use in the contact of these two materials
  num restitution;

  /// Stiffness of the resulting ContactEquation that this ContactMaterial generate
  num stiffness;

  /// Relaxation of the resulting ContactEquation that this ContactMaterial generate
  num relaxation;

  /// Stiffness of the resulting FrictionEquation that this ContactMaterial generate
  num frictionStiffness;

  /// Relaxation of the resulting FrictionEquation that this ContactMaterial generate
  num frictionRelaxation;

  /// Will add surface velocity to this material. If bodyA rests on top if bodyB, and the surface velocity is positive, bodyA will slide to the right.
  num surfaceVelocity;

  /// Offset to be set on ContactEquations. A positive value will make the bodies penetrate more into each other. Can be useful in scenes where contacts need to be more persistent, for example when stacking. Aka "cure for nervous contacts".
  num contactSkinSize;


  static num idCounter = 0;

  ContactMaterial(Material materialA, Material materialB, [options]) {

    this.id = ContactMaterial.idCounter++;

    this.materialA = materialA;

    this.materialB = materialB;

    this.friction = options.friction != null ? options.friction : 0.3;

    this.restitution = options.restitution != null ? options.restitution : 0.0;

    this.stiffness = options.stiffness != null ? options.stiffness : Equation.DEFAULT_STIFFNESS;

    this.relaxation = options.relaxation != null ? options.relaxation : Equation.DEFAULT_RELAXATION;

    this.frictionStiffness = options.frictionStiffness != null ? options.frictionStiffness : Equation.DEFAULT_STIFFNESS;

    this.frictionRelaxation = options.frictionRelaxation != null ? options.frictionRelaxation : Equation.DEFAULT_RELAXATION;

    this.surfaceVelocity = options.surfaceVelocity != null ? options.surfaceVelocity : 0;

    this.contactSkinSize = 0.005;
  }
}
