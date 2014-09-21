import "renderer.dart";
import "package:play_p2/p2.dart" as p2;
import "package:play_pixi/pixi.dart" as PIXI;
import "dart:math" as Math;
import "dart:html";

//typedef FrameFunc(num dt);
class WebGLRenderer extends Renderer {
  num lineWidth;
  num scrollFactor;
  num sleepOpacity;
  List<PIXI.Graphics> sprites;
  List<PIXI.Graphics> springSprites;
  bool debugPolygons;
  PIXI.Graphics drawShapeGraphics;
  PIXI.Renderer renderer;
  PIXI.DisplayObjectContainer stage;
  PIXI.Stage container;



  PIXI.Graphics contactGraphics;
  PIXI.Graphics aabbGraphics;



  num w,h;

  WebGLRenderer(scenes, [Map options=const {
  }]) : super(scenes, options) {
    //options = options || {};

    //var that = this;

    var settings = {
        'lineWidth' : 0.01,
        'scrollFactor' : 0.1,
        'width' : 1280, // Pixi screen resolution
        'height' : 720,
        'useDeviceAspect' : false,
        'sleepOpacity' : 0.2,
    };

    for (var key in options.keys) {
      settings[key] = options[key];
    }

    if (settings.useDeviceAspect) {
      settings.height = window.innerHeight / window.innerWidth * settings.width;
    }

    //this.settings = settings;
    this.lineWidth = settings.lineWidth;
    this.scrollFactor = settings.scrollFactor;
    this.sleepOpacity = settings.sleepOpacity;

    this.sprites = [];
    this.springSprites = [];
    this.debugPolygons = false;

    //Renderer.call(this, scenes, options);

    for (var key in settings) {
      this.settings[key] = settings[key];
    }

    this.pickPrecision = 0.1;

    // Update "ghost draw line"
    this.on("drawPointsChange", (e) {
      var g = this.drawShapeGraphics;
      var path = this.drawPoints;

      g.clear();

      var path2 = [];
      for (var j = 0; j < path.length; j++) {
        var v = path[j];
        path2.push([v[0], v[1]]);
      }

      this.drawPath(g, path2, 0xff0000, null, this.lineWidth, false);
    });

    // Update draw circle
    this.on("drawCircleChange", (e) {
      var g = this.drawShapeGraphics;
      g.clear();
      var center = this.drawCircleCenter;
      var R = p2.vec2.dist(center, this.drawCirclePoint);
      this.drawCircle(g, center[0], center[1], 0, R, null, this.lineWidth);
    });

    // Update draw circle
    this.on("drawRectangleChange", (e) {
      var g = this.drawShapeGraphics;
      g.clear();
      var start = this.drawRectStart;
      var end = this.drawRectEnd;
      var width = start[0] - end[0];
      var height = start[1] - end[1];
      this.drawRectangle(g, start[0] - width / 2, start[1] - height / 2, 0, width, height, null, false, this.lineWidth, false);
    });
  }

  stagePositionToPhysics(out, stagePosition) {
    var x = stagePosition[0],
    y = stagePosition[1];
    p2.vec2.set(out, x, y);
    return out;
  }

  /**
   * Initialize the renderer and stage
   */
  var init_stagePosition = p2.vec2.create(),
  init_physicsPosition = p2.vec2.create();

