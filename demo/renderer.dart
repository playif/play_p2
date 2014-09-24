library demo;

import "package:p2/p2.dart" as p2;
import "package:datgui/datgui.dart" as dat;
import "dart:html";
import "package:play_pixi/pixi.dart" as PIXI;
import "dart:math" as Math;
@MirrorsUsed(targets: const ['datgui', 'demo'], override: '*')
import "dart:mirrors";

part "webgl_renderer.dart";

abstract class Renderer extends p2.EventEmitter {
  dat.GUI gui;
  int state;
  List<p2.Body> bodies;
  List<p2.Spring> springs;
  num timeStep;
  num relaxation;
  num stiffness;
  p2.RevoluteConstraint mouseConstraint;
  p2.Body nullBody;
  num pickPrecision;

  bool useInterpolatedPositions;
  List<List> drawPoints;
  Map drawPointsChangeEvent;
  List drawCircleCenter;
  List drawCirclePoint;
  Map drawCircleChangeEvent;
  Map drawRectangleChangeEvent;
  List drawRectStart;
  List drawRectEnd;
  Map stateChangeEvent;

  num newShapeCollisionMask;
  num newShapeCollisionGroup;

  // If constraints should be drawn
  bool drawConstraints;

  num stats_sum;
  num stats_N;
  num stats_Nsummed;
  num stats_average;

  List addedGlobals;
  Map settings;

  p2.World world;

  HtmlElement element;
  DivElement elementContainer;

  Map scenes;

  Map currentScene;

  Renderer(Function scenes, {bool hideGUI: true}) {
    // Expose globally
    //window.app = this;

    var that = this;

//    if (scenes['setup']) {
//      // Only one scene given, without name
//      scenes = {
//        'default': scenes
//      };
//    } else if (scenes is Function) {
//      scenes = {
//        'default': {
//          'setup': scenes
//        }
//      };
//    }

    this.scenes = {
      'default': {
        'setup': scenes
      }
    };

    this.state = Renderer.DEFAULT;

    // Bodies to draw
    this.bodies = [];
    this.springs = [];
    this.timeStep = 1 / 60;
    this.relaxation = p2.Equation.DEFAULT_RELAXATION;
    this.stiffness = p2.Equation.DEFAULT_STIFFNESS;

    this.mouseConstraint = null;
    this.nullBody = new p2.Body();
    this.pickPrecision = 5;

    this.useInterpolatedPositions = false;

    this.drawPoints = [];
    this.drawPointsChangeEvent = {
      'type': "drawPointsChange"
    };
    this.drawCircleCenter = p2.vec2.create();
    this.drawCirclePoint = p2.vec2.create();
    this.drawCircleChangeEvent = {
      'type': "drawCircleChange"
    };
    this.drawRectangleChangeEvent = {
      'type': "drawRectangleChange"
    };
    this.drawRectStart = p2.vec2.create();
    this.drawRectEnd = p2.vec2.create();

    this.stateChangeEvent = {
      'type': "stateChange",
      state: null
    };


    // Default collision masks for new shapes
    this.newShapeCollisionMask = 1;
    this.newShapeCollisionGroup = 1;

    // If constraints should be drawn
    this.drawConstraints = false;

    this.stats_sum = 0;
    this.stats_N = 100;
    this.stats_Nsummed = 0;
    this.stats_average = -1;

    this.addedGlobals = [];

    this.settings = {
      'tool': Renderer.DEFAULT,
      'fullscreen': () {
        HtmlElement el = document.body;
        el.requestFullscreen();
      },

      'paused [p]': false,
      'manualStep [s]': () {
        that.world.step(that.world.lastTimeStep);
      },
      'fps': 60,
      'maxSubSteps': 3,
      'gravityX': 0,
      'gravityY': -10,
      'sleepMode': p2.World.NO_SLEEPING,

      'drawContacts [c]': false,
      'drawAABBs [t]': false,
      'drawConstraints': false,

      'iterations': 10,
      'stiffness': 1000000,
      'relaxation': 4,
      'tolerance': 0.01,
      'hideGUI': hideGUI
    };

    //this.init();

  }

