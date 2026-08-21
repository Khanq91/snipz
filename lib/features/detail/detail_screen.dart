// Detail screen (spec §8.5, reshaped): the whole body is the interactive
// preview stage — no swipeable tabs, so components that need horizontal /
// vertical drags never fight the navigation. Code / Info / Files are pushed
// as separate routes from the app-bar overflow menu (3-dots), which lists
// every action: Code, Info, Files (multi-file only), Share, Favourite. The
// favourite star stays on the app bar as a one-tap shortcut.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/core/share_block.dart';
import 'package:snipz/features/detail/preview_stage.dart';
import 'package:snipz/registry.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({
    super.key,
    required this.id,
    this.initialVariantId,
    this.initialFrozen = false,
  });

  final String id;

  /// From the `?variant=` / `&frozen=1` deep link (router).
  final String? initialVariantId;
  final bool initialFrozen;

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
        return _DetailBody(
          meta: meta,
          repoUrl: data.remoteUrl,
          initialVariantId: initialVariantId,
          initialFrozen: initialFrozen,
        );
      },
    );
  }
}

enum _DetailAction { code, info, files, states, share, favorite }

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.meta,
    required this.repoUrl,
    this.initialVariantId,
    this.initialFrozen = false,
  });

  final ComponentMeta meta;
  final String? repoUrl;
  final String? initialVariantId;
  final bool initialFrozen;

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        subject: 'Snipz: ${meta.title}',
        text: buildShareBlock(meta, repoUrl: repoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isFavorite = ref.watch(favoritesProvider).contains(meta.id);
    final bool hasFiles = meta.fileCount > 1;
    final bool hasVariants =
        componentRegistry[meta.id]?.variants.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(meta.title),
        actions: [
          IconButton(
            key: const ValueKey('detail-favorite'),
            tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(meta.id),
          ),
          PopupMenuButton<_DetailAction>(
            key: const ValueKey('detail-menu'),
            tooltip: 'Actions',
            onSelected: (action) {
              switch (action) {
                case _DetailAction.code:
                  context.push('/component/${meta.id}/code');
                case _DetailAction.info:
                  context.push('/component/${meta.id}/info');
                case _DetailAction.files:
                  context.push('/component/${meta.id}/files');
                case _DetailAction.states:
                  context.push('/component/${meta.id}/states');
                case _DetailAction.share:
                  _share();
                case _DetailAction.favorite:
                  ref.read(favoritesProvider.notifier).toggle(meta.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                key: ValueKey('menu-code'),
                value: _DetailAction.code,
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Code'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                key: ValueKey('menu-info'),
                value: _DetailAction.info,
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Info'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (hasFiles)
                const PopupMenuItem(
                  key: ValueKey('menu-files'),
                  value: _DetailAction.files,
                  child: ListTile(
                    leading: Icon(Icons.folder_outlined),
                    title: Text('Files'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (hasVariants)
                const PopupMenuItem(
                  key: ValueKey('menu-states'),
                  value: _DetailAction.states,
                  child: ListTile(
                    leading: Icon(Icons.grid_view_outlined),
                    title: Text('States'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                key: ValueKey('detail-share'),
                value: _DetailAction.share,
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                key: const ValueKey('menu-favorite'),
                value: _DetailAction.favorite,
                child: ListTile(
                  leading: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? Colors.amber : null,
                  ),
                  title: Text(isFavorite ? 'Unfavourite' : 'Favourite'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _MetaChip(label: meta.kind.wire),
                // Derived frontmatter can be null before the first verify
                // run — show untested/unknown, never crash (handover rule #4).
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
              child: PreviewStage(
                meta: meta,
                demo: componentRegistry[meta.id],
                initialVariantId: initialVariantId,
                initialFrozen: initialFrozen,
              ),
            ),
          ),
        ],
      ),
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
