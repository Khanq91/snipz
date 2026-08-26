// Demo/usage example for PagePeel. This file is intentionally app-facing;
// the portable component itself only imports Flutter.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'page_peel.dart';

final ComponentDemo pagePeelDemo = ComponentDemo(
  id: 'page_peel',
  builder: (context) => const _Stage(child: _PagePeelShowcase()),
  thumbnailBuilder: (context) => _staticStage(1),
  variants: <DemoVariant>[
    DemoVariant(
      id: 'front',
      label: 'Front page',
      builder: (context) => _staticStage(0),
      frozenBuilder: (context) => _staticStage(0),
    ),
    DemoVariant(
      id: 'revealed',
      label: 'Page beneath',
      builder: (context) => _staticStage(1),
      frozenBuilder: (context) => _staticStage(1),
    ),
  ],
);

List<Widget> _demoPages() => const <Widget>[
  _DemoPage(label: 'Page 2', back: true),
  _DemoPage(label: 'Page 1'),
];

Widget _staticStage(int peeledCount) {
  return _Stage(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: PagePeel(
        pages: _demoPages(),
        initialPeeledCount: peeledCount,
        tapToAdvance: false,
        animate: false,
      ),
    ),
  );
}

class _PagePeelShowcase extends StatefulWidget {
  const _PagePeelShowcase();

  @override
  State<_PagePeelShowcase> createState() => _PagePeelShowcaseState();
}

class _PagePeelShowcaseState extends State<_PagePeelShowcase> {
  late final PagePeelController _controller = PagePeelController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 150,
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            PagePeel(pages: _demoPages(), controller: _controller),
            Positioned(
              right: 8,
              bottom: 8,
              child: _PeelButton(onPressed: _controller.next),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({required this.label, this.back = false});

  final String label;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: back ? const Color(0xFF141417) : const Color(0xFF232326),
        border: Border.all(color: const Color(0xFF2A2A2E)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: back
                ? const Color(0xFFA8A6A0)
                : const Color(0xFFEDE9E0),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PeelButton extends StatelessWidget {
  const _PeelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll<Size>(Size(0, 40)),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFFFF8A00)),
        foregroundColor: WidgetStatePropertyAll<Color>(Color(0xFF0E0E10)),
        textStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      child: const Text('Peel'),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E0E10),
      child: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