  init() {
    this.resizeToFit();
    this.render();
    this.createStats();
//    this.addLogo();
    this.centerCamera(0, 0);

    window.onResize.listen((e) {
      resizeToFit();
    });

    this.setUpKeyboard();
    this.setupGUI();

//    if (!options.containsKey('hideGUI')) {
//      options['hideGUI'] = 'auto';
//    }

//    if ((options['hideGUI'] == 'auto' && window.innerWidth < 600) || options['hideGUI'] == true) {
//      this.gui.close();
//    }
    if (this.settings['hideGUI']) {
      this.gui.close();
    }

    this.printConsoleMessage();

    // Set first scene
    this.setSceneByIndex(0);

    this.startRenderingLoop();

    for (var key in Renderer.toolStateMap.keys) {
      Renderer.stateToolMap[Renderer.toolStateMap[key]] = key;
    }
  }

  render();

  centerCamera(num x, num y);

  static const int DEFAULT = 1;
  static const int PANNING = 2;
  static const int DRAGGING = 3;
  static const int DRAWPOLYGON = 4;
  static const int DRAWINGPOLYGON = 5;
  static const int DRAWCIRCLE = 6;
  static const int DRAWINGCIRCLE = 7;
  static const int DRAWRECTANGLE = 8;
  static const int DRAWINGRECTANGLE = 9;

  static Map toolStateMap = {
    'pick/pan [q]': Renderer.DEFAULT,
    'polygon [d]': Renderer.DRAWPOLYGON,
    'circle [a]': Renderer.DRAWCIRCLE,
    'rectangle [f]': Renderer.DRAWRECTANGLE
  };
  static Map stateToolMap = {};


  static Map keydownEvent = {
    'type': "keydown",
    'originalEvent': null,
    'keyCode': 0,
  };
  static Map keyupEvent = {
    'type': "keyup",
    'originalEvent': null,
    'keyCode': 0,
  };

  //Object.defineProperty(Renderer.prototype, 'drawContacts', {

  bool get drawContacts {
    return this.settings['drawContacts [c]'];
  }

  set drawContacts(bool value) {
    this.settings['drawContacts [c]'] = value;
    this.updateGUI();
  }

  //});

  //Object.defineProperty(Renderer.prototype, 'drawAABBs', {

  bool get drawAABBs {
    return this.settings['drawAABBs [t]'];
  }

  set drawAABBs(bool value) {
    this.settings['drawAABBs [t]'] = value;
    this.updateGUI();
  }

  //});

  //Object.defineProperty(Renderer.prototype, 'paused', {

  bool get paused {
    return this.settings['paused [p]'];
  }

  set paused(bool value) {
    this.settings['paused [p]'] = value;
    this.updateGUI();
  }

  //});

  double getDevicePixelRatio() {
    return window.devicePixelRatio;
  }

  printConsoleMessage() {
    window.console.log(['=== p2.js v' + p2.version + ' ===', 'Welcome to the p2.js debugging environment!', 'Did you know you can interact with the physics here in the console? Try executing the following:', '', '  world.gravity[1] = 10;', ''].join('\n'));
  }

  resizeToFit() {
    var dpr = this.getDevicePixelRatio();
    var rect = this.elementContainer.getBoundingClientRect();
    var w = rect.width * dpr;
    var h = rect.height * dpr;
    this.resize(w, h);
  }

  resize(num w, num h);

  /**
   * Sets up dat.gui
   */

