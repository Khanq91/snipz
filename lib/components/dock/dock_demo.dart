// Demo/usage example for Dock. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'dock.dart';

final ComponentDemo dockDemo = ComponentDemo(
  id: 'dock',
  builder: (context) => const _DockShowcase(),
);

/// Bottom dock — press and slide a finger across the bar to feel the
/// magnification; release over an item to activate it.
class _DockShowcase extends StatefulWidget {
  const _DockShowcase();

  @override
  State<_DockShowcase> createState() => _DockShowcaseState();
}

class _DockShowcaseState extends State<_DockShowcase> {
  String _lastPressed = 'press & slide on the dock';

  DockItemData _item(IconData icon, String label) {
    return DockItemData(
      icon: Icon(icon, color: Colors.white, size: 22),
      label: label,
      onPressed: () => setState(() => _lastPressed = label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF060010),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                _lastPressed,
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Dock(
              items: <DockItemData>[
                _item(Icons.home_rounded, 'Home'),
                _item(Icons.archive_rounded, 'Archive'),
                _item(Icons.person_rounded, 'Profile'),
                _item(Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
