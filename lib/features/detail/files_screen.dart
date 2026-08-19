// Files page (spec §8.5 reshaped): pushed from the detail overflow menu for
// multi-file components only. File list + role (from the verified `files`
// manifest, §3.2). Tap a file to read it on the Code page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/models.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ComponentIndex> index = ref.watch(indexProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Files · $id')),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load index.json\n$error')),
        data: (data) {
          ComponentMeta? meta;
          for (final ComponentMeta c in data.components) {
            if (c.id == id) {
              meta = c;
              break;
            }
          }
          if (meta == null) {
            return Center(child: Text('Unknown component "$id"'));
          }
          final List<MapEntry<String, String>> files = meta.files.entries
              .toList();
          final String entry = meta.entry;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, i) {
              final MapEntry<String, String> f = files[i];
              final bool isEntry = f.key == entry;
              return ListTile(
                key: ValueKey('file-${f.key}'),
                leading: Icon(
                  isEntry ? Icons.login_outlined : Icons.description_outlined,
                ),
                title: Text(
                  f.key,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                subtitle: Text(f.value),
                onTap: () =>
                    context.push('/component/$id/code?file=${f.key}'),
              );
            },
          );
        },
      ),
    );
  }
}
