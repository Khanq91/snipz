// Carrier switcher (spec §8.5, Phase 3): horizontally scrolling chip row —
// never wrapping — that puts a `kind: paint` component on each carrier.
//
// Chip states: verified (normal) / failed (disabled + tooltip with the reason
// from carriers_failed) / untested (dimmed, tap to try) / unavailable
// (disabled — paint has no Shader and no carrierBuilder for this carrier).
//
// The `text` carrier is absolutely lazy (§9.2): it costs a saveLayer per
// frame, so it renders only after its chip is tapped — never by default.

import 'package:flutter/material.dart';

import 'package:snipz/core/carrier_hosts.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';

/// Detail-density hint per carrier (§9.1), wired into the shader factory.
/// Small carriers get more detail cycles so the paint stays legible.
const Map<Carrier, double> carrierScaleHint = {
  Carrier.fullscreen: 1.0,
  Carrier.card: 1.0,
  Carrier.button: 2.0,
  Carrier.text: 2.0,
  Carrier.border: 2.0,
  Carrier.icon: 3.0,
  Carrier.divider: 2.0,
};

enum _ChipState { verified, untested, failed, unavailable }

class CarrierSwitcher extends StatefulWidget {
  const CarrierSwitcher({super.key, required this.meta, required this.demo});

  final ComponentMeta meta;
  final ComponentDemo demo;

  @override
  State<CarrierSwitcher> createState() => _CarrierSwitcherState();
}

class _CarrierSwitcherState extends State<CarrierSwitcher> {
  Carrier _selected = Carrier.fullscreen;

  _ChipState _stateOf(Carrier carrier) {
    if (widget.meta.carriersFailed.containsKey(carrier)) {
      return _ChipState.failed;
    }
    if (!_renderable(carrier)) return _ChipState.unavailable;
    if (widget.meta.carriersVerified.contains(carrier)) {
      return _ChipState.verified;
    }
    return _ChipState.untested;
  }

  bool _renderable(Carrier carrier) {
    if (carrier == Carrier.fullscreen) return true;
    if (widget.demo.carrierBuilders.containsKey(carrier)) return true;
    if (widget.demo.shader != null) return true;
    return WidgetCarrierStage.supported.contains(carrier);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: ClipRect(child: _stage(context))),
        _chipRow(),
      ],
    );
  }

  Widget _stage(BuildContext context) {
    final ComponentDemo demo = widget.demo;
    // Fullscreen is the component's own demo — the most faithful rendering.
    if (_selected == Carrier.fullscreen) {
      return KeyedSubtree(
        key: carrierStageKey(Carrier.fullscreen),
        child: demo.builder(context),
      );
    }
    final WidgetBuilder? handBuilt = demo.carrierBuilders[_selected];
    if (handBuilt != null) {
      return KeyedSubtree(
        key: carrierStageKey(_selected),
        child: handBuilt(context),
      );
    }
    final CarrierShaderSpec? spec = demo.shader;
    if (spec != null) {
      return ShaderCarrierStage(
        // Key restarts prepare per carrier — each stage owns its handle.
        key: ValueKey('shader-${_selected.wire}'),
        spec: spec,
        carrier: _selected,
        scale: carrierScaleHint[_selected] ?? 1.0,
      );
    }
    return WidgetCarrierStage(builder: demo.builder, carrier: _selected);
  }

  Widget _chipRow() {
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (final Carrier carrier in Carrier.values) ...[
              _chip(carrier),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(Carrier carrier) {
    final _ChipState state = _stateOf(carrier);
    final String label =
        carrier.wire[0].toUpperCase() + carrier.wire.substring(1);
    final bool enabled =
        state == _ChipState.verified || state == _ChipState.untested;

    Widget chip = ChoiceChip(
      key: ValueKey('carrier-chip-${carrier.wire}'),
      label: Text(label),
      selected: _selected == carrier,
      onSelected: enabled
          ? (_) => setState(() => _selected = carrier)
          : null,
    );
    // Untested: dimmed but tappable — tap to try (§8.5).
    if (state == _ChipState.untested) {
      chip = Opacity(opacity: 0.55, child: chip);
    }
    // Disabled chips explain themselves on long-press.
    if (state == _ChipState.failed) {
      chip = Tooltip(
        message: widget.meta.carriersFailed[carrier]!,
        triggerMode: TooltipTriggerMode.tap,
        child: chip,
      );
    } else if (state == _ChipState.unavailable) {
      chip = Tooltip(
        message: 'Paint không expose Shader — cần carrierBuilder',
        triggerMode: TooltipTriggerMode.tap,
        child: chip,
      );
    }
    return chip;
  }
}
