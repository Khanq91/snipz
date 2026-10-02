/// Coucou Mochi
/// Origin: adapted for private study from Coucou's Canvas bot engine.
/// Deps: flutter, audioplayers
/// Flutter: 3.44.5
/// Entry file. Copy this folder and declare its audio folder in pubspec.yaml.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '_audio.dart';
import '_engine.dart';
import '_painter.dart';

export '_audio.dart';
export '_engine.dart';
export '_painter.dart';

/// Emotes that can be requested through [CoucouMochiController].
enum CoucouMochiEmote { love, surprised, proud, wink, yawn, happy, annoyed }

enum _MochiCommandType { greet, emote, gulp }

class _MochiCommand {
  const _MochiCommand(this.revision, this.type, [this.emote]);

  final int revision;
  final _MochiCommandType type;
  final CoucouMochiEmote? emote;
}

/// Sends one-shot character actions to a [CoucouMochi].
///
/// Keep the controller with the owner of the widget and dispose it when no
/// longer needed. If a command is sent before the widget mounts, the latest
/// command is applied when it attaches.
class CoucouMochiController extends ChangeNotifier {
  int _revision = 0;
  _MochiCommand? _command;

  void greet() => _send(_MochiCommandType.greet);

  void emote(CoucouMochiEmote emote) => _send(_MochiCommandType.emote, emote);

  void gulp() => _send(_MochiCommandType.gulp);

  void _send(_MochiCommandType type, [CoucouMochiEmote? emote]) {
    _command = _MochiCommand(++_revision, type, emote);
    notifyListeners();
  }
}

/// An interactive Canvas recreation of Coucou's Mochi desktop companion.
///
/// The body, face, status badges, emotes, hands, and particles are procedural.
/// Tap Mochi to poke it; three taps within 1.7 seconds make it dizzy. Touch
/// and hold for the love emote. A mouse hover follows the desktop behavior.
class CoucouMochi extends StatefulWidget {
  const CoucouMochi({
    super.key,
    this.size = 220,
    this.state = CoucouMochiState.idle,
    this.controller,
    this.frozenAt,
    this.animate = true,
    this.interactive = true,
    this.soundEnabled = true,
    this.volume = .12,
    this.greetingOnStart = false,
    this.morph = 0,
    this.backgroundColor = const Color(0xFF080A10),
    this.onSound,
    this.onDizzy,
  }) : assert(size > 0),
       assert(volume >= 0 && volume <= 1),
       assert(morph >= 0 && morph <= 1);

  /// Width of the drawing area in logical pixels. Height is 1.28 times this
  /// value to leave room for the particles that float above Mochi.
  final double size;

  /// Live state supplied by the host. State changes use Coucou's color, eye,
  /// badge, and entry reactions.
  final CoucouMochiState state;

  /// Optional one-shot controls for greeting, emotes, and gulp animation.
  final CoucouMochiController? controller;

  /// Render one deterministic frame and keep the ticker stopped.
  final double? frozenAt;

  /// TickerMode still applies when true; false freezes the current time.
  final bool animate;

  /// Enable tap, touch-hold, gaze, and mouse-hover reactions.
  final bool interactive;

  /// Play the copied Coucou WAV effects.
  final bool soundEnabled;

  /// Coucou's default is 0.12; accepted range is 0 to 1.
  final double volume;

  /// Play the greeting choreography once when the widget mounts.
  final bool greetingOnStart;

  /// Morph between Mochi and the mailbox shape, from 0 to 1.
  final double morph;

  /// Reference background behind the component, for previews and embedding.
  final Color backgroundColor;

  /// Called for each requested sound even when playback is disabled.
  final ValueChanged<String>? onSound;

  /// Called when three quick taps trigger the dizzy reaction.
  final VoidCallback? onDizzy;

  @override
  State<CoucouMochi> createState() => _CoucouMochiState();
}