  setupGUI() {
//    if(dat) == 'undefined'){
//      return;
//    }

    //var that = this;

    dat.GUI gui = this.gui = new dat.GUI();
    //gui.domElement.setAttribute('style', disableSelectionCSS.join(';'));

    Map settings = this.settings;

    gui.add(settings, 'tool', Renderer.toolStateMap).onChange((obj, state) {
      this.setState(int.parse(state));
    });
    gui.add(settings, 'fullscreen');

    // World folder
    dat.GUI worldFolder = gui.addFolder('World');
    worldFolder.open();
    worldFolder.add(settings, 'paused [p]').onChange((obj, p) {
      this.paused = p;
    });
    worldFolder.add(settings, 'manualStep [s]');
    worldFolder.add(settings, 'fps', 60, 60 * 10).step(60).onChange((obj, freq) {
      this.timeStep = 1 / freq;
    });
    worldFolder.add(settings, 'maxSubSteps', 0, 10).step(1);
    num maxg = 100;

    changeGravity(obj, value) {
      if (!(settings['gravityX'].isNaN) && !(settings['gravityY'].isNaN)) {
        p2.vec2.set(this.world.gravity, settings['gravityX'], settings['gravityY']);
      }
    }
    worldFolder.add(settings, 'gravityX', -maxg, maxg).onChange(changeGravity);
    worldFolder.add(settings, 'gravityY', -maxg, maxg).onChange(changeGravity);
    worldFolder.add(settings, 'sleepMode', {
      'NO_SLEEPING': p2.World.NO_SLEEPING,
      'BODY_SLEEPING': p2.World.BODY_SLEEPING,
      'ISLAND_SLEEPING': p2.World.ISLAND_SLEEPING,
    }).onChange((obj, mode) {
      this.world.sleepMode = int.parse(mode);
    });

    // Rendering
    var renderingFolder = gui.addFolder('Rendering');
    renderingFolder.open();
    renderingFolder.add(settings, 'drawContacts [c]').onChange((obj, draw) {
      this.drawContacts = draw;
    });
    renderingFolder.add(settings, 'drawAABBs [t]').onChange((obj, draw) {
      this.drawAABBs = draw;
    });

    // Solver
    var solverFolder = gui.addFolder('Solver');
    solverFolder.open();
    solverFolder.add(settings, 'iterations', 1, 100).step(1).onChange((obj, it) {
      this.world.solver.iterations = it;
    });
    solverFolder.add(settings, 'stiffness', 10).onChange((obj, k) {
      this.setEquationParameters();
    });
    solverFolder.add(settings, 'relaxation', 0, 20).step(0.1).onChange((obj, d) {
      this.setEquationParameters();
    });
    solverFolder.add(settings, 'tolerance', 0, 10).step(0.01).onChange((obj, t) {
      this.world.solver.tolerance = t;
    });

    // Scene picker
    dat.GUI sceneFolder = gui.addFolder('Scenes');
    sceneFolder.open();

    // Add scenes
    int i = 1;
    for (String sceneName in this.scenes.keys) {
      String guiLabel = sceneName + ' [' + (i++).toString() + ']';
      this.settings[guiLabel] = () {
        this.setScene(this.scenes[sceneName]);
      };
      sceneFolder.add(settings, guiLabel);
    }
  }

  /**
   * Updates dat.gui. Call whenever you change demo.settings.
   */

  updateGUI() {
    if (this.gui == null) {
      return;
    }

    updateControllers(dat.GUI folder) {
      // First level
      for (dat.Controller i in folder.controllers) {
        i.updateDisplay();
      }

      // Second level
      for (dat.GUI f in folder.folders) {
        updateControllers(f);
      }
    }
    updateControllers(this.gui);
  }

  setWorld(p2.World world) {
    this.world = world;

    //window.world = world; // For debugging.

    //var that = this;

    world.on("postStep", (Map e) {
      updateStats();
    }).on("addBody", (Map e) {
      addVisual(e['body']);
    }).on("removeBody", (Map e) {
      removeVisual(e['body']);
    }).on("addSpring", (Map e) {
      addVisual(e['spring']);
    }).on("removeSpring", (Map e) {
      removeVisual(e['spring']);
    });
  }



  /**
   * Sets the current scene to the scene definition given.
   * @param {object} sceneDefinition
   * @param {function} sceneDefinition.setup
   * @param {function} [sceneDefinition.teardown]
   */

