// Preview stage per component kind (spec §8.5):
//   paint             -> carrier switcher (Phase 3)
//   carrier/composite -> padded frame + local light/dark toggle
//   effect            -> sample target + effect on/off toggle
// Common to all kinds: checkerboard, freeze (TickerMode), a slow-motion
// speed toggle (GSDevTools-style, via scheduler timeDilation — reset on
// dispose), a time scrubber when the demo declares a sample(t)
// `scrubBuilder`, and — when the demo declares variants — a variant chip
// row (bloub-style state switching, with `?variant=&frozen=` deep links).

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:snipz/app/theme.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/carrier_switcher.dart';

class PreviewStage extends StatefulWidget {
  const PreviewStage({
    super.key,
    required this.meta,
    required this.demo,
    this.initialVariantId,
    this.initialFrozen = false,
  });

  final ComponentMeta meta;

  /// Null when the registry has no entry for this id (drift is caught by
  /// validate.dart; the stage must still not crash).
  final ComponentDemo? demo;

  /// Deep-link entry (`?variant=` / `&frozen=1`): open on this variant,
  /// frozen or not.
  final String? initialVariantId;
  final bool initialFrozen;

  @override
  State<PreviewStage> createState() => _PreviewStageState();
}

class _PreviewStageState extends State<PreviewStage>
    with SingleTickerProviderStateMixin {
  /// Slow-motion presets cycled by the speed button (× of real time). The
  /// same factor drives live playback (via timeDilation) and the scrub
  /// player (via the tick advance below).
  static const List<double> _speeds = [1, 0.5, 0.25, 0.1, 2];
  static const double _frameStep = 1 / 60;

  /// Session-only per-component scrub settings (GSDevTools' `persist`,
  /// deliberately in-memory: closing the app resets them).
  static final Map<String, ({int speedIndex, double inT, double outT})>
      _sessionPrefs = {};

  bool _dark = false;
  bool _effectOn = true;
  bool _checkerboard = false;
  late bool _frozen = widget.initialFrozen;
  late String? _variantId = widget.initialVariantId;
  int _speedIndex = 0;
  double _scrubT = 0;

  // Scrub player: a stage-owned clock over the demo's sample(t) hook — the
  // component renders deterministic frames, the stage owns time.
  late final Ticker _scrubTicker;
  Duration? _scrubLastTick;
  bool _scrubPlaying = false;
  double _inT = 0;
  double _outT = 1;

  double get _scrubDuration => widget.demo?.scrubDuration ?? 1;

  @override
  void initState() {
    super.initState();
    _scrubTicker = createTicker(_handleScrubTick);
    _outT = _scrubDuration;
    final ({int speedIndex, double inT, double outT})? saved =
        _sessionPrefs[widget.meta.id];
    if (saved != null) {
      _speedIndex = saved.speedIndex.clamp(0, _speeds.length - 1);
      _inT = saved.inT.clamp(0.0, _scrubDuration);
      _outT = saved.outT.clamp(_inT + _frameStep, _scrubDuration);
      timeDilation = 1 / _speed;
    }
  }

  @override
  void dispose() {
    _saveSessionPrefs();
    _scrubTicker.dispose();
    // timeDilation is process-global — never leak slow motion past the stage.
    timeDilation = 1.0;
    super.dispose();
  }

  void _saveSessionPrefs() {
    _sessionPrefs[widget.meta.id] =
        (speedIndex: _speedIndex, inT: _inT, outT: _outT);
  }

  double get _speed => _speeds[_speedIndex];

  void _cycleSpeed() {
    setState(() {
      _speedIndex = (_speedIndex + 1) % _speeds.length;
      timeDilation = 1 / _speed;
      _saveSessionPrefs();
    });
  }

  /// The scrubber replaces the dead frozen frame when the default demo
  /// declares a sample(t) scrubBuilder and no variant is selected.
  bool _scrubbing(ComponentDemo demo) =>
      _frozen && _variantId == null && demo.scrubBuilder != null;

  // ---- scrub player -------------------------------------------------------

  void _handleScrubTick(Duration elapsed) {
    final Duration previous = _scrubLastTick ?? Duration.zero;
    _scrubLastTick = elapsed;
    final double delta = ((elapsed - previous).inMicroseconds / 1000000)
        .clamp(0.0, 0.064)
        .toDouble();
    setState(() {
      _scrubT += delta * _speed;
      final double window = _outT - _inT;
      if (_scrubT >= _outT) {
        // Loop inside the in/out window (GSDevTools in-point/out-point).
        _scrubT = window <= 0 ? _inT : _inT + (_scrubT - _inT) % window;
      }
    });
  }

  void _toggleScrubPlay() {
    setState(() {
      _scrubPlaying = !_scrubPlaying;
      if (_scrubPlaying) {
        if (_scrubT < _inT || _scrubT >= _outT) _scrubT = _inT;
        _scrubLastTick = Duration.zero;
        _scrubTicker.start();
      } else {
        _scrubTicker.stop();
        _scrubLastTick = null;
      }
    });
  }

  void _stopScrubPlay() {
    if (!_scrubPlaying) return;
    _scrubPlaying = false;
    _scrubTicker.stop();
    _scrubLastTick = null;
  }

  void _stepFrame(int direction) {
    setState(() {
      _stopScrubPlay();
      _scrubT = (_scrubT + direction * _frameStep).clamp(0.0, _scrubDuration);
    });
  }

  void _setWindow(double inT, double outT) {
    setState(() {
      _inT = inT;
      _outT = outT.clamp(inT + _frameStep, _scrubDuration);
      _saveSessionPrefs();
    });
  }

  DemoVariant? _variantOf(ComponentDemo demo) {
    final String? id = _variantId;
    if (id == null) return null;
    for (final DemoVariant v in demo.variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// The demo content honoring the selected variant and the freeze toggle.
  /// Frozen + a variant with a deterministic frame -> that frame; otherwise
  /// TickerMode stops every well-behaved ticker under it. (Known limit:
  /// components animating via Timer/Stream do not freeze — the authoring
  /// convention asks for tickers precisely for this.)
  Widget _content(ComponentDemo demo) {
    final DemoVariant? variant = _variantOf(demo);
    final WidgetBuilder live = variant?.builder ?? demo.builder;
    if (_frozen && variant?.frozenBuilder != null) {
      return variant!.frozenBuilder!(context);
    }
    if (_scrubbing(demo)) {
      // sample(t): a deterministic frame at the scrubbed time.
      return demo.scrubBuilder!(context, _scrubT);
    }
    return TickerMode(enabled: !_frozen, child: Builder(builder: live));
  }

  /// GSDevTools-style transport shown while scrubbing (freeze +
  /// scrubBuilder): play/pause looping inside the in/out window, ±1-frame
  /// steps, a playhead slider, and a compact RangeSlider defining the loop
  /// window. Keyboard (desktop niceties, no-op without one): space
  /// play/pause · ←/→ frame step · I/O set in/out at the playhead · R
  /// resets the window.
  Widget _scrubRow(ComponentDemo demo) {
    final TextStyle? label = Theme.of(context).textTheme.labelSmall;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): _toggleScrubPlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _stepFrame(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _stepFrame(1),
        const SingleActivator(LogicalKeyboardKey.keyI): () =>
            _setWindow(_scrubT, _outT),
        const SingleActivator(LogicalKeyboardKey.keyO): () =>
            _setWindow(_inT, _scrubT),
        const SingleActivator(LogicalKeyboardKey.keyR): () =>
            _setWindow(0, _scrubDuration),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('scrub-play'),
                    tooltip: _scrubPlaying ? 'Pause' : 'Play in/out loop',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _scrubPlaying ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    onPressed: _toggleScrubPlay,
                  ),
                  IconButton(
                    key: const ValueKey('scrub-step-back'),
                    tooltip: '-1 frame',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_arrow_left, size: 20),
                    onPressed: () => _stepFrame(-1),
                  ),
                  IconButton(
                    key: const ValueKey('scrub-step-fwd'),
                    tooltip: '+1 frame',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_arrow_right, size: 20),
                    onPressed: () => _stepFrame(1),
                  ),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('scrub-slider'),
                      value: _scrubT.clamp(0.0, demo.scrubDuration),
                      max: demo.scrubDuration,
                      onChangeStart: (_) => setState(_stopScrubPlay),
                      onChanged: (v) => setState(() => _scrubT = v),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${_scrubT.toStringAsFixed(2)}s',
                      style: label,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(_inT.toStringAsFixed(1), style: label),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: RangeSlider(
                        key: const ValueKey('scrub-window'),
                        values: RangeValues(
                          _inT,
                          _outT.clamp(_inT + _frameStep, demo.scrubDuration),
                        ),
                        max: demo.scrubDuration,
                        onChanged: (RangeValues v) =>
                            _setWindow(v.start, v.end),
                      ),
                    ),
                  ),
                  Text(_outT.toStringAsFixed(1), style: label),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slow-motion toggle — GSDevTools' timeScale, powered by the scheduler's
  /// global timeDilation so every well-behaved ticker follows.
  Widget _speedButton() {
    final String label = switch (_speed) {
      1 => '1×',
      2 => '2×',
      0.5 => '½×',
      0.25 => '¼×',
      _ => '$_speed×',
    };
    return TextButton(
      key: const ValueKey('toggle-speed'),
      onPressed: _cycleSpeed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: _speed == 1
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.primary,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ComponentDemo? demo = widget.demo;
    if (demo == null) {
      return const Center(child: Text('No demo registered for this id'));
    }
    return switch (widget.meta.kind) {
      Kind.paint => _paintStage(demo),
      Kind.carrier || Kind.composite => _framedStage(demo),
      Kind.effect => _effectStage(demo),
    };
  }

  /// Paint gets the carrier switcher (§8.5) — fullscreen chip by default.
  /// Freeze wraps the whole switcher: shader hosts run on tickers, so
  /// TickerMode stops them too.
  Widget _paintStage(ComponentDemo demo) => Column(
    children: [
      Expanded(
        child: TickerMode(
          enabled: !_frozen,
          child: CarrierSwitcher(meta: widget.meta, demo: demo),
        ),
      ),
      _controlBar(
        children: [
          const Text('Paint'),
          const Spacer(),
          _speedButton(),
          _freezeButton(),
        ],
      ),
    ],
  );

  Widget _framedStage(ComponentDemo demo) {
    final ThemeData stageTheme = buildTheme(
      _dark ? Brightness.dark : Brightness.light,
    );
    return Column(
      children: [
        Expanded(
          // Theme wraps the demo so components reading Theme.of(context)
          // follow the stage toggle, not the app theme.
          child: Theme(
            data: stageTheme,
            child: _stageBackground(
              surface: stageTheme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _content(demo),
                ),
              ),
            ),
          ),
        ),
        if (_scrubbing(demo)) _scrubRow(demo),
        if (demo.variants.isNotEmpty) _variantRow(demo),
        _controlBar(
          children: [
            const Text('Stage'),
            const Spacer(),
            _speedButton(),
            _freezeButton(),
            _checkerboardButton(),
            IconButton(
              tooltip: _dark ? 'Switch to light' : 'Switch to dark',
              icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ],
        ),
      ],
    );
  }

  /// Checkerboard reveals transparency (§8.5 common toggles).
  Widget _stageBackground({required Color surface, required Widget child}) =>
      _checkerboard
          ? CustomPaint(
              painter: const _CheckerboardPainter(),
              child: child,
            )
          : ColoredBox(color: surface, child: child);

  Widget _freezeButton() => IconButton(
    key: const ValueKey('toggle-freeze'),
    tooltip: _frozen ? 'Resume' : 'Freeze',
    isSelected: _frozen,
    icon: Icon(_frozen ? Icons.play_arrow : Icons.pause),
    onPressed: () => setState(() {
      _frozen = !_frozen;
      if (!_frozen) _stopScrubPlay(); // live mode owns time again
    }),
  );

  Widget _checkerboardButton() => IconButton(
    key: const ValueKey('toggle-checkerboard'),
    tooltip: 'Checkerboard background',
    isSelected: _checkerboard,
    icon: const Icon(Icons.grid_on_outlined),
    onPressed: () => setState(() => _checkerboard = !_checkerboard),
  );

  /// Variant chips: "Demo" is the component's own default preview; the rest
  /// come from the registry entry.
  Widget _variantRow(ComponentDemo demo) => SizedBox(
    height: 48,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ChoiceChip(
            key: const ValueKey('variant-chip-default'),
            label: const Text('Demo'),
            selected: _variantId == null,
            onSelected: (_) => setState(() => _variantId = null),
          ),
          for (final DemoVariant v in demo.variants) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              key: ValueKey('variant-chip-${v.id}'),
              label: Text(v.label),
              selected: _variantId == v.id,
              onSelected: (_) => setState(() {
                _variantId = v.id;
                _stopScrubPlay(); // variants hide the scrub transport
              }),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _effectStage(ComponentDemo demo) {
    return Column(
      children: [
        Expanded(
          child: _stageBackground(
            surface: Theme.of(context).colorScheme.surface,
            child: _effectOn
                ? ClipRect(child: _content(demo))
                : _target(),
          ),
        ),
        if (_effectOn && _scrubbing(demo)) _scrubRow(demo),
        if (demo.variants.isNotEmpty) _variantRow(demo),
        _controlBar(
          children: [
            const Text('Effect'),
            const Spacer(),
            _speedButton(),
            _freezeButton(),
            _checkerboardButton(),
            Switch(
              value: _effectOn,
              onChanged: (value) => setState(() => _effectOn = value),
            ),
          ],
        ),
      ],
    );
  }

  /// Bare comparison target shown while the effect is toggled off.
  Widget _target() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Sample target',
          style: TextStyle(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }

  Widget _controlBar({required List<Widget> children}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: children),
  );
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const double _cell = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint light = Paint()..color = const Color(0xFFCCCCCC);
    final Paint dark = Paint()..color = const Color(0xFF999999);
    for (int y = 0; (y * _cell) < size.height; y++) {
      for (int x = 0; (x * _cell) < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * _cell, y * _cell, _cell, _cell),
          (x + y).isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter oldDelegate) => false;
}
