// Detail screen (spec §8.5): preview stage by kind, Files tab (multi-file
// only), Code tab (monospace, horizontal scroll — kept light, it exists to
// glance 20 lines), lazy Info tab (§5.0), share sheet (§8.6).

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/core/share_block.dart';
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
        return _DetailBody(meta: meta, repoUrl: data.remoteUrl);
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.meta, required this.repoUrl});

  final ComponentMeta meta;
  final String? repoUrl;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody>
    with SingleTickerProviderStateMixin {
  late final bool _hasFilesTab = widget.meta.fileCount > 1;
  late final TabController _tabs = TabController(
    length: _hasFilesTab ? 4 : 3,
    vsync: this,
  );

  /// File shown by the Code tab; defaults to the entry.
  late String _selectedFile = widget.meta.entry;

  int get _codeTabIndex => _hasFilesTab ? 2 : 1;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openFile(String name) {
    setState(() => _selectedFile = name);
    _tabs.animateTo(_codeTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ComponentMeta meta = widget.meta;
    final bool isFavorite = ref.watch(favoritesProvider).contains(meta.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(meta.title),
        actions: [
          IconButton(
            key: const ValueKey('detail-share'),
            tooltip: 'Share paste-ready block',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                subject: 'Snipz: ${meta.title}',
                text: buildShareBlock(meta, repoUrl: widget.repoUrl),
              ),
            ),
          ),
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
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Preview'),
            if (_hasFilesTab) const Tab(text: 'Files'),
            const Tab(text: 'Code'),
            const Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PreviewTab(meta: meta),
          if (_hasFilesTab) _FilesTab(meta: meta, onOpen: _openFile),
          // Built only when the tab becomes visible -> sources stay lazy.
          _CodeTab(
            id: meta.id,
            file: _selectedFile,
            onPickFile: (name) => setState(() => _selectedFile = name),
          ),
          _InfoTab(id: meta.id),
        ],
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

/// File list + role (from the verified `files` manifest, §3.2). Tap a file
/// to read it in the Code tab.
class _FilesTab extends StatelessWidget {
  const _FilesTab({required this.meta, required this.onOpen});

  final ComponentMeta meta;
  final void Function(String name) onOpen;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> files = meta.files.entries.toList();
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, i) {
        final MapEntry<String, String> f = files[i];
        final bool isEntry = f.key == meta.entry;
        return ListTile(
          key: ValueKey('file-${f.key}'),
          leading: Icon(
            isEntry ? Icons.login_outlined : Icons.description_outlined,
          ),
          title: Text(f.key, style: const TextStyle(fontFamily: 'monospace')),
          subtitle: Text(f.value),
          onTap: () => onOpen(f.key),
        );
      },
    );
  }
}

/// Monospace + both-axis scroll (§1.1: glanceable, not comfortable — it
/// answers "is this the one I need", nothing more).
class _CodeTab extends ConsumerWidget {
  const _CodeTab({
    required this.id,
    required this.file,
    required this.onPickFile,
  });

  final String id;
  final String file;
  final void Function(String name) onPickFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First watch triggers the lazy read of assets/sources/<id>.json (§5.0).
    final AsyncValue<ComponentSources> sources = ref.watch(sourcesProvider(id));
    return sources.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load sources for "$id"\n$error')),
      data: (data) {
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
                        onSelected: (_) => onPickFile(name),
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
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
