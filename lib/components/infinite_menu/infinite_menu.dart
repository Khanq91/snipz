/// Infinite Menu
/// Origin: adapted — react-bits "InfiniteMenu" (WebGL2 + gl-matrix) rebuilt on
/// CustomPainter: same icosphere layout, arcball control, snapping and camera
/// dolly; the GL instanced rendering is replaced by projected, depth-sorted
/// image discs.
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One entry on the sphere. [image] is app-provided (any ImageProvider);
/// while it resolves the disc renders as a flat placeholder.
class InfiniteMenuItem {
  const InfiniteMenuItem({
    required this.image,
    this.title = '',
    this.description = '',
    this.onPressed,
  });

  final ImageProvider image;
  final String title;
  final String description;

  /// Replaces the original's `link` — fired by the overlay action button.
  final VoidCallback? onPressed;
}

/// Drag-to-spin sphere of image discs. When the pointer is released the
/// nearest disc snaps to face the camera and becomes the active item; the
/// optional overlay shows its title/description and an action button.
///
/// The widget fills its parent (give it bounded constraints). Rendering is
/// a perspective projection done on the CPU — 42 discs, cheap per frame —
/// and the internal ticker stops on its own once the sphere has settled.
class InfiniteMenu extends StatefulWidget {
  const InfiniteMenu({
    super.key,
    required this.items,
    this.scale = 1.0,
    this.animate = true,
    this.showOverlay = true,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.accentColor = const Color(0xFF00FFFF),
    this.titleStyle,
    this.descriptionStyle,
    this.filterQuality = FilterQuality.medium,
    this.onActiveItemChanged,
    this.onMovementChanged,
  });

  final List<InfiniteMenuItem> items;

  /// Camera-distance factor from the original (`3 * scale`). Bigger = sphere
  /// further away / smaller on screen. NOT a §9.1 paint-detail scale.
  final double scale;

  /// External stop switch: false freezes the ticker (keeps the last frame)
  /// and ignores pointer input.
  final bool animate;

  /// Title / description / action button of the active item, faithful to the
  /// original's DOM overlay. Turn off to render only the sphere and drive
  /// your own UI from [onActiveItemChanged] + [onMovementChanged].
  final bool showOverlay;

  /// The original clears to opaque black. Use [Colors.transparent] to
  /// composite the sphere over your own background.
  final Color backgroundColor;

  final Color textColor;

  /// Action button fill (original: #00FFFF circle, black border + arrow).
  final Color accentColor;

  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final FilterQuality filterQuality;

  /// Fired whenever the snapped-to item changes (index into [items]).
  final ValueChanged<int>? onActiveItemChanged;

  /// True while dragging or coasting — the original uses it to hide the
  /// overlay; exposed so app chrome can react too.
  final ValueChanged<bool>? onMovementChanged;

  @override
  State<InfiniteMenu> createState() => _InfiniteMenuState();
}

// ---------------------------------------------------------------------------
// Minimal vec3/quat — hand-rolled so the file stays "flutter only" (rule 1:
// no package:vector_math import; only the handful of gl-matrix ops the
// original algorithm actually uses).
// ---------------------------------------------------------------------------

class _V3 {
  _V3(this.x, this.y, this.z);
  double x, y, z;

  double get length => math.sqrt(x * x + y * y + z * z);

  _V3 normalized() {
    final double l = length;
    return l > 1e-12 ? _V3(x / l, y / l, z / l) : _V3(0, 0, 0);
  }

  _V3 operator +(_V3 o) => _V3(x + o.x, y + o.y, z + o.z);
  _V3 operator -(_V3 o) => _V3(x - o.x, y - o.y, z - o.z);
  _V3 scaled(double s) => _V3(x * s, y * s, z * s);

  static double dot(_V3 a, _V3 b) => a.x * b.x + a.y * b.y + a.z * b.z;

  static _V3 cross(_V3 a, _V3 b) => _V3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
      );

  static double sqrDist(_V3 a, _V3 b) {
    final double dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return dx * dx + dy * dy + dz * dz;
  }
}

class _Quat {
  _Quat(this.x, this.y, this.z, this.w);
  _Quat.identity() : this(0, 0, 0, 1);
  double x, y, z, w;