  init() {
    var w = this.w,
    h = this.h,
    s = this.settings;

    var that = this;

    PIXI.Renderer renderer = this.renderer = PIXI.autoDetectRenderer(s.width, s.height, null, null, true);
    PIXI.DisplayObjectContainer stage = this.stage = new PIXI.DisplayObjectContainer();
    PIXI.Stage container = this.container = new PIXI.Stage(0xFFFFFF, true);

    var el = this.element = this.renderer.view;
    el.tabIndex = 1;
    el.classList.add(Renderer.elementClass);
    el.setAttribute('style', 'width:100%;');

    var div = this.elementContainer = new DivElement();
    div.classList.add(Renderer.containerClass);
    div.setAttribute('style', 'width:100%; height:100%');
    div.appendChild(el);
    document.body.append(div);
    el.focus();
    el.oncontextmenu = (e) {
      return false;
    };

    this.container.addChild(stage);

    // Graphics object for drawing shapes
    this.drawShapeGraphics = new PIXI.Graphics();
    stage.addChild(this.drawShapeGraphics);

    // Graphics object for contacts
    this.contactGraphics = new PIXI.Graphics();
    stage.addChild(this.contactGraphics);

    // Graphics object for AABBs
    this.aabbGraphics = new PIXI.Graphics();
    stage.addChild(this.aabbGraphics);

    stage.scale.x = 200; // Flip Y direction.
    stage.scale.y = -200;

    var lastX, lastY, lastMoveX, lastMoveY, startX, startY, down = false;

    var physicsPosA = p2.vec2.create();
    var physicsPosB = p2.vec2.create();
    var stagePos = p2.vec2.create();
    var initPinchLength = 0;
    var initScaleX = 1;
    var initScaleY = 1;
    var lastNumTouches = 0;
    container.mousedown = container.touchstart = (e) {
      lastMoveX = e.global.x;
      lastMoveY = e.global.y;

      if (e.originalEvent.touches) {
        lastNumTouches = e.originalEvent.touches.length;
      }

      if (e.originalEvent.touches && e.originalEvent.touches.length == 2) {

        var touchA = that.container.interactionManager.touchs[0];
        var touchB = that.container.interactionManager.touchs[1];

        var pos = touchA.getLocalPosition(stage);
        p2.vec2.set(stagePos, pos.x, pos.y);
        that.stagePositionToPhysics(physicsPosA, stagePos);

        pos = touchB.getLocalPosition(stage);
        p2.vec2.set(stagePos, pos.x, pos.y);
        that.stagePositionToPhysics(physicsPosB, stagePos);

        initPinchLength = p2.vec2.dist(physicsPosA, physicsPosB);

        var initScaleX = stage.scale.x;
        var initScaleY = stage.scale.y;

        return;
      }
      lastX = e.global.x;
      lastY = e.global.y;
      startX = stage.position.x;
      startY = stage.position.y;
      down = true;

      that.lastMousePos = e.global;

      var pos = e.getLocalPosition(stage);
      p2.vec2.set(init_stagePosition, pos.x, pos.y);
      that.stagePositionToPhysics(init_physicsPosition, init_stagePosition);
      that.handleMouseDown(init_physicsPosition);
    };
    container.mousemove = container.touchmove = (e) {
      if (e.originalEvent.touches) {
        if (lastNumTouches != e.originalEvent.touches.length) {
          lastX = e.global.x;
          lastY = e.global.y;
          startX = stage.position.x;
          startY = stage.position.y;
        }

        lastNumTouches = e.originalEvent.touches.length;
      }

      lastMoveX = e.global.x;
      lastMoveY = e.global.y;

      if (e.originalEvent.touches && e.originalEvent.touches.length == 2) {
        var touchA = that.container.interactionManager.touchs[0];
        var touchB = that.container.interactionManager.touchs[1];

        var pos = touchA.getLocalPosition(stage);
        p2.vec2.set(stagePos, pos.x, pos.y);
        that.stagePositionToPhysics(physicsPosA, stagePos);

        pos = touchB.getLocalPosition(stage);
        p2.vec2.set(stagePos, pos.x, pos.y);
        that.stagePositionToPhysics(physicsPosB, stagePos);

        var pinchLength = p2.vec2.dist(physicsPosA, physicsPosB);

        // Get center
        p2.vec2.add(physicsPosA, physicsPosA, physicsPosB);
        p2.vec2.scale(physicsPosA, physicsPosA, 0.5);
        that.zoom(
            (touchA.global.x + touchB.global.x) * 0.5,
            (touchA.global.y + touchB.global.y) * 0.5,
            null,
            pinchLength / initPinchLength * initScaleX, // zoom relative to the initial scale
            pinchLength / initPinchLength * initScaleY
        );

        return;
      }

      if (down && that.state == Renderer.PANNING) {
        stage.position.x = e.global.x - lastX + startX;
        stage.position.y = e.global.y - lastY + startY;
      }

      that.lastMousePos = e.global;

      var pos = e.getLocalPosition(stage);
      p2.vec2.set(init_stagePosition, pos.x, pos.y);
      that.stagePositionToPhysics(init_physicsPosition, init_stagePosition);
      that.handleMouseMove(init_physicsPosition);
    };
    container.mouseup = container.touchend = (e) {
      if (e.originalEvent.touches) {
        lastNumTouches = e.originalEvent.touches.length;
      }

      down = false;
      lastMoveX = e.global.x;
      lastMoveY = e.global.y;

      that.lastMousePos = e.global;

      var pos = e.getLocalPosition(stage);
      p2.vec2.set(init_stagePosition, pos.x, pos.y);
      that.stagePositionToPhysics(init_physicsPosition, init_stagePosition);
      that.handleMouseUp(init_physicsPosition);
    };

    // http://stackoverflow.com/questions/7691551/touchend-event-in-ios-webkit-not-firing
    this.element.onTouchMove.listen((e) {
      e.preventDefault();
    });

    MouseWheelHandler(WheelEvent e) {
      // cross-browser wheel delta
      //e = window.event || e; // old IE support
      //var delta = Math.max(-1, Math.min(1, (e.wheelDelta || -e.detail)));

      WheelEvent o = e;
      num d = o.detail, w = o.wheelDeltaY, n = 225, n1 = n - 1;

      // Normalize delta: http://stackoverflow.com/a/13650579/2285811
      num f = w / d;
      d = d != 0 ? w && (f) ? d / f : -d / 1.35 : w / 120;
      // Quadratic scale if |d| > 1
      d = d < 1 ? d < -1 ? (-Math.pow(d, 2) - n1) / n : d : (Math.pow(d, 2) + n1) / n;
      // Delta *should* not be greater than 2...
      num delta = Math.min(Math.max(d / 2, -1), 1);

      bool out = delta >= 0;
      if (lastMoveX != null) {
        that.zoom(lastMoveX, lastMoveY, out, null, null, delta);
      }
    }

    if (el.addEventListener != null) {
      el.addEventListener("mousewheel", MouseWheelHandler, false); // IE9, Chrome, Safari, Opera
      el.addEventListener("DOMMouseScroll", MouseWheelHandler, false);
      // Firefox
    } else {
      el.attachEvent("onmousewheel", MouseWheelHandler);
      // IE 6/7/8
    }

    this.centerCamera(0, 0);
  }

