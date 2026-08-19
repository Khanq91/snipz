// Code page (spec §8.5 reshaped): pushed from the detail overflow menu.
// Monospace + both-axis scroll (§1.1: glanceable, not comfortable — it
// answers "is this the one I need", nothing more). Multi-file components get
// a chip row to switch files; `initialFile` lets the Files page deep-link.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/models.dart';

class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key, required this.id, this.initialFile});

  final String id;
  final String? initialFile;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    // First watch triggers the lazy read of assets/sources/<id>.json (§5.0).
    final AsyncValue<ComponentSources> sources = ref.watch(
      sourcesProvider(widget.id),
    );
    return Scaffold(
      appBar: AppBar(title: Text('Code · ${widget.id}')),
      body: sources.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load sources for "${widget.id}"\n$error'),
        ),
        data: (data) {
          final String file =
              _selected ??
              widget.initialFile ??
              (data.files.isEmpty ? '' : data.files.keys.first);
          final String code =
              data.files[file] ?? '// "$file" not found in sources';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.files.length > 1)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      for (final String name in data.files.keys) ...[
                        ChoiceChip(
                          key: ValueKey('code-file-$name'),
                          label: Text(name),
                          selected: name == file,
                          onSelected: (_) => setState(() => _selected = name),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      code,
                      key: const ValueKey('code-view'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