  void setIdentity() {
    x = 0;
    y = 0;
    z = 0;
    w = 1;
  }

  void copyFrom(_Quat o) {
    x = o.x;
    y = o.y;
    z = o.z;
    w = o.w;
  }

  void setAxisAngle(_V3 axis, double rad) {
    final double half = rad * 0.5, s = math.sin(half);
    x = axis.x * s;
    y = axis.y * s;
    z = axis.z * s;
    w = math.cos(half);
  }

  void normalize() {
    final double l = math.sqrt(x * x + y * y + z * z + w * w);
    if (l > 1e-12) {
      x /= l;
      y /= l;
      z /= l;
      w /= l;
    } else {
      setIdentity();
    }
  }

  /// out = a * b (gl-matrix quat.multiply order).
  static _Quat multiply(_Quat a, _Quat b) => _Quat(
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
        a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
      );

  _Quat conjugated() => _Quat(-x, -y, -z, w);

  _V3 rotate(_V3 v) {
    // q * v * q^-1, expanded (gl-matrix vec3.transformQuat).
    final double uvx = y * v.z - z * v.y,
        uvy = z * v.x - x * v.z,
        uvz = x * v.y - y * v.x;
    final double uuvx = y * uvz - z * uvy,
        uuvy = z * uvx - x * uvz,
        uuvz = x * uvy - y * uvx;
    return _V3(
      v.x + 2 * (uvx * w + uuvx),
      v.y + 2 * (uvy * w + uuvy),
      v.z + 2 * (uvz * w + uuvz),
    );
  }

  /// Ported gl-matrix quat.slerp (shortest path, with lerp fallback).
  void slerpTo(_Quat b, double t) {
    double bx = b.x, by = b.y, bz = b.z, bw = b.w;
    double cosom = x * bx + y * by + z * bz + w * bw;
    if (cosom < 0) {
      cosom = -cosom;
      bx = -bx;
      by = -by;
      bz = -bz;
      bw = -bw;
    }
    double scale0, scale1;
    if (1 - cosom > 1e-6) {
      final double omega = math.acos(cosom), sinom = math.sin(omega);
      scale0 = math.sin((1 - t) * omega) / sinom;
      scale1 = math.sin(t * omega) / sinom;
    } else {
      scale0 = 1 - t;
      scale1 = t;
    }
    x = scale0 * x + scale1 * bx;
    y = scale0 * y + scale1 * by;
    z = scale0 * z + scale1 * bz;
    w = scale0 * w + scale1 * bw;
  }
}

// ---------------------------------------------------------------------------
// Icosphere — IcosahedronGeometry().subdivide(1).spherize(2) from the source.
// 42 vertices; each vertex hosts one disc instance.
// ---------------------------------------------------------------------------

List<_V3> _buildIcosphere(double radius) {
  final double t = math.sqrt(5) * 0.5 + 0.5;
  final List<_V3> verts = <_V3>[
    _V3(-1, t, 0), _V3(1, t, 0), _V3(-1, -t, 0), _V3(1, -t, 0),
    _V3(0, -1, t), _V3(0, 1, t), _V3(0, -1, -t), _V3(0, 1, -t),
    _V3(t, 0, -1), _V3(t, 0, 1), _V3(-t, 0, -1), _V3(-t, 0, 1),
  ];
  const List<int> faces = <int>[
    0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, //
    1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8, //
    3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, //
    4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
  ];
  // One subdivision: add the midpoint of every edge (cache-deduped).
  final Map<int, int> midCache = <int, int>{};
  int midPoint(int a, int b) {
    final int key = a < b ? b * 4096 + a : a * 4096 + b;
    final int? cached = midCache[key];
    if (cached != null) return cached;
    final _V3 va = verts[a], vb = verts[b];
    verts.add(_V3((va.x + vb.x) * 0.5, (va.y + vb.y) * 0.5, (va.z + vb.z) * 0.5));
    midCache[key] = verts.length - 1;
    return verts.length - 1;
  }

  for (int i = 0; i < faces.length; i += 3) {
    midPoint(faces[i], faces[i + 1]);
    midPoint(faces[i + 1], faces[i + 2]);
    midPoint(faces[i + 2], faces[i]);
  }
  return verts.map((v) => v.normalized().scaled(radius)).toList(growable: false);
}