  zoom(num x, num y, bool zoomOut, num actualScaleX, num actualScaleY, [num multiplier=1]) {
    num scrollFactor = this.scrollFactor;
    PIXI.Stage stage = this.stage;

    if (actualScaleX == null) {

      if (!zoomOut) {
        scrollFactor *= -1;
      }

      scrollFactor *= multiplier.abs();

      stage.scale.x *= (1 + scrollFactor);
      stage.scale.y *= (1 + scrollFactor);
      stage.position.x += (scrollFactor) * (stage.position.x - x);
      stage.position.y += (scrollFactor) * (stage.position.y - y);
    } else {
      stage.scale.x *= actualScaleX;
      stage.scale.y *= actualScaleY;
      stage.position.x += (actualScaleX - 1) * (stage.position.x - x);
      stage.position.y += (actualScaleY - 1) * (stage.position.y - y);
    }

    stage.updateTransform();
  }

  centerCamera(num x, num y) {
    this.stage.position.x = this.renderer.width / 2 - this.stage.scale.x * x;
    this.stage.position.y = this.renderer.height / 2 - this.stage.scale.y * y;
  }

  /**
   * Make sure that a rectangle is visible in the canvas.
   * @param  {number} centerX
   * @param  {number} centerY
   * @param  {number} width
   * @param  {number} height
   */

