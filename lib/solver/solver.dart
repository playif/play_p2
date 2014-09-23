part of p2;

/// Base class for constraint solvers.
abstract class Solver extends EventEmitter{

  num type;

  /// Current equations in the solver.
  List<Equation> equations;

  /// Function that is used to sort all equations before each solve.
  Function equationSortFunction;

  Solver(int type,{Function equationSortFunction}) : super() {
    //options = options || {};

    //EventEmitter.call(this);

    this.type = type;

    this.equations = [];

    this.equationSortFunction = equationSortFunction;
  }

  /**
   * Method to be implemented in each subclass
   * @method solve
   * @param  {Number} dt
   * @param  {World} world
   */
  solve (dt,world){
    throw new Exception("Solver.solve should be implemented by subclasses!");
  }

  World mockWorld = new World(fake:true);

  /**
   * Solves all constraints in an island.
   * @method solveIsland
   * @param  {Number} dt
   * @param  {Island} island
   */
  solveIsland (dt,island){

    this.removeAllEquations();

    if(island.equations.length != null){
      // Add equations to solver
      this.addEquations(island.equations);
      mockWorld.bodies.clear();
      island.getBodies(mockWorld.bodies);

      // Solve
      if(mockWorld.bodies.isNotEmpty){
        this.solve(dt,mockWorld);
      }
    }
  }

  /**
   * Sort all equations using the .equationSortFunction. Should be called by subclasses before solving.
   * @method sortEquations
   */
  sortEquations(){
    if(this.equationSortFunction != null){
      this.equations.sort(this.equationSortFunction);
    }
  }

  /**
   * Add an equation to be solved.
   *
   * @method addEquation
   * @param {Equation} eq
   */
  addEquation (Equation eq){
    if(eq.enabled){
      this.equations.add(eq);
    }
  }

  /**
   * Add equations. Same as .addEquation, but this time the argument is an array of Equations
   *
   * @method addEquations
   * @param {Array} eqs
   */
  addEquations (List<Equation> eqs){
    //Utils.appendArray(this.equations,eqs);
    for(var i=0, N=eqs.length; i!=N; i++){
      Equation eq = eqs[i];
      if(eq.enabled){
        this.equations.add(eq);
      }
    }
  }

  /// Remove an equation.
  removeEquation (Equation eq){
    var i = this.equations.indexOf(eq);
    if(i != -1){
      this.equations.removeAt(i);
    }
  }

  /**
   * Remove all currently added equations.
   *
   * @method removeAllEquations
   */
  removeAllEquations(){
    this.equations.clear();
  }

  static const int GS = 1;
  static const int ISLAND = 2;
}
