// Demo/usage example for ToastOvershoot.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'toast_overshoot.dart';

final ComponentDemo toastOvershootDemo = ComponentDemo(
  id: 'toast_overshoot',
  builder: (context) => const _ToastShowcase(),
  thumbnailBuilder: (context) => const _Stage(
    child: ToastOvershoot(initiallyVisible: true, animate: false),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'visible',
      label: 'Visible',
      builder: (context) => const _Stage(
        child: ToastOvershoot(initiallyVisible: true, animate: false),
      ),
    ),
  ],
);

/// Kinetics card stage: a trigger button top-left, the toast rising from the
/// bottom center — same layout as the original `.demo-toast-zone`.
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
        width: 260,
        height: 150,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 8,
              left: 8,
              child: _PillButton(
                label: 'Trigger',
                onPressed: () => setState(() => _pushId++),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(child: ToastOvershoot(pushId: _pushId)),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

/// Dark stage matching the kinetics palette (graphite #0e0e10).
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