  frame(num centerX, num centerY, num width, num height) {
    var ratio = this.renderer.width / this.renderer.height;
    if (ratio < width / height) {
      this.stage.scale.x = this.renderer.width / width;
      this.stage.scale.y = -this.stage.scale.x;
    } else {
      this.stage.scale.y = -this.renderer.height / height;
      this.stage.scale.x = -this.stage.scale.y;
    }
    this.centerCamera(centerX, centerY);
  }

  /**
   * Draw a circle onto a graphics object
   * @method drawCircle
   * @static
   * @param  {PIXI.Graphics} g
   * @param  {Number} x
   * @param  {Number} y
   * @param  {Number} radius
   * @param  {Number} color
   * @param  {Number} lineWidth
   */

  drawCircle(PIXI.Graphics g, num x, num y, num angle, num radius, [num color=0xffffff, num lineWidth=1, bool isSleeping=true]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "number" ? color : 0xffffff;
    g.lineStyle(lineWidth, 0x000000, 1);
    g.beginFill(color, isSleeping ? this.sleepOpacity : 1.0);
    g.drawCircle(x, y, radius);
    g.endFill();

    // line from center to edge
    g.moveTo(x, y);
    g.lineTo(x + radius * Math.cos(angle),
    y + radius * Math.sin(angle));
  }

  static drawSpring(PIXI.Graphics g, num restLength, [num color=0xffffff, num lineWidth=1]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "undefined" ? 0xffffff : color;
    g.lineStyle(lineWidth, color, 1);
    if (restLength < lineWidth * 10) {
      restLength = lineWidth * 10;
    }
    num M = 12;
    num dx = restLength / M;
    g.moveTo(-restLength / 2, 0);
    for (int i = 1; i < M; i++) {
      num x = -restLength / 2 + dx * i;
      num y = 0;
      if (i <= 1 || i >= M - 1) {
// Do nothing
      } else if (i % 2 == 0) {
        y -= 0.1 * restLength;
      } else {
        y += 0.1 * restLength;
      }
      g.lineTo(x, y);
    }
    g.lineTo(restLength / 2, 0);
  }

  /**
   * Draw a finite plane onto a PIXI.Graphics.
   * @method drawPlane
   * @param  {PIXI.Graphics} g
   * @param  {Number} x0
   * @param  {Number} x1
   * @param  {Number} color
   * @param  {Number} lineWidth
   * @param  {Number} diagMargin
   * @param  {Number} diagSize
   * @todo Should consider an angle
   */

  static drawPlane(PIXI.Graphics g, num x0, num x1,
                   [num color=0xffffff,
                   num lineColor=0x0,
                   num lineWidth=1,
                   num diagMargin=0,
                   num diagSize=0,
                   num maxLength=0]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "undefined" ? 0xffffff : color;
    g.lineStyle(lineWidth, lineColor, 1);

// Draw a fill color
    g.lineStyle(0, 0, 0);
    g.beginFill(color);
    var max = maxLength;
    g.moveTo(-max, 0);
    g.lineTo(max, 0);
    g.lineTo(max, -max);
    g.lineTo(-max, -max);
    g.endFill();

// Draw the actual plane
    g.lineStyle(lineWidth, lineColor);
    g.moveTo(-max, 0);
    g.lineTo(max, 0);
  }


  static drawLine(PIXI.Graphics g, List offset, num angle, num len, [ num color=0x0, num lineWidth=1]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "undefined" ? 0x000000 : color;
    g.lineStyle(lineWidth, color, 1);

    var startPoint = p2.vec2.fromValues(-len / 2, 0);
    var endPoint = p2.vec2.fromValues(len / 2, 0);

    p2.vec2.rotate(startPoint, startPoint, angle);
    p2.vec2.rotate(endPoint, endPoint, angle);

    p2.vec2.add(startPoint, startPoint, offset);
    p2.vec2.add(endPoint, endPoint, offset);

    g.moveTo(startPoint[0], startPoint[1]);
    g.lineTo(endPoint[0], endPoint[1]);
  }

