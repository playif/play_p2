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

  ContactMaterial(Material materialA, Material materialB, {num friction: 0.3, num restitution: 0, num stiffness:Equation.DEFAULT_STIFFNESS, num relaxation:Equation.DEFAULT_RELAXATION, num frictionStiffness:Equation.DEFAULT_STIFFNESS, num frictionRelaxation:Equation.DEFAULT_RELAXATION, num surfaceVelocity: 0}) {

    this.id = ContactMaterial.idCounter++;

    this.materialA = materialA;

    this.materialB = materialB;

    this.friction = friction ;

    this.restitution = restitution;

    this.stiffness = stiffness;

    this.relaxation = relaxation;

    this.frictionStiffness = frictionStiffness;

    this.frictionRelaxation = frictionRelaxation;

    this.surfaceVelocity = surfaceVelocity;

    this.contactSkinSize = 0.005;
  }
}
