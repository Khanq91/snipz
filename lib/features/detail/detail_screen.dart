// Detail screen: preview stage by kind + lazy Info tab (spec §8.5, §5.0).
// Code/Files tabs and share are Phase 5; carrier switcher is Phase 3.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/detail/preview_stage.dart';
import 'package:snipz/registry.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cached by IndexLoader — watching here never re-reads the asset.
    final AsyncValue<ComponentIndex> index = ref.watch(indexProvider);
    return index.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load index.json\n$error')),
      ),
      data: (data) {
        ComponentMeta? meta;
        for (final ComponentMeta c in data.components) {
          if (c.id == id) {
            meta = c;
            break;
          }
        }
        if (meta == null) {
          return Scaffold(
            appBar: AppBar(title: Text(id)),
            body: Center(child: Text('Unknown component "$id"')),
          );
        }
        return _DetailBody(meta: meta);
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.meta});

  final ComponentMeta meta;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(meta.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Preview'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PreviewTab(meta: meta),
            // Built only when the tab becomes visible -> sources stay lazy.
            _InfoTab(id: meta.id),
          ],
        ),
      ),
    );
  }
}

class _PreviewTab extends StatelessWidget {
  const _PreviewTab({required this.meta});

  final ComponentMeta meta;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetaChip(label: meta.kind.wire),
              // Derived frontmatter can be null before the first verify run —
              // show untested/unknown, never crash (handover rule #4).
              _MetaChip(label: meta.status?.wire ?? 'untested'),
              _MetaChip(label: 'verified: ${meta.lastVerified ?? 'unknown'}'),
              _MetaChip(label: 'v${meta.version}'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: PreviewStage(meta: meta, demo: componentRegistry[meta.id]),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First watch triggers the lazy read of assets/sources/<id>.json (§5.0).
    final AsyncValue<ComponentSources> sources = ref.watch(sourcesProvider(id));
    return sources.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load sources for "$id"\n$error')),
      data: (data) => Markdown(
        data: data.readmeBody,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