  drawCapsule(PIXI.Graphics g, num x, num y, num angle, num len, num radius,
              [num color=0x0,
              num fillColor=0x0,
              num lineWidth=1,
              bool isSleeping=true]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "undefined" ? 0x000000 : color;
    g.lineStyle(lineWidth, color, 1);

// Draw circles at ends
    num c = Math.cos(angle);
    num s = Math.sin(angle);
    g.beginFill(fillColor, isSleeping ? this.sleepOpacity : 1.0);
    g.drawCircle(-len / 2 * c + x, -len / 2 * s + y, radius);
    g.drawCircle(len / 2 * c + x, len / 2 * s + y, radius);
    g.endFill();

// Draw rectangle
    g.lineStyle(lineWidth, color, 0);
    g.beginFill(fillColor, isSleeping ? this.sleepOpacity : 1.0);
    g.moveTo(-len / 2 * c + radius * s + x, -len / 2 * s + radius * c + y);
    g.lineTo(len / 2 * c + radius * s + x, len / 2 * s + radius * c + y);
    g.lineTo(len / 2 * c - radius * s + x, len / 2 * s - radius * c + y);
    g.lineTo(-len / 2 * c - radius * s + x, -len / 2 * s - radius * c + y);
    g.endFill();

// Draw lines in between
    g.lineStyle(lineWidth, color, 1);
    g.moveTo(-len / 2 * c + radius * s + x, -len / 2 * s + radius * c + y);
    g.lineTo(len / 2 * c + radius * s + x, len / 2 * s + radius * c + y);
    g.moveTo(-len / 2 * c - radius * s + x, -len / 2 * s - radius * c + y);
    g.lineTo(len / 2 * c - radius * s + x, len / 2 * s - radius * c + y);

  }

// Todo angle

  drawRectangle(PIXI.Graphics g, num x, num y, num angle,
                num w, num h,
                [num color=0xffffff, num fillColor, num lineWidth=1, bool isSleeping=true]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "number" ? color : 0xffffff;
    fillColor = fillColor is num ? fillColor : 0xffffff;
    g.lineStyle(lineWidth);
    g.beginFill(fillColor, isSleeping ? this.sleepOpacity : 1.0);
    g.drawRect(x - w / 2, y - h / 2, w, h);
  }

  drawConvex(PIXI.Graphics g, List verts, List triangles,
             [num color=0x000000,
             num fillColor,
             num lineWidth=1,
             bool debug,
             List offset,
             bool isSleeping]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "undefined" ? 0x000000 : color;
    if (!debug) {
      g.lineStyle(lineWidth, color, 1);
      g.beginFill(fillColor, isSleeping ? this.sleepOpacity : 1.0);
      for (var i = 0; i != verts.length; i++) {
        List v = verts[i];
        num x = v[0],
        y = v[1];
        if (i == 0) {
          g.moveTo(x, y);
        } else {
          g.lineTo(x, y);
        }
      }
      g.endFill();
      if (verts.length > 2) {
        g.moveTo(verts[verts.length - 1][0], verts[verts.length - 1][1]);
        g.lineTo(verts[0][0], verts[0][1]);
      }
    } else {
      List colors = [0xff0000, 0x00ff00, 0x0000ff];
      for (int i = 0; i != verts.length + 1; i++) {
        var v0 = verts[i % verts.length],
        v1 = verts[(i + 1) % verts.length],
        x0 = v0[0],
        y0 = v0[1],
        x1 = v1[0],
        y1 = v1[1];
        g.lineStyle(lineWidth, colors[i % colors.length], 1);
        g.moveTo(x0, y0);
        g.lineTo(x1, y1);
        g.drawCircle(x0, y0, lineWidth * 2);
      }

      g.lineStyle(lineWidth, 0x000000, 1);
      g.drawCircle(offset[0], offset[1], lineWidth * 2);
    }
  }

