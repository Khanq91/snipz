// Preview stage per component kind (spec §8.5):
//   paint             -> full-stage preview (carrier switcher is Phase 3)
//   carrier/composite -> padded frame + local light/dark toggle
//   effect            -> sample target + effect on/off toggle
// Checkerboard and device frame are later phases.

import 'package:flutter/material.dart';
import 'package:snipz/app/theme.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';

class PreviewStage extends StatefulWidget {
  const PreviewStage({super.key, required this.meta, required this.demo});

  final ComponentMeta meta;

  /// Null when the registry has no entry for this id (drift is caught by
  /// validate.dart; the stage must still not crash).
  final ComponentDemo? demo;

  @override
  State<PreviewStage> createState() => _PreviewStageState();
}

class _PreviewStageState extends State<PreviewStage> {
  bool _dark = false;
  bool _effectOn = true;

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

  /// Paint fills the whole stage — closest to its fullscreen carrier.
  Widget _paintStage(ComponentDemo demo) =>
      ClipRect(child: demo.builder(context));

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
            child: ColoredBox(
              color: stageTheme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: demo.builder(context),
                ),
              ),
            ),
          ),
        ),
        _controlBar(
          children: [
            const Text('Stage'),
            const Spacer(),
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

  Widget _effectStage(ComponentDemo demo) {
    return Column(
      children: [
        Expanded(
          child: _effectOn ? ClipRect(child: demo.builder(context)) : _target(),
        ),
        _controlBar(
          children: [
            const Text('Effect'),
            const Spacer(),
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