class _CoucouMochiState extends State<CoucouMochi>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final CoucouMochiEngine _engine = CoucouMochiEngine();
  final CoucouMochiAudio _audio = CoucouMochiAudio();
  final ValueNotifier<CoucouMochiFrame> _frameSignal =
      ValueNotifier<CoucouMochiFrame>(CoucouMochiEngine().sample(0));
  Timer? _hoverTimer;
  Duration? _lastTick;
  double _clock = 0;
  bool _loveFromHover = false;
  int _lastCommandRevision = 0;

  bool get _frozen => widget.frozenAt != null || !widget.animate;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_consumeControllerCommand);
    _engine.setState(widget.state, 0, force: true);
    _engine.setMorph(widget.morph, 0);
    if (widget.greetingOnStart) _engine.greet(0);
    _frameSignal.value = _engine.sample(widget.frozenAt ?? 0);
    _ticker = createTicker(_tick);
    if (!_frozen) _ticker.start();
    if (widget.greetingOnStart) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _play('greet');
      });
    }
    _consumeControllerCommand();
  }

  void _tick(Duration elapsed) {
    final Duration previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    _clock += ((elapsed - previous).inMicroseconds / 1e6)
        .clamp(0.0, .064)
        .toDouble();
    _frameSignal.value = _engine.sample(_clock);
  }

  @override
  void didUpdateWidget(CoucouMochi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_consumeControllerCommand);
      _lastCommandRevision = 0;
      widget.controller?.addListener(_consumeControllerCommand);
      _consumeControllerCommand();
    }
    if (oldWidget.state != widget.state) {
      _engine.setState(widget.state, _clock);
      _play(_soundFor(widget.state));
    }
    if (oldWidget.morph != widget.morph) {
      _engine.setMorph(widget.morph, _clock);
      if (widget.morph > .5) _play('pop');
    }
    if (oldWidget.greetingOnStart != widget.greetingOnStart &&
        widget.greetingOnStart) {
      _engine.greet(_clock);
      _play('greet');
    }
    if (_frozen) {
      if (_ticker.isActive) _ticker.stop();
      _lastTick = null;
      _frameSignal.value = _engine.sample(widget.frozenAt ?? _clock);
    } else if (!_ticker.isActive) {
      _lastTick = null;
      _ticker.start();
    }
  }

  String? _soundFor(CoucouMochiState state) => switch (state) {
    CoucouMochiState.working => 'work',
    CoucouMochiState.thinking => 'think',
    CoucouMochiState.searching => 'search',
    CoucouMochiState.approval => 'approval',
    CoucouMochiState.question => 'question',
    CoucouMochiState.error => 'error',
    CoucouMochiState.finished => 'finish',
    CoucouMochiState.ratelimit => 'rate',
    CoucouMochiState.sleeping => 'sleep',
    CoucouMochiState.dizzy => 'dizzy',
    CoucouMochiState.idle => null,
  };

  void _play(String? name) {
    if (name == null) return;
    widget.onSound?.call(name);
    if (widget.soundEnabled)
      unawaited(_audio.play(name, volume: widget.volume));
  }

  void _tap() {
    if (!_canInteract) return;
    final bool dizzy = _engine.tap(_clock);
    _frameSignal.value = _engine.sample(_clock);
    if (dizzy) {
      _play('dizzy');
      widget.onDizzy?.call();
    } else {
      _play('slap');
      Future<void>.delayed(const Duration(milliseconds: 60), () {
        if (mounted) _play('annoyed');
      });
    }
  }

  void _love() {
    if (!_canInteract) return;
    _engine.triggerEmote('love', _clock);
    _frameSignal.value = _engine.sample(_clock);
    _play(_loveFromHover ? 'hover' : 'love');
    _loveFromHover = false;
  }

  void _startHover(PointerEnterEvent _) {
    if (!_canInteract) return;
    _engine.setHover(true, _clock);
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !_canInteract) return;
      _loveFromHover = true;
      _love();
    });
  }

  void _endHover(PointerExitEvent _) {
    _hoverTimer?.cancel();
    _engine.setHover(false, _clock);
    _loveFromHover = false;
  }

  void _look(Offset local) {
    if (!_canInteract) return;
    final double w = widget.size;
    final double h = widget.size * 1.28;
    final double x = math.tanh((local.dx - w / 2) / 260);
    final double y = -math.tanh((local.dy - h / 2) / 200);
    _engine.setLook(x, y, _clock);
    _frameSignal.value = _engine.sample(_clock);
  }

  void _greet() {
    _engine.greet(_clock);
    _frameSignal.value = _engine.sample(_clock);
    _play('greet');
  }

  void _triggerEmote(String emote) {
    _engine.triggerEmote(emote, _clock);
    _frameSignal.value = _engine.sample(_clock);
    _play(switch (emote) {
      'love' => 'love',
      'proud' => 'proud',
      'wink' => 'wink',
      'yawn' => 'yawn',
      'annoyed' => 'annoyed',
      _ => 'pop',
    });
  }

  void _consumeControllerCommand() {
    final _MochiCommand? command = widget.controller?._command;
    if (command == null || command.revision == _lastCommandRevision) return;
    _lastCommandRevision = command.revision;
    if (_frozen) return;
    switch (command.type) {
      case _MochiCommandType.greet:
        _greet();
        break;
      case _MochiCommandType.emote:
        _triggerEmote(command.emote!.name);
        break;
      case _MochiCommandType.gulp:
        _engine.gulp(_clock);
        _frameSignal.value = _engine.sample(_clock);
        _play('gulp');
        break;
    }
  }

  bool get _canInteract => widget.interactive && !_frozen;

  @override
  void dispose() {
    widget.controller?.removeListener(_consumeControllerCommand);
    _hoverTimer?.cancel();
    _ticker.dispose();
    _frameSignal.dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget illustration = CustomPaint(
      size: Size(widget.size, widget.size * 1.28),
      painter: _FramePainter(
        frames: _frameSignal,
        backgroundColor: widget.backgroundColor,
      ),
    );
    return MouseRegion(
      onEnter: _canInteract ? _startHover : null,
      onExit: _canInteract ? _endHover : null,
      onHover: _canInteract ? (event) => _look(event.localPosition) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canInteract ? _tap : null,
        onLongPress: _canInteract ? _love : null,
        onPanUpdate: _canInteract
            ? (details) => _look(details.localPosition)
            : null,
        child: illustration,
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.frames, required this.backgroundColor})
    : super(repaint: frames);

  final ValueListenable<CoucouMochiFrame> frames;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    CoucouMochiPainter(
      frame: frames.value,
      backgroundColor: backgroundColor,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.frames != frames ||
      oldDelegate.backgroundColor != backgroundColor;
}