// ---------------------------------------------------------------------------
// ArcballControl — near-verbatim port (pointer wiring moved to the widget).
// ---------------------------------------------------------------------------

class _ArcballControl {
  bool isPointerDown = false;
  final _Quat orientation = _Quat.identity();
  final _Quat pointerRotation = _Quat.identity();
  double rotationVelocity = 0;
  _V3 rotationAxis = _V3(1, 0, 0);

  final _V3 snapDirection = _V3(0, 0, -1);
  _V3? snapTargetDirection;

  Offset pointerPos = Offset.zero;
  Offset _previousPointerPos = Offset.zero;
  double _rotationVelocityInternal = 0;
  final _Quat _combinedQuat = _Quat.identity();

  static const double _epsilon = 0.1;

  Size viewSize = Size.zero;

  void onPointerDown(Offset local) {
    pointerPos = local;
    _previousPointerPos = local;
    isPointerDown = true;
  }

  void onPointerMove(Offset local) {
    if (isPointerDown) pointerPos = local;
  }

  void onPointerUp() {
    isPointerDown = false;
  }

  void update(double deltaTime, double targetFrameDuration) {
    final double timeScale = deltaTime / targetFrameDuration + 0.00001;
    double angleFactor = timeScale;
    final _Quat snapRotation = _Quat.identity();

    if (isPointerDown) {
      final double intensity = 0.3 * timeScale;
      final double angleAmplification = 5 / timeScale;
      Offset mid = (pointerPos - _previousPointerPos) * intensity;

      if (mid.dx * mid.dx + mid.dy * mid.dy > _epsilon) {
        mid = _previousPointerPos + mid;
        final _V3 p = _project(mid).normalized();
        final _V3 q = _project(_previousPointerPos).normalized();
        _previousPointerPos = mid;
        angleFactor *= angleAmplification;
        _quatFromVectors(p, q, pointerRotation, angleFactor);
      } else {
        pointerRotation.slerpTo(_Quat.identity(), intensity);
      }
    } else {
      pointerRotation.slerpTo(_Quat.identity(), 0.1 * timeScale);

      final _V3? target = snapTargetDirection;
      if (target != null) {
        const double snappingIntensity = 0.2;
        final double sqrDist = _V3.sqrDist(target, snapDirection);
        final double distanceFactor = math.max(0.1, 1 - sqrDist * 10);
        angleFactor *= snappingIntensity * distanceFactor;
        _quatFromVectors(target, snapDirection, snapRotation, angleFactor);
      }
    }

    final _Quat combined = _Quat.multiply(snapRotation, pointerRotation);
    final _Quat newOrientation = _Quat.multiply(combined, orientation);
    orientation.copyFrom(newOrientation);
    orientation.normalize();

    _combinedQuat.slerpTo(combined, 0.8 * timeScale);
    _combinedQuat.normalize();

    final double rad = math.acos(_combinedQuat.w.clamp(-1.0, 1.0)) * 2.0;
    final double s = math.sin(rad / 2.0);
    double rv = 0;
    if (s > 0.000001) {
      rv = rad / (2 * math.pi);
      rotationAxis = _V3(
        _combinedQuat.x / s,
        _combinedQuat.y / s,
        _combinedQuat.z / s,
      );
    }

    _rotationVelocityInternal += (rv - _rotationVelocityInternal) * 0.5 * timeScale;
    rotationVelocity = _rotationVelocityInternal / timeScale;
  }

  void _quatFromVectors(_V3 a, _V3 b, _Quat out, double angleFactor) {
    _V3 axis = _V3.cross(a, b).normalized();
    if (axis.length < 1e-9) axis = _V3(1, 0, 0);
    final double d = _V3.dot(a, b).clamp(-1.0, 1.0);
    out.setAxisAngle(axis, math.acos(d) * angleFactor);
  }

