// Preview stage per component kind (spec §8.5):
//   paint             -> carrier switcher (Phase 3)
//   carrier/composite -> padded frame + local light/dark toggle
//   effect            -> sample target + effect on/off toggle
// Common to all kinds: checkerboard, freeze (TickerMode) and — when the demo
// declares variants — a variant chip row (bloub-style state switching, with
// `?variant=&frozen=` deep links).

import 'package:flutter/material.dart';
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

class _PreviewStageState extends State<PreviewStage> {
  bool _dark = false;
  bool _effectOn = true;
  bool _checkerboard = false;
  late bool _frozen = widget.initialFrozen;
  late String? _variantId = widget.initialVariantId;

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
    return TickerMode(enabled: !_frozen, child: Builder(builder: live));
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
        children: [const Text('Paint'), const Spacer(), _freezeButton()],
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
        if (demo.variants.isNotEmpty) _variantRow(demo),
        _controlBar(
          children: [
            const Text('Stage'),
            const Spacer(),
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
    onPressed: () => setState(() => _frozen = !_frozen),
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
              onSelected: (_) => setState(() => _variantId = v.id),
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
        if (demo.variants.isNotEmpty) _variantRow(demo),
        _controlBar(
          children: [
            const Text('Effect'),
            const Spacer(),
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