  drawPath(PIXI.Graphics g, List path, [num color=0x0, num fillColor, num lineWidth=1, bool isSleeping=true]) {
//    lineWidth = typeof(lineWidth) == "number" ? lineWidth : 1;
//    color = typeof(color) == "undefined" ? 0x000000 : color;
    g.lineStyle(lineWidth, color, 1);
    if (fillColor is num) {
      g.beginFill(fillColor, isSleeping ? this.sleepOpacity : 1.0);
    }
    num lastx = null,
    lasty = null;
    for (int i = 0; i < path.length; i++) {
      var v = path[i],
      x = v[0],
      y = v[1];
      if (x != lastx || y != lasty) {
        if (i == 0) {
          g.moveTo(x, y);
        } else {
// Check if the lines are parallel
          var p1x = lastx,
          p1y = lasty,
          p2x = x,
          p2y = y,
          p3x = path[(i + 1) % path.length][0],
          p3y = path[(i + 1) % path.length][1];
          var area = ((p2x - p1x) * (p3y - p1y)) - ((p3x - p1x) * (p2y - p1y));
          if (area != 0) {
            g.lineTo(x, y);
          }
        }
        lastx = x;
        lasty = y;
      }
    }
    if (fillColor is num) {
      g.endFill();
    }

// Close the path
    if (path.length > 2 && fillColor is num) {
      g.moveTo(path[path.length - 1][0], path[path.length - 1][1]);
      g.lineTo(path[0][0], path[0][1]);
    }
  }

  updateSpriteTransform(sprite, body) {
    if (this.useInterpolatedPositions) {
      sprite.position.x = body.interpolatedPosition[0];
      sprite.position.y = body.interpolatedPosition[1];
      sprite.rotation = body.interpolatedAngle;
    } else {
      sprite.position.x = body.position[0];
      sprite.position.y = body.position[1];
      sprite.rotation = body.angle;
    }
  }

  var X = p2.vec2.fromValues(1, 0),
  distVec = p2.vec2.fromValues(0, 0),
  worldAnchorA = p2.vec2.fromValues(0, 0),
  worldAnchorB = p2.vec2.fromValues(0, 0);