  setScene(Map sceneDefinition) {
//    if (sceneDefinition is String) {
//      sceneDefinition = this.scenes[sceneDefinition];
//    }

    this.removeAllVisuals();
    if (this.currentScene != null && this.currentScene['teardown'] != null) {
      this.currentScene['teardown']();
    }
    if (this.world != null) {
      this.world.clear();
    }

//    for (var i = 0; i < this.addedGlobals.length; i++) {
//      delete window[this.addedGlobals];
//    }

    //var preGlobalVars = Object.keys(window);

    this.currentScene = sceneDefinition;
    this.world = null;
    sceneDefinition['setup'](this);
    if (this.world == null) {
      throw new Exception('The .setup function in the scene definition must run this.setWorld(world);');
    }

    //var postGlobalVars = Object.keys(window);
    var added = [];
//    for (var i = 0; i < postGlobalVars.length; i++) {
//      if (preGlobalVars.indexOf(postGlobalVars[i]) == -1 && postGlobalVars[i] != 'world') {
//        added.push(postGlobalVars[i]);
//      }
//    }
    if (added.length != 0) {
      added.sort();
      window.console.log(['The following variables were exposed globally from this physics scene.', '', '  ' + added.join(', '), ''].join('\n'));
    }

    this.addedGlobals = added;

    // Set the GUI parameters from the loaded world
    Map settings = this.settings;
    p2.GSSolver solver = world.solver;
    settings['iterations'] = solver.iterations;
    settings['tolerance'] = solver.tolerance;
    settings['gravityX'] = this.world.gravity[0];
    settings['gravityY'] = this.world.gravity[1];
    settings['sleepMode'] = this.world.sleepMode;
    this.updateGUI();
  }

  /**
   * Set scene by its position in which it was given. Starts at 0.
   * @param {number} index
   */

  setSceneByIndex(int index) {
    int i = 0;
    for (var key in this.scenes.keys) {
      if (i == index) {
        this.setScene(this.scenes[key]);
        break;
      }
      i++;
    }
  }

  static const String elementClass = 'p2-canvas';
  static const String containerClass = 'p2-container';

  /**
   * Adds all needed keyboard callbacks
   */

  setUpKeyboard() {
    var that = this;

    this.elementContainer.onKeyDown.listen((e) {
//      if (!e.keyCode) {
//        return;
//      }
      num s = that.state;
      String ch = new String.fromCharCode(e.keyCode);
      switch (ch) {
        case "P": // pause
          that.paused = !that.paused;
          break;
        case "S": // step
          that.world.step(that.world.lastTimeStep);
          break;
        case "R": // restart
          that.setScene(that.currentScene);
          break;
        case "C": // toggle draw contacts & constraints
          that.drawContacts = !that.drawContacts;
          that.drawConstraints = !that.drawConstraints;
          break;
        case "T": // toggle draw AABBs
          that.drawAABBs = !that.drawAABBs;
          break;
        case "D": // toggle draw polygon mode
          that.setState(s == Renderer.DRAWPOLYGON ? Renderer.DEFAULT : s = Renderer.DRAWPOLYGON);
          break;
        case "A": // toggle draw circle mode
          that.setState(s == Renderer.DRAWCIRCLE ? Renderer.DEFAULT : s = Renderer.DRAWCIRCLE);
          break;
        case "F": // toggle draw rectangle mode
          that.setState(s == Renderer.DRAWRECTANGLE ? Renderer.DEFAULT : s = Renderer.DRAWRECTANGLE);
          break;
        case "Q": // set default
          that.setState(Renderer.DEFAULT);
          break;
        case "1":
        case "2":
        case "3":
        case "4":
        case "5":
        case "6":
        case "7":
        case "8":
        case "9":
          that.setSceneByIndex(int.parse(ch) - 1);
          break;
        default:
          Renderer.keydownEvent['keyCode'] = e.keyCode;
          Renderer.keydownEvent['originalEvent'] = e;
          that.emit(Renderer.keydownEvent);
          break;
      }
      that.updateGUI();
    });

    this.elementContainer.onKeyUp.listen((e) {
      switch (new String.fromCharCode(e.keyCode)) {
        default:
          Renderer.keyupEvent['keyCode'] = e.keyCode;
          Renderer.keyupEvent['originalEvent'] = e;
          that.emit(Renderer.keyupEvent);
          break;
      }
    });
  }

