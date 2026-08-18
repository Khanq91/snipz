// Gallery: 2-column grid of REAL widgets (spec §8.3). Data comes from the
// single startup read of index.json; thumbnails come from the registry.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/registry.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ComponentIndex> index = ref.watch(indexProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Snipz')),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load index.json\n$error')),
        data: (data) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: data.components.length,
          itemBuilder: (context, i) => _ComponentTile(meta: data.components[i]),
        ),
      ),
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({required this.meta});

  final ComponentMeta meta;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      key: ValueKey<String>('tile-${meta.id}'),
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/component/${meta.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // RepaintBoundary isolates thumbnail painting from grid
              // scrolling (§8.3). IgnorePointer keeps interactive demos from
              // swallowing the tile tap. Never a `text` carrier here (§9.2).
              child: RepaintBoundary(
                child: IgnorePointer(child: _thumbnail(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    meta.kind.wire,
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(BuildContext context) {
    final ComponentDemo? demo = componentRegistry[meta.id];
    if (demo == null) {
      // Index and registry are kept in sync by validate.dart; this is a
      // defensive fallback so a drift never crashes the gallery.
      return const Center(child: Icon(Icons.broken_image_outlined));
    }
    final WidgetBuilder builder = demo.thumbnailBuilder ?? demo.builder;
    return ClipRect(child: builder(context));
  }
}
