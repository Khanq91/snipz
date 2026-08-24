// Demo/usage example for ToastStack.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'toast_stack.dart';

final ComponentDemo toastStackDemo = ComponentDemo(
  id: 'toast_stack',
  builder: (context) => const _ToastShowcase(),
  // Static three-toast stack for the gallery tile — the idle stage is empty.
  thumbnailBuilder: (context) => const _Stage(
    child: FittedBox(
      fit: BoxFit.contain,
      child: ToastStack(
        initialMessages: <String>['Saved #1', 'Saved #2', 'Saved #3'],
        animate: false,
      ),
    ),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'one',
      label: '1 toast',
      builder: (context) => const _Stage(
        child: ToastStack(
          initialMessages: <String>['Saved #1'],
          animate: false,
        ),
      ),
    ),
    DemoVariant(
      id: 'three',
      label: '3 toasts',
      builder: (context) => const _Stage(
        child: ToastStack(
          initialMessages: <String>['Saved #1', 'Saved #2', 'Saved #3'],
          animate: false,
        ),
      ),
    ),
  ],
);

class _ToastShowcase extends StatefulWidget {
  const _ToastShowcase();

  @override
  State<_ToastShowcase> createState() => _ToastShowcaseState();
}

class _ToastShowcaseState extends State<_ToastShowcase> {
  int _pushId = 0;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: SizedBox(
        width: 240,
        height: 170,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Positioned(
              left: 20,
              right: 20,
              bottom: 48,
              child: ToastStack(pushId: _pushId),
            ),
            _PillButton(
              label: 'Push toast',
              onPressed: () => setState(() => _pushId++),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
