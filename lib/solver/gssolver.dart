part of p2;

class GSSolver extends Solver {

  /// The number of iterations to do when solving. More gives better results, but is more expensive.
  int iterations;


  /// The error tolerance, per constraint. If the total error is below this limit, the solver will stop iterating. Set to zero for as good solution as possible, but to something larger than zero to make computations faster.
  num tolerance;

  int arrayStep;
  List lambda;
  List Bs;
  List invCs;

  /// Set to true to set all right hand side terms to zero when solving. Can be handy for a few applications.
  bool useZeroRHS;

  /// Number of solver iterations that are done to approximate normal forces. When these iterations are done, friction force will be computed from the contact normal forces. These friction forces will override any other friction forces set from the World for example.
  int frictionIterations;

  /// The number of iterations that were made during the last solve. If .tolerance is zero, this value will always be equal to .iterations, but if .tolerance is larger than zero, and the solver can quit early, then this number will be somewhere between 1 and .iterations.
  int usedIterations;

  GSSolver({num iterations: 10, num tolerance: 0.01}) : super(Solver.GS) {
    this.iterations = iterations;

    this.tolerance = tolerance;

    this.arrayStep = 30;
    this.lambda = new Float32List(this.arrayStep);
    this.Bs = new Float32List(this.arrayStep);
    this.invCs = new Float32List(this.arrayStep);

    this.useZeroRHS = false;

    this.frictionIterations = 0;

    this.usedIterations = 0;
  }

  setArrayZero(List array) {
    int l = array.length;
    while (l-- > 0) {
      array[l] = 0.0;
    }
  }

  /**
   * Solve the system of equations
   * @method solve
   * @param  {Number}  h       Time step
   * @param  {World}   world    World to solve
   */
  solve(num h, World world) {

    this.sortEquations();

    var iter = 0,
        maxIter = this.iterations,
        maxFrictionIter = this.frictionIterations,
        equations = this.equations,
        Neq = equations.length,
        tolSquared = pow(this.tolerance * Neq, 2),
        bodies = world.bodies,
        Nbodies = world.bodies.length,
        add = vec2.add,
        set = vec2.set,
        useZeroRHS = this.useZeroRHS,
        lambda = this.lambda;

    this.usedIterations = 0;

    if (Neq != 0) {
      for (var i = 0; i != Nbodies; i++) {
        var b = bodies[i];

        // Update solve mass
        b.updateSolveMassProperties();
      }
    }

    // Things that does not change during iteration can be computed once
    if (lambda.length < Neq) {
      lambda = this.lambda = new Float32List(Neq + this.arrayStep);
      this.Bs = new Float32List(Neq + this.arrayStep);
      this.invCs = new Float32List(Neq + this.arrayStep);
    }
    setArrayZero(lambda);
    var invCs = this.invCs,
        Bs = this.Bs;
    lambda = this.lambda;

    for (var i = 0; i != equations.length; i++) {
      Equation c = equations[i];
      if (c.timeStep != h || c.needsUpdate) {
        c.timeStep = h;
        c.update();
      }
      Bs[i] = c.computeB(c.a, c.b, h);
      invCs[i] = c.computeInvC(c.epsilon);
    }

    var q, B, c, deltalambdaTot, i, j;

    if (Neq != 0) {

      for (i = 0; i != Nbodies; i++) {
        var b = bodies[i];

        // Reset vlambda
        b.resetConstraintVelocity();
      }

      if (maxFrictionIter != 0) {
        // Iterate over contact equations to get normal forces
        for (iter = 0; iter != maxFrictionIter; iter++) {

          // Accumulate the total error for each iteration.
          deltalambdaTot = 0.0;

          for (j = 0; j != Neq; j++) {
            c = equations[j];

            num deltalambda = GSSolver.iterateEquation(j, c, c.epsilon, Bs, invCs, lambda, useZeroRHS, h, iter);
            deltalambdaTot += (deltalambda).abs();
          }

          this.usedIterations++;

          // If the total error is small enough - stop iterate
          if (deltalambdaTot * deltalambdaTot <= tolSquared) {
            break;
          }
        }

        GSSolver.updateMultipliers(equations, lambda, 1 / h);

        // Set computed friction force
        for (j = 0; j != Neq; j++) {
          Equation eq = equations[j];
          if (eq is FrictionEquation) {
            var f = 0.0;
            for (var k = 0; k != eq.contactEquations.length; k++) {
              f += eq.contactEquations[k].multiplier;
            }
            f *= eq.frictionCoefficient / eq.contactEquations.length;
            eq.maxForce = f;
            eq.minForce = -f;
          }
        }
      }

      // Iterate over all equations
      for (iter = 0; iter != maxIter; iter++) {

        // Accumulate the total error for each iteration.
        deltalambdaTot = 0.0;

        for (j = 0; j != Neq; j++) {
          c = equations[j];

          var deltalambda = GSSolver.iterateEquation(j, c, c.epsilon, Bs, invCs, lambda, useZeroRHS, h, iter);
          deltalambdaTot += (deltalambda).abs();
        }

        this.usedIterations++;

        // If the total error is small enough - stop iterate
        if (deltalambdaTot * deltalambdaTot <= tolSquared) {
          break;
        }
      }

      // Add result to velocity
      for (i = 0; i != Nbodies; i++) {
        bodies[i].addConstraintVelocity();
      }

      GSSolver.updateMultipliers(equations, lambda, 1 / h);
    }
  }

// Sets the .multiplier property of each equation
  static updateMultipliers(equations, lambda, invDt) {
    // Set the .multiplier property of each equation
    var l = equations.length;
    while (l-- > 0) {
      equations[l].multiplier = lambda[l] * invDt;
    }
  }

  static num iterateEquation(j, eq, eps, Bs, invCs, lambda, useZeroRHS, dt, iter) {
    // Compute iteration
    var B = Bs[j],
        invC = invCs[j],
        lambdaj = lambda[j],
        GWlambda = eq.computeGWlambda();

    num maxForce = eq.maxForce,
        minForce = eq.minForce;

    if (useZeroRHS) {
      B = 0;
    }

    num deltalambda = invC * (B - GWlambda - eps * lambdaj);

    // Clamp if we are not within the min/max interval
    num lambdaj_plus_deltalambda = lambdaj + deltalambda;
    if (lambdaj_plus_deltalambda < minForce * dt) {
      deltalambda = minForce * dt - lambdaj;
    } else if (lambdaj_plus_deltalambda > maxForce * dt) {
      deltalambda = maxForce * dt - lambdaj;
    }
    lambda[j] += deltalambda;
    eq.addToWlambda(deltalambda);

    return deltalambda;
  }
}
