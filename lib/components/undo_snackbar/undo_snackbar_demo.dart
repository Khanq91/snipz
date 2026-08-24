// Demo/usage example for UndoSnackbar.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'undo_snackbar.dart';

final ComponentDemo undoSnackbarDemo = ComponentDemo(
  id: 'undo_snackbar',
  builder: (context) => const _UndoShowcase(),
  // Static full-progress bar for the gallery tile — the idle stage is
  // just the Delete button.
  thumbnailBuilder: (context) => const _Stage(
    child: FittedBox(
      fit: BoxFit.contain,
      child: UndoSnackbar(requestId: 1, animate: false),
    ),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'ready',
      label: 'Ready',
      builder: (context) =>
          const _Stage(child: SizedBox(width: 240, height: 130)),
    ),
    DemoVariant(
      id: 'undo-window',
      label: 'Undo window',
      builder: (context) =>
          const _Stage(child: UndoSnackbar(requestId: 1, animate: false)),
    ),
  ],
);

class _UndoShowcase extends StatefulWidget {
  const _UndoShowcase();

  @override
  State<_UndoShowcase> createState() => _UndoShowcaseState();
}

class _UndoShowcaseState extends State<_UndoShowcase> {
  int _requestId = 0;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: SizedBox(
        width: 240,
        height: 130,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _PillButton(
              label: 'Delete item',
              onPressed: () => setState(() => _requestId++),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: UndoSnackbar(requestId: _requestId, onUndo: () {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF232326),
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFF2A2A2E))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEDE9E0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0E0E10),
      child: Center(child: child),
    );
  }
}
