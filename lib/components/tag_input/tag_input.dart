/// TagInput
/// Origin: reimplemented — kinetics "Tag Input" (Interaction & Input),
///   https://github.com/ckissi/kinetics — thông số + hành vi quan sát, dựng lại
/// Deps: flutter only
/// Flutter: 3.44.0
/// Entry file. Copy cả folder này sang project khác là dùng được.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tag/token input: submitting text pops an amber chip in from scale 0.4
/// with a spring; × (or Backspace in the empty field, where the platform
/// reports it) pops it back out with a quick scale-down fade. The container
/// border highlights while the field has focus.
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    this.initialTags = const <String>['design', 'motion'],
    this.hintText = 'Add tag…',
    this.width = 240,
    this.backgroundColor = const Color(0xFF232326),
    this.borderColor = const Color(0xFF2A2A2E),
    this.focusBorderColor = const Color(0xFFFF8A00),
    this.tagColor = const Color(0xFFFF8A00),
    this.tagTextColor = const Color(0xFF0E0E10),
    this.textColor = const Color(0xFFEDE9E0),
    this.hintColor = const Color(0xFF6E6C68),
    this.onChanged,
    this.animate = true,
  });

  final List<String> initialTags;
  final String hintText;
  final double width;
  final Color backgroundColor;
  final Color borderColor;
  final Color focusBorderColor;
  final Color tagColor;
  final Color tagTextColor;
  final Color textColor;
  final Color hintColor;

  /// Fires with the current tag list after every add/remove.
  final ValueChanged<List<String>>? onChanged;

  /// False applies adds/removes immediately.
  final bool animate;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> with TickerProviderStateMixin {
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  final List<_TagEntry> _entries = <_TagEntry>[];
  final TextEditingController _field = TextEditingController();
  final FocusNode _focus = FocusNode();
  int _nextId = 0;

  bool get _motionEnabled =>
      widget.animate &&
      !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  @override
  void initState() {
    super.initState();
    for (final String tag in widget.initialTags) {
      _entries.add(_createEntry(tag, staticEntry: true));
    }
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final _TagEntry entry in _entries) {
      entry.dispose();
    }
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  _TagEntry _createEntry(String text, {bool staticEntry = false}) {
    final _TagEntry entry = _TagEntry(
      id: _nextId++,
      text: text,
      enter: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
      exit: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
      ),
    );
    if (staticEntry) entry.enter.value = 1;
    return entry;
  }

  void _add(String raw) {
    final String text = raw.trim();
    _field.clear();
    _focus.requestFocus();
    if (text.isEmpty) return;
    final _TagEntry entry = _createEntry(text);
    setState(() => _entries.add(entry));
    if (_motionEnabled) {
      entry.enter.forward(from: 0);
    } else {
      entry.enter.value = 1;
    }
    _notify();
  }

  void _remove(_TagEntry entry) {
    if (entry.removing) return;
    entry.removing = true;
    if (mounted) setState(() {});
    if (!_motionEnabled) {
      _drop(entry);
      return;
    }
    entry.exit.forward(from: 0).then((_) {
      if (mounted && _entries.contains(entry)) _drop(entry);
    });
    _notify();
  }

  void _drop(_TagEntry entry) {
    if (!_entries.remove(entry)) return;
    entry.dispose();
    if (mounted) setState(() {});
  }

  void _notify() {
    widget.onChanged?.call(<String>[
      for (final _TagEntry entry in _entries)
        if (!entry.removing) entry.text,
    ]);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _field.text.isEmpty) {
      final Iterable<_TagEntry> live = _entries.where((e) => !e.removing);
      if (live.isNotEmpty) _remove(live.last);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _motionEnabled
          ? const Duration(milliseconds: 250)
          : Duration.zero,
      curve: Curves.ease,
      width: widget.width,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(
          color: _focus.hasFocus ? widget.focusBorderColor : widget.borderColor,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focus.requestFocus,
        child: Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (final _TagEntry entry in _entries) _tag(entry),
            // The original field flexes into the remaining row space; a Wrap
            // has no flexible children, so it gets a fixed slot instead.
            SizedBox(
              width: 96,
              child: Focus(
                onKeyEvent: _onKeyEvent,
                child: TextField(
                  controller: _field,
                  focusNode: _focus,
                  onSubmitted: _add,
                  textInputAction: TextInputAction.done,
                  cursorColor: widget.focusBorderColor,
                  style: TextStyle(fontSize: 13, color: widget.textColor),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: widget.hintColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(_TagEntry entry) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[entry.enter, entry.exit]),
      builder: (context, child) {
        final double entered = _spring.transform(entry.enter.value);
        final double exited = Curves.ease.transform(entry.exit.value);
        return Opacity(
          opacity: ((entry.enter.value) * (1 - exited)).clamp(0, 1),
          child: Transform.scale(
            scale: 0.4 + 0.6 * entered - 0.6 * exited * entered,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.only(left: 11, right: 6, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: widget.tagColor,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              entry.text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: widget.tagTextColor,
              ),
            ),
            const SizedBox(width: 5),
            Semantics(
              button: true,
              label: 'Remove ${entry.text}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _remove(entry),
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF000000).withValues(alpha: 0.18),
                  ),
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      color: widget.tagTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagEntry {
  _TagEntry({
    required this.id,
    required this.text,
    required this.enter,
    required this.exit,
  });

  final int id;
  final String text;
  final AnimationController enter;
  final AnimationController exit;
  bool removing = false;

  void dispose() {
    enter.dispose();
    exit.dispose();
  }
}
