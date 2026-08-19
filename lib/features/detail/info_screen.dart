// Info page (spec §8.5 reshaped): pushed from the detail overflow menu.
// Renders the README body; sources stay lazy (§5.0) — the asset is only read
// when this page is opened.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/models.dart';

class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First watch triggers the lazy read of assets/sources/<id>.json (§5.0).
    final AsyncValue<ComponentSources> sources = ref.watch(sourcesProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text('Info · $id')),
      body: sources.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load sources for "$id"\n$error')),
        data: (data) => Markdown(
          data: data.readmeBody,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