  render() {
    var w = this.renderer.width,
    h = this.renderer.height,
    springSprites = this.springSprites,
    sprites = this.sprites;

    // Update body transforms
    for (var i = 0; i != this.bodies.length; i++) {
      this.updateSpriteTransform(this.sprites[i], this.bodies[i]);
    }

    // Update graphics if the body changed sleepState
    for (var i = 0; i != this.bodies.length; i++) {
      var isSleeping = (this.bodies[i].sleepState == p2.Body.SLEEPING);
      var sprite = this.sprites[i];
      var body = this.bodies[i];
      if (sprite.drawnSleeping != isSleeping) {
        sprite.clear();
        this.drawRenderable(body, sprite, sprite.drawnColor, sprite.drawnLineColor);
      }
    }

    // Update spring transforms
    for (var i = 0; i != this.springs.length; i++) {
      var s = this.springs[i],
      sprite = springSprites[i],
      bA = s.bodyA,
      bB = s.bodyB;

      if (this.useInterpolatedPositions) {
        p2.vec2.toGlobalFrame(worldAnchorA, s.localAnchorA, bA.interpolatedPosition, bA.interpolatedAngle);
        p2.vec2.toGlobalFrame(worldAnchorB, s.localAnchorB, bB.interpolatedPosition, bB.interpolatedAngle);
      } else {
        s.getWorldAnchorA(worldAnchorA);
        s.getWorldAnchorB(worldAnchorB);
      }

      sprite.scale.y = 1;
      if (worldAnchorA[1] < worldAnchorB[1]) {
        var tmp = worldAnchorA;
        worldAnchorA = worldAnchorB;
        worldAnchorB = tmp;
        sprite.scale.y = -1;
      }

      var sxA = worldAnchorA[0],
      syA = worldAnchorA[1],
      sxB = worldAnchorB[0],
      syB = worldAnchorB[1];

      // Spring position is the mean point between the anchors
      sprite.position.x = ( sxA + sxB ) / 2;
      sprite.position.y = ( syA + syB ) / 2;

      // Compute distance vector between anchors, in screen coords
      distVec[0] = sxA - sxB;
      distVec[1] = syA - syB;

      // Compute angle
      sprite.rotation = Math.acos(p2.vec2.dot(X, distVec) / p2.vec2.length(distVec));

      // And scale
      sprite.scale.x = p2.vec2.length(distVec) / s.restLength;
    }

    // Clear contacts
    if (this.drawContacts) {
      this.contactGraphics.clear();
      this.stage.removeChild(this.contactGraphics);
      this.stage.addChild(this.contactGraphics);

      var g = this.contactGraphics;
      g.lineStyle(this.lineWidth, 0x000000, 1);
      for (var i = 0; i != this.world.narrowphase.contactEquations.length; i++) {
        var eq = this.world.narrowphase.contactEquations[i],
        bi = eq.bodyA,
        bj = eq.bodyB,
        ri = eq.contactPointA,
        rj = eq.contactPointB,
        xi = bi.position[0],
        yi = bi.position[1],
        xj = bj.position[0],
        yj = bj.position[1];

        g.moveTo(xi, yi);
        g.lineTo(xi + ri[0], yi + ri[1]);

        g.moveTo(xj, yj);
        g.lineTo(xj + rj[0], yj + rj[1]);

      }
      this.contactGraphics.cleared = false;
    } else if (!this.contactGraphics.cleared) {
      this.contactGraphics.clear();
      this.contactGraphics.cleared = true;
    }

    // Draw AABBs
    if (this.drawAABBs) {
      this.aabbGraphics.clear();
      this.stage.removeChild(this.aabbGraphics);
      this.stage.addChild(this.aabbGraphics);
      var g = this.aabbGraphics;
      g.lineStyle(this.lineWidth, 0x000000, 1);

      for (var i = 0; i != this.world.bodies.length; i++) {
        var aabb = this.world.bodies[i].getAABB();
        g.drawRect(aabb.lowerBound[0], aabb.lowerBound[1], aabb.upperBound[0] - aabb.lowerBound[0], aabb.upperBound[1] - aabb.lowerBound[1]);
      }
      this.aabbGraphics.cleared = false;
    } else if (!this.aabbGraphics.cleared) {
      this.aabbGraphics.clear();
      this.aabbGraphics.cleared = true;
    }

    this.renderer.render(this.container);
  }