  /**
   * Start the rendering loop
   */

  startRenderingLoop() {
    var demo = this,
        lastCallTime = new DateTime.now().millisecondsSinceEpoch / 1000;

    update(dt) {
      if (!demo.paused) {
        num now = new DateTime.now().millisecondsSinceEpoch / 1000,
            timeSinceLastCall = now - lastCallTime;
        lastCallTime = now;
        demo.world.step(demo.timeStep, timeSinceLastCall, demo.settings['maxSubSteps']);
      }
      demo.render();
      window.requestAnimationFrame(update);
    }
    window.requestAnimationFrame(update);
  }

  /**
   * Set the app state.
   * @param {number} state
   */

  setState(num state) {
    this.state = state;
    this.stateChangeEvent['state'] = state;
    this.emit(this.stateChangeEvent);
    if (Renderer.stateToolMap[state] != null) {
      this.settings['tool'] = state;
      this.updateGUI();
    }
  }

  /**
   * Should be called by subclasses whenever there's a mousedown event
   */

  handleMouseDown(List physicsPosition) {
    switch (this.state) {

      case Renderer.DEFAULT:

        // Check if the clicked point overlaps bodies
        List<p2.Body> result = this.world.hitTest(physicsPosition, this.world.bodies, this.pickPrecision);

        // Remove static bodies
        p2.Body b;
        while (result.length > 0) {
          b = result.removeAt(0);
          if (b.type == p2.Body.STATIC) {
            b = null;
          } else {
            break;
          }
        }

        if (b != null) {
          b.wakeUp();
          this.setState(Renderer.DRAGGING);
          // Add mouse joint to the body
          var localPoint = p2.vec2.create();
          b.toLocalFrame(localPoint, physicsPosition);
          this.world.addBody(this.nullBody);
          this.mouseConstraint = new p2.RevoluteConstraint(this.nullBody, b, localPivotA: physicsPosition, localPivotB: localPoint);
          this.world.addConstraint(this.mouseConstraint);
        } else {
          this.setState(Renderer.PANNING);
        }
        break;

      case Renderer.DRAWPOLYGON:
        // Start drawing a polygon
        this.setState(Renderer.DRAWINGPOLYGON);
        this.drawPoints = [];
        List copy = p2.vec2.create();
        p2.vec2.copy(copy, physicsPosition);
        this.drawPoints.add(copy);
        this.emit(this.drawPointsChangeEvent);
        break;

      case Renderer.DRAWCIRCLE:
        // Start drawing a circle
        this.setState(Renderer.DRAWINGCIRCLE);
        p2.vec2.copy(this.drawCircleCenter, physicsPosition);
        p2.vec2.copy(this.drawCirclePoint, physicsPosition);
        this.emit(this.drawCircleChangeEvent);
        break;

      case Renderer.DRAWRECTANGLE:
        // Start drawing a circle
        this.setState(Renderer.DRAWINGRECTANGLE);
        p2.vec2.copy(this.drawRectStart, physicsPosition);
        p2.vec2.copy(this.drawRectEnd, physicsPosition);
        this.emit(this.drawRectangleChangeEvent);
        break;
    }
  }

  /**
   * Should be called by subclasses whenever there's a mousedown event
   */