  /// Screen point -> virtual arcball sphere (r=2), verbatim incl. the
  /// hyperbolic sheet outside the sphere and the GL x flip.
  _V3 _project(Offset pos) {
    const double r = 2;
    final double w = viewSize.width, h = viewSize.height;
    final double s = math.max(w, h) - 1;
    final double x = (2 * pos.dx - w - 1) / s;
    final double y = (2 * pos.dy - h - 1) / s;
    final double xySq = x * x + y * y;
    const double rSq = r * r;
    final double z = xySq <= rSq / 2.0 ? math.sqrt(rSq - xySq) : rSq / math.sqrt(xySq);
    return _V3(-x, y, z);
  }
}

// ---------------------------------------------------------------------------
// Widget state — ticker, camera, image resolving, overlay.
// ---------------------------------------------------------------------------

/// Mutable per-frame scene values shared with the painter. The painter is
/// only reconstructed on widget rebuilds, but repaints every tick via the
/// repaint Listenable — so anything that changes per tick must live here,
/// not in painter fields.
class _SceneState {
  double cameraZ = 3;
  double smoothRotationVelocity = 0;
}

class _InfiniteMenuState extends State<InfiniteMenu>
    with SingleTickerProviderStateMixin {
  static const double _sphereRadius = 2.0;
  static const double _targetFrameMs = 1000 / 60;

  late final List<_V3> _vertices = _buildIcosphere(_sphereRadius);
  final _ArcballControl _control = _ArcballControl();
  final _SceneState _scene = _SceneState();

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  int _settledFrames = 0;

  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  int _activeIndex = -1;
  bool _isMoving = false;

  // Resolved images, index-aligned with widget.items.
  List<ImageInfo?> _images = <ImageInfo?>[];
  final List<ImageStream> _streams = <ImageStream>[];
  final List<ImageStreamListener> _listeners = <ImageStreamListener>[];

  @override
  void initState() {
    super.initState();
    _scene.cameraZ = 3 * widget.scale;
    _ticker = createTicker(_tick);
    if (widget.animate) _ticker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImages();
  }

  @override
  void didUpdateWidget(InfiniteMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) _resolveImages();
    if (widget.animate != oldWidget.animate) {
      if (widget.animate && !_ticker.isActive) {
        _lastElapsed = Duration.zero;
        _ticker.start();
      } else if (!widget.animate && _ticker.isActive) {
        _ticker.stop();
      }
    }
  }

  void _resolveImages() {
    _disposeImages();
    _images = List<ImageInfo?>.filled(widget.items.length, null);
    final List<ImageInfo?> images = _images;
    for (int i = 0; i < widget.items.length; i++) {
      final ImageStream stream =
          widget.items[i].image.resolve(createLocalImageConfiguration(context));
      final ImageStreamListener listener = ImageStreamListener(
        (ImageInfo info, bool syncCall) {
          // `images` pins the generation this listener belongs to.
          if (!mounted || !identical(images, _images)) {
            info.dispose();
            return;
          }
          images[i]?.dispose();
          images[i] = info;
          _repaint.value++;
        },
        onError: (Object error, StackTrace? stackTrace) {}, // placeholder disc
      );
      _streams.add(stream);
      _listeners.add(listener);
      stream.addListener(listener);
    }
  }

  void _disposeImages() {
    for (int i = 0; i < _streams.length; i++) {
      _streams[i].removeListener(_listeners[i]);
    }
    _streams.clear();
    _listeners.clear();
    for (final ImageInfo? info in _images) {
      info?.dispose();
    }
    _images = <ImageInfo?>[];
  }

  void _tick(Duration elapsed) {
    // Original clamps rAF delta to 32ms.
    double dt = (elapsed - _lastElapsed).inMicroseconds / 1000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 32) dt = 32;

    _control.update(dt, _targetFrameMs);
    _onControlUpdate(dt);
    _scene.smoothRotationVelocity = _control.rotationVelocity;

    // Self-stop: once released, snapped and still, park the ticker. Any
    // pointer-down (or animate toggle) restarts it.
    final _V3? snapTarget = _control.snapTargetDirection;
    final bool snapSettled = snapTarget == null ||
        _V3.sqrDist(snapTarget, _control.snapDirection) < 1e-5;
    final bool moving = _control.isPointerDown ||
        _scene.smoothRotationVelocity.abs() > 0.005 ||
        !snapSettled ||
        (_scene.cameraZ - 3 * widget.scale).abs() > 0.001;
    _settledFrames = moving ? 0 : _settledFrames + 1;
    if (_settledFrames > 30 && _ticker.isActive) {
      _ticker.stop();
      _lastElapsed = Duration.zero;
    }

    _repaint.value++;
  }

  // Port of InfiniteGridMenu.onControlUpdate: snap target + camera dolly.
  void _onControlUpdate(double deltaTime) {
    final double timeScale = deltaTime / _targetFrameMs + 0.0001;
    double damping = 5 / timeScale;
    double cameraTargetZ = 3 * widget.scale;

    final bool isMoving =
        _control.isPointerDown || _scene.smoothRotationVelocity.abs() > 0.01;
    if (isMoving != _isMoving) {
      _isMoving = isMoving;
      widget.onMovementChanged?.call(isMoving);
      if (widget.showOverlay && mounted) setState(() {});
    }

    if (!_control.isPointerDown) {
      final int nearest = _findNearestVertexIndex();
      final int itemCount = math.max(1, widget.items.length);
      final int itemIndex = nearest % itemCount;
      if (itemIndex != _activeIndex && widget.items.isNotEmpty) {
        _activeIndex = itemIndex;
        widget.onActiveItemChanged?.call(itemIndex);
        if (widget.showOverlay && mounted) setState(() {});
      }
      _control.snapTargetDirection =
          _control.orientation.rotate(_vertices[nearest]).normalized();
    } else {
      cameraTargetZ += _control.rotationVelocity * 80 + 2.5;
      damping = 7 / timeScale;
    }

    _scene.cameraZ += (cameraTargetZ - _scene.cameraZ) / damping;
  }

  int _findNearestVertexIndex() {
    final _V3 nt = _control.orientation.conjugated().rotate(_control.snapDirection);
    double maxD = -double.infinity;
    int nearest = 0;
    for (int i = 0; i < _vertices.length; i++) {
      final double d = _V3.dot(nt, _vertices[i]);
      if (d > maxD) {
        maxD = d;
        nearest = i;
      }
    }
    return nearest;
  }

  void _wake() {
    if (widget.animate && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _disposeImages();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InfiniteMenuItem? active = widget.items.isNotEmpty && _activeIndex >= 0
        ? widget.items[_activeIndex]
        : null;

    return LayoutBuilder(builder: (context, constraints) {
      final Size size = constraints.biggest;
      _control.viewSize = size;

      final Widget sphere = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.animate
            ? (e) {
                _control.onPointerDown(e.localPosition);
                _wake();
              }
            : null,
        onPointerMove: widget.animate ? (e) => _control.onPointerMove(e.localPosition) : null,
        onPointerUp: widget.animate ? (_) => _control.onPointerUp() : null,
        onPointerCancel: widget.animate ? (_) => _control.onPointerUp() : null,
        child: CustomPaint(
          size: size,
          painter: _InfiniteMenuPainter(
            repaint: _repaint,
            vertices: _vertices,
            control: _control,
            scene: _scene,
            images: _images,
            itemCount: widget.items.length,
            backgroundColor: widget.backgroundColor,
            filterQuality: widget.filterQuality,
          ),
        ),
      );

      if (!widget.showOverlay || active == null) return sphere;

      // Overlay timings from the original: hide in 100ms while moving,
      // reveal in 500ms once settled; CSS cubic-bezier(.25,.1,.25,1) == ease.
      final Duration dur = Duration(milliseconds: _isMoving ? 100 : 500);
      const Curve curve = Curves.ease;

      final TextStyle titleStyle = widget.titleStyle ??
          TextStyle(
            color: widget.textColor,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1.05,
          );
      final TextStyle descStyle = widget.descriptionStyle ??
          TextStyle(color: widget.textColor, fontSize: 16, height: 1.3);

      return Stack(children: <Widget>[
        Positioned.fill(child: sphere),
        // Title — left of the sphere, vertically centered.
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          width: size.width * 0.32,
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _isMoving ? 0 : 1,
                duration: dur,
                curve: curve,
                child: AnimatedSlide(
                  offset: _isMoving ? const Offset(-0.1, 0) : Offset.zero,
                  duration: dur,
                  curve: curve,
                  child: Text(active.title,
                      style: titleStyle, overflow: TextOverflow.fade),
                ),
              ),
            ),
          ),
        ),
        // Description — right side, vertically centered, narrow column.
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          width: size.width * 0.28,
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: _isMoving ? 0 : 1,
                duration: dur,
                curve: curve,
                child: AnimatedSlide(
                  offset: _isMoving ? const Offset(0.1, 0) : Offset.zero,
                  duration: dur,
                  curve: curve,
                  child: Text(active.description,
                      style: descStyle, overflow: TextOverflow.fade),
                ),
              ),
            ),
          ),
        ),
        // Action button — bottom center, slides and scales away while moving.
        AnimatedPositioned(
          duration: dur,
          curve: curve,
          left: 0,
          right: 0,
          bottom: _isMoving ? -80 : 56,
          child: Center(
            child: AnimatedOpacity(
              opacity: _isMoving ? 0 : 1,
              duration: dur,
              curve: curve,
              child: AnimatedScale(
                scale: _isMoving ? 0 : 1,
                duration: dur,
                curve: curve,
                child: GestureDetector(
                  onTap: active.onPressed,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('↗',
                        style: TextStyle(
                            color: Color(0xFF120F17),
                            fontSize: 26,
                            height: 1)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

// ---------------------------------------------------------------------------
// Painter — replaces the GL pipeline. Per frame: rotate 42 vertices, build
// each disc's tangent frame, project to screen as an affine-mapped ellipse,
// depth-sort, backface-cull, draw the cover-cropped image.
// ---------------------------------------------------------------------------

class _InfiniteMenuPainter extends CustomPainter {
  _InfiniteMenuPainter({
    required Listenable repaint,
    required this.vertices,
    required this.control,
    required this.scene,
    required this.images,
    required this.itemCount,
    required this.backgroundColor,
    required this.filterQuality,
  }) : super(repaint: repaint);

  final List<_V3> vertices;
  final _ArcballControl control;
  final _SceneState scene;
  final List<ImageInfo?> images;
  final int itemCount;
  final Color backgroundColor;
  final FilterQuality filterQuality;

  static const double _sphereRadius = _InfiniteMenuState._sphereRadius;
  static const double _discScale = 0.25; // original `scale`
  static const double _scaleIntensity = 0.6; // original SCALE_INTENSITY

  final Float64List _m4 = Float64List(16);
  static final Path _unitDisc = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1));
  final Paint _imagePaint = Paint();
  final Paint _placeholderPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    }
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Camera: at (0,0,cameraZ) looking at the origin, y-up (GL convention);
    // fov fits the sphere like updateProjectionMatrix() in the source.
    final double cameraZ = scene.cameraZ;
    final double aspect = size.width / size.height;
    const double height = _sphereRadius * 0.35;
    final double fov = aspect > 1
        ? 2 * math.atan(height / cameraZ)
        : 2 * math.atan(height / aspect / cameraZ);
    final double f = 1 / math.tan(fov / 2);

    Offset project(_V3 p) {
      final double zv = p.z - cameraZ; // view-space z (negative in front)
      final double inv = -1 / zv;
      final double xn = (f / aspect) * p.x * inv;
      final double yn = f * p.y * inv;
      return Offset((xn + 1) / 2 * size.width, (1 - yn) / 2 * size.height);
    }

    // Velocity smear (vertex-shader stretch, approximated per disc below).
    final double stretchVel =
        math.min(0.15, (scene.smoothRotationVelocity * 1.1).abs() * 15);

    final _Quat orientation = control.orientation;
    final int n = vertices.length;
    final List<(double, int, _V3)> visible = <(double, int, _V3)>[];
    for (int i = 0; i < n; i++) {
      final _V3 q = orientation.rotate(vertices[i]);
      // Disc lives on the opposite direction of its vertex (sign inherited
      // from the original's instance-matrix chain); cull the far hemisphere.
      if (-q.z / _sphereRadius < -0.15) continue;
      visible.add((q.z, i, q));
    }
    // Painter's algorithm: q.z descending == disc center z ascending (far
    // discs first, because the disc sits at -q).
    visible.sort((a, b) => b.$1.compareTo(a.$1));

    for (final (_, int i, _V3 q) in visible) {
      final _V3 qn = q.normalized();
      final _V3 u = qn.scaled(-1); // disc direction (unit)

      // Depth-dependent scale: s = |z|/R * 0.6 + 0.4, world radius = s*0.25.
      final double s =
          (q.z.abs() / _sphereRadius) * _scaleIntensity + (1 - _scaleIntensity);
      final double fs = s * _discScale;
      // World radius: rim at local distance 1 × finalScale. The GL version
      // additionally curves the disc onto the sphere (re-normalization in the
      // vertex shader) — the flat-disc approximation here differs only at
      // grazing angles. See README Port notes.
      final double discRadius = fs;
      final _V3 center = u.scaled(_sphereRadius * (1 - fs));

      // Tangent frame (targetTo with up (0,1,0); fallback near the poles).
      _V3 xAxis = _V3.cross(_V3(0, 1, 0), u.scaled(-1));
      if (xAxis.length < 1e-6) xAxis = _V3(1, 0, 0);
      xAxis = xAxis.normalized();
      final _V3 yAxis = _V3.cross(u.scaled(-1), xAxis).normalized();

      // Backface cull against the actual view ray.
      final _V3 toCam = _V3(0, 0, cameraZ) - center;
      if (_V3.dot(u, toCam) <= 0) continue;

      final Offset p0 = project(center);
      final Offset p1 = project(center + xAxis.scaled(discRadius));
      final Offset p2 = project(center + yAxis.scaled(discRadius));
      final Offset ex = p1 - p0, ey = p2 - p0;

      // Column-major affine: local unit disc -> screen ellipse.
      _m4[0] = ex.dx;
      _m4[1] = ex.dy;
      _m4[4] = ey.dx;
      _m4[5] = ey.dy;
      _m4[10] = 1;
      _m4[12] = p0.dx;
      _m4[13] = p0.dy;
      _m4[15] = 1;

      canvas.save();
      canvas.transform(_m4);

      if (stretchVel > 0.001) {
        // Stretch along normalize(cross(center, rotationAxis)) projected into
        // the disc's local frame — same direction the GL rim smear uses.
        final _V3 sd = _V3.cross(center, control.rotationAxis).normalized();
        if (sd.length > 0.5) {
          final double lx = _V3.dot(sd, xAxis), ly = _V3.dot(sd, yAxis);
          final double len = math.sqrt(lx * lx + ly * ly);
          if (len > 1e-6) {
            final double angle = math.atan2(ly / len, lx / len);
            final double k = 1 + stretchVel / fs;
            canvas.rotate(angle);
            canvas.scale(k, 1);
            canvas.rotate(-angle);
          }
        }
      }

      canvas.clipPath(_unitDisc, doAntiAlias: true);

      final int imageIndex = itemCount > 0 ? i % itemCount : -1;
      final ImageInfo? info = imageIndex >= 0 && imageIndex < images.length
          ? images[imageIndex]
          : null;
      if (info != null) {
        final ui.Image img = info.image;
        final double side =
            math.min(img.width, img.height).toDouble(); // center square crop
        final Rect src = Rect.fromCenter(
          center: Offset(img.width / 2, img.height / 2),
          width: side,
          height: side,
        );
        _imagePaint.filterQuality = filterQuality;
        canvas.drawImageRect(
            img, src, const Rect.fromLTRB(-1, -1, 1, 1), _imagePaint);
      } else {
        // Image not resolved yet (or no items): flat placeholder disc.
        _placeholderPaint.color = const Color(0xFF2A2A2E);
        canvas.drawRect(const Rect.fromLTRB(-1, -1, 1, 1), _placeholderPaint);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InfiniteMenuPainter oldDelegate) =>
      oldDelegate.images != images ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.filterQuality != filterQuality ||
      oldDelegate.itemCount != itemCount;
}