  drawRenderable(obj, graphics, color, lineColor) {
    var lw = this.lineWidth;

    var zero = [0, 0];
    graphics.drawnSleeping = false;
    graphics.drawnColor = color;
    graphics.drawnLineColor = lineColor;

    if (obj is p2.Body && obj.shapes.length) {

      var isSleeping = (obj.sleepState == p2.Body.SLEEPING);
      graphics.drawnSleeping = isSleeping;

      if (obj.concavePath && !this.debugPolygons) {
        var path = [];
        for (var j = 0; j != obj.concavePath.length; j++) {
          var v = obj.concavePath[j];
          path.push([v[0], v[1]]);
        }
        this.drawPath(graphics, path, lineColor, color, lw, isSleeping);
      } else {
        for (var i = 0; i < obj.shapes.length; i++) {
          var child = obj.shapes[i],
          offset = obj.shapeOffsets[i],
          angle = obj.shapeAngles[i];
          offset = offset || zero;
          angle = angle || 0;

          if (child is p2.Circle) {
            this.drawCircle(graphics, offset[0], offset[1], angle, child.radius, color, lw, isSleeping);

          } else if (child is p2.Particle) {
            this.drawCircle(graphics, offset[0], offset[1], angle, 2 * lw, lineColor, 0);

          } else if (child is p2.Plane) {
            // TODO use shape angle
            WebGLRenderer.drawPlane(graphics, -10, 10, color, lineColor, lw, lw * 10, lw * 10, 100);

          } else if (child is p2.Line) {
            WebGLRenderer.drawLine(graphics, offset, angle, child.length, lineColor, lw);

          } else if (child is p2.Rectangle) {
            this.drawRectangle(graphics, offset[0], offset[1], angle, child.width, child.height, lineColor, color, lw, isSleeping);

          } else if (child is p2.Capsule) {
            this.drawCapsule(graphics, offset[0], offset[1], angle, child.length, child.radius, lineColor, color, lw, isSleeping);

          } else if (child is p2.Convex) {
            // Scale verts
            var verts = [],
            vrot = p2.vec2.create();
            for (var j = 0; j != child.vertices.length; j++) {
              var v = child.vertices[j];
              p2.vec2.rotate(vrot, v, angle);
              verts.push([(vrot[0] + offset[0]), (vrot[1] + offset[1])]);
            }
            this.drawConvex(graphics, verts, child.triangles, lineColor, color, lw, this.debugPolygons, [offset[0], -offset[1]], isSleeping);

          } else if (child is p2.Heightfield) {
            var path = [[0, -100]];
            for (var j = 0; j != child.data.length; j++) {
              var v = child.data[j];
              path.push([j * child.elementWidth, v]);
            }
            path.push([child.data.length * child.elementWidth, -100]);
            this.drawPath(graphics, path, lineColor, color, lw, isSleeping);

          }
        }
      }

    } else if (obj is p2.Spring) {
      var restLengthPixels = obj.restLength;
      WebGLRenderer.drawSpring(graphics, restLengthPixels, 0x000000, lw);
    }
  }

  addRenderable(obj) {
    num lw = this.lineWidth;

    // Random color
    int color = int.parse(randomPastelHex(), radix:16);
    num lineColor = 0x000000;

    List zero = [0, 0];

    PIXI.Graphics sprite = new PIXI.Graphics();
    if (obj is p2.Body && obj.shapes.length != 0) {

      this.drawRenderable(obj, sprite, color, lineColor);
      this.sprites.add(sprite);
      this.stage.addChild(sprite);

    } else if (obj is p2.Spring) {
      this.drawRenderable(obj, sprite, 0x000000, lineColor);
      this.springSprites.add(sprite);
      this.stage.addChild(sprite);
    }
  }

  removeRenderable(obj) {
    if (obj is p2.Body) {
      int i = this.bodies.indexOf(obj);
      if (i != -1) {
        this.stage.removeChild(this.sprites[i]);
        this.sprites.removeAt(i);
      }
    } else if (obj is p2.Spring) {
      int i = this.springs.indexOf(obj);
      if (i != -1) {
        this.stage.removeChild(this.springSprites[i]);
        this.springSprites.removeAt(i);
      }
    }
  }

  resize(w, h) {
    var renderer = this.renderer;
    var view = renderer.view;
    var ratio = w / h;
    renderer.resize(w, h);
  }
}

//http://stackoverflow.com/questions/5623838/rgb-to-hex-and-hex-to-rgb

String componentToHex(c) {
  String hex = c.toString(16);
  return hex.length == 1 ? "0" + hex : hex;
}

String rgbToHex(int r, int g, int b) {
  return componentToHex(r) + componentToHex(g) + componentToHex(b);
}
//http://stackoverflow.com/questions/43044/algorithm-to-randomly-generate-an-aesthetically-pleasing-color-palette

Math.Random random = new Math.Random();
const List mix = const [255, 255, 255];

String randomPastelHex() {

  int red = random.nextInt(256);
  int green = random.nextInt(256);
  int blue = random.nextInt(256);

  // mix the color
  red = ((red + 3 * mix[0]) / 4).floor();
  green = ((green + 3 * mix[1]) / 4).floor();
  blue = ((blue + 3 * mix[2]) / 4).floor();

  return rgbToHex(red, green, blue);
}