  handleMouseMove(physicsPosition) {
    var sampling = 0.4;
    switch (this.state) {
      case Renderer.DEFAULT:
      case Renderer.DRAGGING:
        if (this.mouseConstraint != null) {
          p2.vec2.copy(this.mouseConstraint.pivotA, physicsPosition);
          this.mouseConstraint.bodyA.wakeUp();
          this.mouseConstraint.bodyB.wakeUp();
        }
        break;

      case Renderer.DRAWINGPOLYGON:
        // drawing a polygon - add new point
        var sqdist = p2.vec2.dist(physicsPosition, this.drawPoints[this.drawPoints.length - 1]);
        if (sqdist > sampling * sampling) {
          var copy = [0, 0];
          p2.vec2.copy(copy, physicsPosition);
          this.drawPoints.add(copy);
          this.emit(this.drawPointsChangeEvent);
        }
        break;

      case Renderer.DRAWINGCIRCLE:
        // drawing a circle - change the circle radius point to current
        p2.vec2.copy(this.drawCirclePoint, physicsPosition);
        this.emit(this.drawCircleChangeEvent);
        break;

      case Renderer.DRAWINGRECTANGLE:
        // drawing a rectangle - change the end point to current
        p2.vec2.copy(this.drawRectEnd, physicsPosition);
        this.emit(this.drawRectangleChangeEvent);
        break;
    }
  }

  /**
   * Should be called by subclasses whenever there's a mouseup event
   */

  handleMouseUp(List physicsPosition) {

    p2.Body b;

    switch (this.state) {

      case Renderer.DEFAULT:
        break;

      case Renderer.DRAGGING:
        // Drop constraint
        this.world.removeConstraint(this.mouseConstraint);
        this.mouseConstraint = null;
        this.world.removeBody(this.nullBody);
        this.setState(Renderer.DEFAULT);
        break;

      case Renderer.PANNING:
        this.setState(Renderer.DEFAULT);
        break;

      case Renderer.DRAWINGPOLYGON:
        // End this drawing state
        this.setState(Renderer.DRAWPOLYGON);
        if (this.drawPoints.length > 3) {
          // Create polygon
          b = new p2.Body(mass: 1);
          if (b.fromPolygon(this.drawPoints, removeCollinearPoints: 0.01)) {
            this.world.addBody(b);
          }
        }
        this.drawPoints = [];
        this.emit(this.drawPointsChangeEvent);
        break;

      case Renderer.DRAWINGCIRCLE:
        // End this drawing state
        this.setState(Renderer.DRAWCIRCLE);
        var R = p2.vec2.dist(this.drawCircleCenter, this.drawCirclePoint);
        if (R > 0) {
          // Create circle
          b = new p2.Body(mass: 1, position: this.drawCircleCenter);
          var circle = new p2.Circle(R);
          b.addShape(circle);
          this.world.addBody(b);
        }
        p2.vec2.copy(this.drawCircleCenter, this.drawCirclePoint);
        this.emit(this.drawCircleChangeEvent);
        break;

      case Renderer.DRAWINGRECTANGLE:
        // End this drawing state
        this.setState(Renderer.DRAWRECTANGLE);
        // Make sure first point is upper left
        var start = this.drawRectStart;
        var end = this.drawRectEnd;
        for (var i = 0; i < 2; i++) {
          if (start[i] > end[i]) {
            var tmp = end[i];
            end[i] = start[i];
            start[i] = tmp;
          }
        }
        var width = (start[0] - end[0]).abs();
        var height = (start[1] - end[1]).abs();
        if (width > 0 && height > 0) {
          // Create box
          b = new p2.Body(mass: 1, position: [this.drawRectStart[0] + width * 0.5, this.drawRectStart[1] + height * 0.5]);
          var rectangleShape = new p2.Rectangle(width, height);
          b.addShape(rectangleShape);
          this.world.addBody(b);
        }
        p2.vec2.copy(this.drawRectEnd, this.drawRectStart);
        this.emit(this.drawRectangleChangeEvent);
        break;
    }

    if (b != null) {
      b.wakeUp();
      for (var i = 0; i < b.shapes.length; i++) {
        var s = b.shapes[i];
        s.collisionMask = this.newShapeCollisionMask;
        s.collisionGroup = this.newShapeCollisionGroup;
      }
    }
  }

  /**
   * Update stats
   */

