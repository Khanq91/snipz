import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';
import 'depth_page_transition.dart';

final ComponentDemo depthPageTransitionDemo = ComponentDemo(
  id: 'depth_page_transition',
  builder: (_) => const _RouteDemo(),
  thumbnailBuilder: (_) => const FittedBox(
    child: SizedBox(width: 360, height: 460, child: _FrozenPush(progress: .55)),
  ),
  variants: [
    DemoVariant(
      id: 'push_pop',
      label: 'Push / Pop',
      builder: (_) => const _RouteDemo(),
      frozenBuilder: (_) => const _FrozenPush(progress: .55),
    ),
    DemoVariant(
      id: 'settled',
      label: 'Settled',
      builder: (_) => const _FrozenPush(progress: 1),
    ),
  ],
  scrubDuration: .45,
  scrubBuilder: (_, t) => _FrozenPush(progress: (t / .45).clamp(0, 1)),
);

class _RouteDemo extends StatefulWidget {
  const _RouteDemo();
  @override
  State<_RouteDemo> createState() => _RouteDemoState();
}

class _RouteDemoState extends State<_RouteDemo> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const DepthPageTransitionsBuilder(),
        },
      ),
    ),
    child: ClipRect(
      child: NavigatorPopHandler<void>(
        onPopWithResult: (_) => _navigator.currentState!.pop(),
        child: Navigator(
          key: _navigator,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const _DemoPage(level: 0),
          ),
        ),
      ),
    ),
  );
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({required this.level, this.interactive = true});
  final int level;
  final bool interactive;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: level.isEven
        ? const Color(0xFF152239)
        : const Color(0xFF23334D),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              level == 0 ? Icons.layers_outlined : Icons.tune_rounded,
              size: 44,
              color: const Color(0xFF9BC9FF),
            ),
            const SizedBox(height: 16),
            Text(
              level == 0 ? 'Depth navigation' : 'Page $level',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Slide · fade · rounded depth',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFC0CDE0)),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: interactive
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _DemoPage(level: level + 1),
                      ),
                    )
                  : null,
              child: const Text('Push page'),
            ),
            if (level > 0)
              TextButton(
                onPressed: interactive
                    ? () => Navigator.of(context).pop()
                    : null,
                child: const Text('Go back'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FrozenPush extends StatelessWidget {
  const _FrozenPush({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) => FittedBox(
    child: SizedBox(
      width: 360,
      height: 460,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DepthPageTransition(
              animation: const AlwaysStoppedAnimation(1),
              secondaryAnimation: AlwaysStoppedAnimation(progress),
              child: const _DemoPage(level: 0, interactive: false),
            ),
            DepthPageTransition(
              animation: AlwaysStoppedAnimation(progress),
              secondaryAnimation: const AlwaysStoppedAnimation(0),
              child: const _DemoPage(level: 1, interactive: false),
            ),
          ],
        ),
      ),
    ),
  );
}
