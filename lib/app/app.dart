import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snipz/app/router.dart';
import 'package:snipz/app/theme.dart';

/// App root. Expects a ProviderScope above it that overrides
/// indexLoaderProvider (see main.dart / widget_test.dart).
class SnipzApp extends StatefulWidget {
  const SnipzApp({super.key});

  @override
  State<SnipzApp> createState() => _SnipzAppState();
}

class _SnipzAppState extends State<SnipzApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Snipz',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
