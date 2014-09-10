part of p2;

/// Holds a body and keeps track of some additional properties needed for graph traversal.
class IslandNode {
  /// The body that is contained in this node.
  Body body;

  /// Neighboring IslandNodes
  List<IslandNode> neighbors;

  /// Equations connected to this node.
  List<Equation> equations;

  /// If this node was visiting during the graph traversal.
  bool visited;

  IslandNode(Body body) {
    this.body = body;
    this.neighbors = [];
    this.equations = [];
    this.visited = false;
  }

  /// Clean this node from bodies and equations.

  reset() {
    this.equations.clear();
    this.neighbors.clear();
    this.visited = false;
    this.body = null;
  }
}
