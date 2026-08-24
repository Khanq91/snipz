// Demo/usage example for NotificationSlideIn.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'notification_slide_in.dart';

final ComponentDemo notificationSlideInDemo = ComponentDemo(
  id: 'notification_slide_in',
  builder: (context) => const _NotificationShowcase(),
  // Static visible pill for the gallery tile — the idle stage is empty.
  // FittedBox: the pill is nowrap (like the original) and wider than a tile.
  thumbnailBuilder: (context) => const _Stage(
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 240,
        height: 130,
        child: NotificationSlideIn(requestId: 1, animate: false),
      ),
    ),
  ),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'hidden',
      label: 'Hidden',
      builder: (context) =>
          const _Stage(child: NotificationSlideIn(animate: false)),
    ),
    DemoVariant(
      id: 'visible',
      label: 'Visible',
      builder: (context) => const _Stage(
        child: NotificationSlideIn(requestId: 1, animate: false),
      ),
    ),
  ],
);

class _NotificationShowcase extends StatefulWidget {
  const _NotificationShowcase();

  @override
  State<_NotificationShowcase> createState() => _NotificationShowcaseState();
}

class _NotificationShowcaseState extends State<_NotificationShowcase> {
  int _requestId = 0;

  @override
  Widget build(BuildContext context) {
    return _Stage(
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          NotificationSlideIn(requestId: _requestId),
          Positioned(
            left: 16,
            top: 70,
            child: _PillButton(
              label: 'Notify',
              onPressed: () => setState(() => _requestId++),
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEDE9E0),
              fontSize: 12,
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
