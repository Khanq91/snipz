import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '_audio.dart';
import '_greeting.dart';
import '_upload.dart';
import '_upload_painter.dart';

enum CoucouMochiSceneType { launch, upload }

/// The upstream launch and upload choreographies in their reference spaces.
/// Upload is a local animation preview; it does not send a file anywhere.
/// Drag to make the mailbox follow, release to swallow. Tap to replay.
class CoucouMochiScene extends StatefulWidget {
  const CoucouMochiScene({
    super.key,
    required this.type,
    this.width = 640,
    this.frozenAt,
    this.soundEnabled = true,
    this.volume = .12,
    this.onSound,
    this.onComplete,
  }) : assert(width > 0),
       assert(volume >= 0 && volume <= 1);
  final CoucouMochiSceneType type;
  final double width;
  final double? frozenAt;
  final bool soundEnabled;
  final double volume;
  final ValueChanged<String>? onSound;
  final VoidCallback? onComplete;
  @override
  State<CoucouMochiScene> createState() => _CoucouMochiSceneState();
}

class _CoucouMochiSceneState extends State<CoucouMochiScene>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _audio = CoucouMochiAudio();
  CoucouMochiUploadEngine _upload = CoucouMochiUploadEngine();
  double _time = 0, _previous = -.001;
  double? _collapse;
  Duration? _last;
  bool _complete = false,
      _dropCuePlayed = false,
      _dragging = false,
      _holdLaunch = false,
      _tickerEnabled = true;
  @override
  void initState() {
    super.initState();
    _seedUpload();
    _ticker = createTicker(_tick);
    if (widget.frozenAt == null) _ticker.start();
  }

  void _seedUpload() {
    _upload = CoucouMochiUploadEngine()
      ..enter(0, 220, 78)
      ..move(.2, 180, 88)
      ..drop(.8);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled != _tickerEnabled) {
      _last = null;
      _tickerEnabled = enabled;
    }
  }

  @override
  void didUpdateWidget(CoucouMochiScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) _reset();
    if (widget.frozenAt != null) {
      _ticker.stop();
      _last = null;
    } else if (!_ticker.isActive && !_complete) {
      _last = null;
      _ticker.start();
    }
  }

  void _reset() {
    _time = 0;
    _previous = -.001;
    _collapse = null;
    _complete = false;
    _dropCuePlayed = false;
    _last = null;
    _dragging = false;
    _holdLaunch = false;
    _seedUpload();
    if (widget.frozenAt == null && !_ticker.isActive) _ticker.start();
  }

  void _play(String name) {
    if (widget.frozenAt != null || !_tickerEnabled) return;
    widget.onSound?.call(name);
    if (widget.soundEnabled) {
      unawaited(_audio.play(name, volume: widget.volume));
    }
  }

  void _tick(Duration elapsed) {
    _time += (elapsed - (_last ?? elapsed)).inMicroseconds / 1e6;
    _last = elapsed;
    void cue(double at, String name) {
      if (_previous < at && _time >= at) _play(name);
    }

    if (widget.type == CoucouMochiSceneType.launch) {
      if (_collapse == null) {
        cue(1.36, 'greet');
        cue(2.72, 'blip');
      }
      if (!_holdLaunch && _collapse == null && _time >= 4.9) _collapse = 4.9;
      if (_collapse != null && _time >= _collapse! + .42) _finish();
    } else {
      final drop = _upload.dropAt;
      if (drop != null) {
        if (!_dropCuePlayed && _time >= drop) {
          _dropCuePlayed = true;
          _play('approve');
        }
        for (int n = 1; n <= 9; n++) {
          cue(drop + 1.3 + n * .24, 'tick');
        }
        cue(drop + 3.7, 'approve');
        if (_time >= drop + 5.1) _finish();
      }
    }
    _previous = _time;
    setState(() {});
  }

  void _finish() {
    if (_complete) return;
    _complete = true;
    _ticker.stop();
    widget.onComplete?.call();
  }

  Offset _local(Offset p) => p * (640 / widget.width);
  void _startDrag(DragStartDetails d) {
    if (widget.type != CoucouMochiSceneType.upload || widget.frozenAt != null) {
      return;
    }
    _reset();
    _dragging = true;
    final p = _local(d.localPosition);
    _upload = CoucouMochiUploadEngine()..enter(0, p.dx, p.dy);
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.frozenAt ?? _time;
    final launch = widget.type == CoucouMochiSceneType.launch;
    final h = launch ? 150.0 : 176.0;
    final painter = launch
        ? CoucouMochiGreetingPainter(
            time: t,
            collapseAt: widget.frozenAt != null
                ? (t >= 4.9 ? 4.9 : null)
                : _collapse,
          )
        : CoucouMochiUploadPainter(frame: _upload.sample(t));
    return MouseRegion(
      onEnter: launch && widget.frozenAt == null
          ? (PointerEnterEvent _) {
              _holdLaunch = true;
            }
          : null,
      onExit: launch && widget.frozenAt == null
          ? (PointerExitEvent _) {
              _holdLaunch = false;
              _collapse ??= _time;
            }
          : null,
      child: GestureDetector(
        onTap: widget.frozenAt != null
            ? null
            : () {
                setState(_reset);
              },
        onPanStart: widget.frozenAt != null || launch ? null : _startDrag,
        onPanUpdate: widget.frozenAt != null || launch
            ? null
            : (d) {
                if (!_dragging) return;
                final p = _local(d.localPosition);
                _upload.move(_time, p.dx, p.dy);
              },
        onPanEnd: widget.frozenAt != null || launch
            ? null
            : (_) {
                if (_dragging) {
                  _dragging = false;
                  _upload.drop(_time);
                }
              },
        onPanCancel: widget.frozenAt != null || launch
            ? null
            : () {
                if (_dragging) {
                  _dragging = false;
                  _upload.drop(_time);
                }
              },
        child: CustomPaint(
          size: Size(widget.width, widget.width * h / 640),
          painter: painter,
        ),
      ),
    );
  }
}
