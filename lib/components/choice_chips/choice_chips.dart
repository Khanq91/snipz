/// PopChips ("Choice Chips")
/// Origin: reimplemented — kinetics "Choice Chips" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
/// (Class là PopChips — tránh trùng ChoiceChip của Material.)
library;

import 'package:flutter/widgets.dart';

/// Row of multi-select filter chips that pop (scale 1.12, spring) on every
/// toggle while their colors crossfade. Controlled: the parent owns
/// [selected] and rebuilds in [onChanged].
class PopChips extends StatelessWidget {
  const PopChips({
    super.key,
    this.options = const <String>['Spring', 'Glide', 'Bounce', 'Decay'],
    this.selected = const <String>{},
    required this.onChanged,
    this.spacing = 8,
    this.borderColor = const Color(0xFF2A2A2E),
    this.labelColor = const Color(0xFFA8A6A0),
    this.selectedColor = const Color(0xFFFF8A00),
    this.selectedLabelColor = const Color(0xFF0E0E10),
    this.animate = true,
  });

  final List<String> options;
  final Set<String> selected;

  /// Receives a NEW set with the tapped option toggled. Null = disabled.
  final ValueChanged<Set<String>>? onChanged;
  final double spacing;
  final Color borderColor;
  final Color labelColor;
  final Color selectedColor;
  final Color selectedLabelColor;

  /// False applies state changes immediately, without the pop.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final String option in options)
          _PopChip(
            label: option,
            selected: selected.contains(option),
            onTap: onChanged == null ? null : () => _toggle(option),
            borderColor: borderColor,
            labelColor: labelColor,
            selectedColor: selectedColor,
            selectedLabelColor: selectedLabelColor,
            animate: animate,
          ),
      ],
    );
  }

  void _toggle(String option) {
    final Set<String> next = Set<String>.of(selected);
    if (!next.remove(option)) next.add(option);
    onChanged!(next);
  }
}

/// One chip. Owns only its transient pop (300ms hold, like the original
/// setTimeout); the on/off state stays with the parent.
class _PopChip extends StatefulWidget {
  const _PopChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.borderColor,
    required this.labelColor,
    required this.selectedColor,
    required this.selectedLabelColor,
    required this.animate,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color borderColor;
  final Color labelColor;
  final Color selectedColor;
  final Color selectedLabelColor;
  final bool animate;

  @override
  State<_PopChip> createState() => _PopChipState();
}

class _PopChipState extends State<_PopChip>
    with SingleTickerProviderStateMixin {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  late final AnimationController _popHold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  bool _popped = false;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    _popHold.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _popped = false);
      }
    });
  }

  @override
  void dispose() {
    _popHold.dispose();
    super.dispose();
  }

  void _tap() {
    if (_motionEnabled) {
      setState(() => _popped = true);
      _popHold.forward(from: 0);
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final Duration popDuration = _motionEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;
    final Duration colorDuration = _motionEnabled
        ? const Duration(milliseconds: 200)
        : Duration.zero;

    return Semantics(
      button: true,
      toggled: widget.selected,
      enabled: widget.onTap != null,
      onTap: widget.onTap == null ? null : _tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null ? null : _tap,
        child: AnimatedScale(
          scale: _popped ? 1.12 : 1,
          duration: popDuration,
          curve: _spring,
          child: AnimatedContainer(
            duration: colorDuration,
            curve: Curves.ease,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
            decoration: BoxDecoration(
              color: widget.selected ? widget.selectedColor : null,
              border: Border.all(
                color: widget.selected
                    ? widget.selectedColor
                    : widget.borderColor,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: AnimatedDefaultTextStyle(
              duration: colorDuration,
              curve: Curves.ease,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: widget.selected
                    ? widget.selectedLabelColor
                    : widget.labelColor,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
