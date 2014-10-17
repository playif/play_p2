part of p2;

/// Holds a body and keeps track of some additional properties needed for graph traversal.
class IslandNode {
  /// The body that is contained in this node.
  Body body;

  /// Neighboring IslandNodes
  final List<IslandNode> neighbors = new List<IslandNode>();

  /// Equations connected to this node.
  final List<Equation> equations= new List<Equation>();

  /// If this node was visiting during the graph traversal.
  bool visited = false;

  IslandNode(Body body) {
    this.body = body;
  }

  /// Clean this node from bodies and equations.

  reset() {
    this.equations.clear();
    this.neighbors.clear();
    this.visited = false;
    this.body = null;
  }
}
