part of p2;

/// Splits the system of bodies and equations into independent islands
class IslandManager {
  List<IslandNode> _nodePool = [];
  List<Island> _islandPool = [];

  /// The equations to split. Manually fill this array before running .split().
  List<Equation> equations = [];

  /**
   * The resulting {{#crossLink "Island"}}{{/crossLink}}s.
   * @property {Array} islands
   */
  List<Island> islands;

  /// The resulting graph nodes.
  List<IslandNode> nodes;

  /// The node queue, used when traversing the graph of nodes.
  List<IslandNode> queue;

  IslandManager() {
    // Pooling of node objects saves some GC load
    this._nodePool = [];
    this._islandPool = [];

    /**
     * The equations to split. Manually fill this array before running .split().
     * @property {Array} equations
     */
    this.equations = [];

    /**
     * The resulting {{#crossLink "Island"}}{{/crossLink}}s.
     * @property {Array} islands
     */
    this.islands = [];

    /**
     * The resulting graph nodes.
     * @property {Array} nodes
     */
    this.nodes = [];

    /**
     * The node queue, used when traversing the graph of nodes.
     * @private
     * @property {Array} queue
     */
    this.queue = [];
  }

  /**
   * Get an unvisited node from a list of nodes.
   * @static
   * @method getUnvisitedNode
   * @param  {Array} nodes
   * @return {IslandNode|boolean} The node if found, else false.
   */

  static IslandNode getUnvisitedNode(List<IslandNode> nodes) {
    var Nnodes = nodes.length;
    for (var i = 0; i != Nnodes; i++) {
      var node = nodes[i];
      if (!node.visited && node.body.type == Body.DYNAMIC) {
        return node;
      }
    }
    return null;
  }

  /**
   * Visit a node.
   * @method visit
   * @param  {IslandNode} node
   * @param  {Array} bds
   * @param  {Array} eqs
   */

  visit(IslandNode node, List bds, List eqs) {
    bds.add(node.body);
    var Neqs = node.equations.length;
    for (var i = 0; i != Neqs; i++) {
      var eq = node.equations[i];
      if (eqs.indexOf(eq) == -1) {
        // Already added?
        eqs.add(eq);
      }
    }
  }

  /**
   * Runs the search algorithm, starting at a root node. The resulting bodies and equations will be stored in the provided arrays.
   * @method bfs
   * @param  {IslandNode} root The node to start from
   * @param  {Array} bds  An array to append resulting Bodies to.
   * @param  {Array} eqs  An array to append resulting Equations to.
   */

  bfs(IslandNode root, List bds, List eqs) {

    // Reset the visit queue
    //var queue = this.queue;
    queue.clear();

    // Add root node to queue
    queue.add(root);
    root.visited = true;
    this.visit(root, bds, eqs);

    // Process all queued nodes
    while (queue.isNotEmpty) {

      // Get next node in the queue
      IslandNode node = queue.removeLast();

      // Visit unvisited neighboring nodes
      IslandNode child;
      while ((child = IslandManager.getUnvisitedNode(node.neighbors)) != null) {
        child.visited = true;
        this.visit(child, bds, eqs);

        // Only visit the children of this node if it's dynamic
        if (child.body.type == Body.DYNAMIC) {
          queue.add(child);
        }
      }
    }
  }

  /**
   * Split the world into independent islands. The result is stored in .islands.
   * @method split
   * @param  {World} world
   * @return {Array} The generated islands
   */

  List<Island> split(World world) {
    var bodies = world.bodies;
    //nodes = this.nodes,
    //equations = this.equations;

    // Move old nodes to the node pool
    while (nodes.isNotEmpty) {
      this._nodePool.add(nodes.removeLast());
    }

    // Create needed nodes, reuse if possible
    for (int i = 0; i != bodies.length; i++) {
      if (this._nodePool.isNotEmpty) {
        IslandNode node = this._nodePool.removeLast();
        node.reset();
        node.body = bodies[i];
        nodes.add(node);
      } else {
        nodes.add(new IslandNode(bodies[i]));
      }
    }

    // Add connectivity data. Each equation connects 2 bodies.
    for (int k = 0; k != equations.length; k++) {
      var eq = equations[k],
      i = bodies.indexOf(eq.bodyA),
      j = bodies.indexOf(eq.bodyB),
      ni = nodes[i],
      nj = nodes[j];
      ni.neighbors.add(nj);
      nj.neighbors.add(ni);
      ni.equations.add(eq);
      nj.equations.add(eq);
    }

    // Move old islands to the island pool
    //var islands = this.islands;
    while (islands.isNotEmpty) {
      Island island = islands.removeLast();
      island.reset();
      this._islandPool.add(island);
    }

    // Get islands
    var child;
    while ((child = IslandManager.getUnvisitedNode(nodes)) != null) {

      // Create new island
      Island island = this._islandPool.length ? this._islandPool.removeLast() : new Island();

      // Get all equations and bodies in this island
      this.bfs(child, island.bodies, island.equations);

      islands.add(island);
    }

    return islands;
  }
}