  updateStats() {
    this.stats_sum += this.world.lastStepTime;
    this.stats_Nsummed++;
    if (this.stats_Nsummed == this.stats_N) {
      this.stats_average = this.stats_sum / this.stats_N;
      this.stats_sum = 0.0;
      this.stats_Nsummed = 0;
    }
    /*
    this.stats_stepdiv.innerHTML = "Physics step: "+(Math.round(this.stats_average*100)/100)+"ms";
    this.stats_contactsdiv.innerHTML = "Contacts: "+this.world.narrowphase.contactEquations.length;
    */
  }

  /**
   * Add an object to the demo
   * @param  {mixed} obj Either Body or Spring
   */

  addVisual(obj) {
    if (obj is p2.LinearSpring) {
      this.springs.add(obj);
      this.addRenderable(obj);
    } else if (obj is p2.Body) {
      if (obj.shapes.length != 0) {
        // Only draw things that can be seen
        this.bodies.add(obj);
        this.addRenderable(obj);
      }
    }
  }

  addRenderable(obj);
  removeRenderable(obj);

  /**
   * Removes all visuals from the scene
   */

  removeAllVisuals() {
    var bodies = this.bodies,
        springs = this.springs;
    while (bodies.length != 0) {
      this.removeVisual(bodies[bodies.length - 1]);
    }
    while (springs.isNotEmpty) {
      this.removeVisual(springs[springs.length - 1]);
    }
  }

  /**
   * Remove an object from the demo
   * @param  {mixed} obj Either Body or Spring
   */

  removeVisual(obj) {
    this.removeRenderable(obj);
    if (obj is p2.LinearSpring) {
      var idx = this.springs.indexOf(obj);
      if (idx != -1) {
        this.springs.removeAt(idx);
      }
    } else if (obj is p2.Body) {
      var idx = this.bodies.indexOf(obj);
      if (idx != -1) {
        this.bodies.removeAt(idx);
      }
    } else {
      window.console.error("Visual type not recognized...");
    }
  }

  /**
   * Create the container/divs for stats
   * @todo  integrate in new menu
   */

  createStats() {
    /*
    var stepDiv = document.createElement("div");
    var vecsDiv = document.createElement("div");
    var matsDiv = document.createElement("div");
    var contactsDiv = document.createElement("div");
    stepDiv.setAttribute("id","step");
    vecsDiv.setAttribute("id","vecs");
    matsDiv.setAttribute("id","mats");
    contactsDiv.setAttribute("id","contacts");
    document.body.appendChild(stepDiv);
    document.body.appendChild(vecsDiv);
    document.body.appendChild(matsDiv);
    document.body.appendChild(contactsDiv);
    this.stats_stepdiv = stepDiv;
    this.stats_contactsdiv = contactsDiv;
    */
  }

//  Renderer.prototype.addLogo = function(){
//    var css = [
//        'position:absolute',
//        'left:10px',
//        'top:15px',
//        'text-align:center',
//        'font: 13px Helvetica, arial, freesans, clean, sans-serif',
//    ].concat(disableSelectionCSS);
//
//    var div = document.createElement('div');
//    div.innerHTML = [
//        "<div style='"+css.join(';')+"' user-select='none'>",
//        "<h1 style='margin:0px'><a href='http://github.com/schteppe/p2.js' style='color:black; text-decoration:none;'>p2.js</a></h1>",
//        "<p style='margin:5px'>Physics Engine</p>",
//        '<a style="color:black; text-decoration:none;" href="https://twitter.com/share" class="twitter-share-button" data-via="schteppe" data-count="none" data-hashtags="p2js">Tweet</a>',
//        "</div>"
//    ].join("");
//    this.elementContainer.appendChild(div);
//
//    // Twitter button script
//    !function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+'://platform.twitter.com/widgets.js';fjs.parentNode.insertBefore(js,fjs);}}(document, 'script', 'twitter-wjs');
//};

  static Map zoomInEvent = {
    'type': "zoomin"
  };
  static Map zoomOutEvent = {
    'type': "zoomout"
  };

  setEquationParameters() {
    this.world.setGlobalEquationParameters(stiffness: this.settings['stiffness'], relaxation: this.settings['relaxation']);
  }

}
