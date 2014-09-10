library p2;



import "dart:typed_data";
import "dart:math";
import "poly_decomp/index.dart" as decomp;


part "collision/aabb.dart";
part "collision/broadphase.dart";
part "collision/grid_broadphase.dart";
part "collision/naive_broadphase.dart";
part "collision/narrowphase.dart";
part "collision/sap_broadphase.dart";


part "constraint/constraint.dart";
part "constraint/distance_constraint.dart";
part "constraint/gear_constraint.dart";
part "constraint/lock_constraint.dart";
part "constraint/prismatic_constraint.dart";
part "constraint/revolute_constraint.dart";


part "equations/angle_lock_equation.dart";
part "equations/contact_equation.dart";
part "equations/equation.dart";
part "equations/friction_equation.dart";
part "equations/rotational_lock_equation.dart";
part "equations/rotational_velocity_equation.dart";


part "events/event_emitter.dart";


part "material/material.dart";
part "material/contact_material.dart";


part "math/polyk.dart";
part "math/vec2.dart";


part "object/body.dart";
part "object/linear_spring.dart";
part "object/rotational_spring.dart";
part "object/spring.dart";


part "shapes/capsule.dart";
part "shapes/circle.dart";
part "shapes/convex.dart";
part "shapes/heightfield.dart";
part "shapes/line.dart";
part "shapes/particle.dart";
part "shapes/plane.dart";
part "shapes/rectangle.dart";
part "shapes/shape.dart";


part "solver/gssolver.dart";
part "solver/solver.dart";


part "utils/overlap_keeper.dart";
part "utils/tuple_dictionary.dart";
part "utils/utils.dart";


part "world/island.dart";
part "world/island_manager.dart";
part "world/island_node.dart";
part "world/world.dart";



