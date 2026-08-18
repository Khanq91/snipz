import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snipz/features/detail/detail_screen.dart';
import 'package:snipz/features/gallery/gallery_screen.dart';

/// One router instance per app widget (created in SnipzApp's state so tests
/// don't share navigation state). Every route uses a fade transition — the
/// default ZoomPageTransitionsBuilder adds a scrim layer that flashes over
/// transparent Scaffold backgrounds (spec §11).
GoRouter buildRouter() => GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadePage(state, const GalleryScreen()),
    ),
    GoRoute(
      path: '/component/:id',
      pageBuilder: (context, state) =>
          _fadePage(state, DetailScreen(id: state.pathParameters['id']!)),
    ),
  ],
  errorPageBuilder: (context, state) =>
      _fadePage(state, _NotFoundScreen(uri: state.uri)),
);

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for "$uri"')),
    );
  }
}
