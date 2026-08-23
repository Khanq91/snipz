// Gallery: 2-column grid of REAL widgets (spec §8.3). Data comes from the
// single startup read of index.json; thumbnails come from the registry.
// Phase 4 adds search (title/tag), filters (kind / status / carrier /
// compat / favorites), the two §8.4 badges and the favorite star.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/compat.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/core/models.dart';
import 'package:snipz/features/gallery/badges.dart';
import 'package:snipz/registry.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _query = '';
  Kind? _kind;
  ComponentStatus? _status;
  Carrier? _carrier;
  bool _compatOnly = false;
  bool _favoritesOnly = false;
  bool _sessionOnly = false;

  List<ComponentMeta> _filtered(
    List<ComponentMeta> all,
    SessionInfo? session,
  ) {
    final Set<String> favorites = ref.watch(favoritesProvider);
    final String? target = ref.watch(effectiveTargetProvider);
    final String q = _query.trim().toLowerCase();
    return [
      for (final ComponentMeta m in all)
        if ((q.isEmpty ||
                m.title.toLowerCase().contains(q) ||
                m.tags.any((t) => t.toLowerCase().contains(q))) &&
            (_kind == null || m.kind == _kind) &&
            (_status == null || m.status == _status) &&
            (_carrier == null || m.carriersVerified.contains(_carrier)) &&
            (!_favoritesOnly || favorites.contains(m.id)) &&
            (!_sessionOnly || (session?.contains(m.id) ?? false)) &&
            (!_compatOnly ||
                target == null ||
                resolveCompat(m, target: target, today: DateTime.now()).badge ==
                    CompatBadge.good))
          m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ComponentIndex> index = ref.watch(indexProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snipz'),
        actions: [
          IconButton(
            key: const ValueKey('open-settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: index.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Failed to load index.json\n$error')),
        data: (data) {
          final SessionInfo? session = data.session;
          final List<ComponentMeta> shown =
              _filtered(data.components, session);
          return Column(
            children: [
              _searchField(),
              _filterRow(session),
              Expanded(
                child: shown.isEmpty
                    ? const Center(child: Text('No components match'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _ComponentTile(
                          meta: shown[i],
                          sessionFlag: session?.flagOf(shown[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
    child: TextField(
      key: const ValueKey('gallery-search'),
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'Search title / tag',
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
    ),
  );

  /// Horizontal, never wrapping (mobile §1.1).
  Widget _filterRow(SessionInfo? session) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // current work batch — only when SESSION.yaml declares one
          if (session != null && !session.isEmpty) ...[
            FilterChip(
              key: const ValueKey('filter-session'),
              label: const Text('✦ New'),
              selected: _sessionOnly,
              onSelected: (v) => setState(() => _sessionOnly = v),
            ),
            const SizedBox(width: 8),
          ],
          FilterChip(
            key: const ValueKey('filter-favorites'),
            label: const Text('★ Fav'),
            selected: _favoritesOnly,
            onSelected: (v) => setState(() => _favoritesOnly = v),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const ValueKey('filter-compat'),
            label: const Text('🟢 Compat'),
            selected: _compatOnly,
            onSelected: (v) => setState(() => _compatOnly = v),
          ),
          const SizedBox(width: 8),
          for (final Kind k in Kind.values) ...[
            FilterChip(
              key: ValueKey('filter-kind-${k.wire}'),
              label: Text(k.wire),
              selected: _kind == k,
              onSelected: (v) => setState(() => _kind = v ? k : null),
            ),
            const SizedBox(width: 8),
          ],
          _menuChip<ComponentStatus>(
            key: const ValueKey('filter-status'),
            label: _status == null ? 'status' : 'status: ${_status!.wire}',
            selected: _status != null,
            values: ComponentStatus.values,
            name: (s) => s.wire,
            onPick: (s) => setState(() => _status = s),
          ),
          const SizedBox(width: 8),
          _menuChip<Carrier>(
            key: const ValueKey('filter-carrier'),
            label: _carrier == null ? 'carrier' : 'carrier: ${_carrier!.wire}',
            selected: _carrier != null,
            values: Carrier.values,
            name: (c) => c.wire,
            onPick: (c) => setState(() => _carrier = c),
          ),
        ],
      ),
    );
  }

  /// FilterChip that opens a single-choice menu (status / carrier — too many
  /// values for one chip each).
  Widget _menuChip<T>({
    required Key key,
    required String label,
    required bool selected,
    required List<T> values,
    required String Function(T) name,
    required void Function(T?) onPick,
  }) {
    return PopupMenuButton<T?>(
      key: key,
      onSelected: onPick,
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('any')),
        for (final T v in values) PopupMenuItem(value: v, child: Text(name(v))),
      ],
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
        backgroundColor: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
      ),
    );
  }
}

class _ComponentTile extends ConsumerWidget {
  const _ComponentTile({required this.meta, this.sessionFlag});

  final ComponentMeta meta;

  /// Non-null marks this tile as part of the current work batch.
  final SessionFlag? sessionFlag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isFavorite = ref.watch(favoritesProvider).contains(meta.id);
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // RepaintBoundary isolates thumbnail painting from grid
                  // scrolling (§8.3). Off-viewport pause (§9.2) is handled by
                  // GridView.builder disposing off-screen children — their
                  // tickers die with them. IgnorePointer keeps interactive
                  // demos from swallowing the tile tap. Never a `text`
                  // carrier here.
                  RepaintBoundary(
                    child: IgnorePointer(child: _thumbnail(context)),
                  ),
                  if (sessionFlag != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _SessionBadge(
                        key: ValueKey('session-badge-${meta.id}'),
                        flag: sessionFlag!,
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      key: ValueKey('favorite-${meta.id}'),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        size: 20,
                        color: isFavorite
                            ? Colors.amber
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(meta.id),
                    ),
                  ),
                ],
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CompatBadgeDot(meta: meta),
                      const SizedBox(width: 6),
                      Flexible(child: PortabilityBadge(meta: meta)),
                      const Spacer(),
                      Text(
                        meta.kind.wire,
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

/// NEW (violet) / FIX (amber) pill on tiles of the current work batch. Lives
/// for the whole session — no dismissal — and disappears when the next batch
/// replaces SESSION.yaml.
class _SessionBadge extends StatelessWidget {
  const _SessionBadge({super.key, required this.flag});

  final SessionFlag flag;

  @override
  Widget build(BuildContext context) {
    final bool added = flag == SessionFlag.added;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: added ? const Color(0xFF7C5CD6) : const Color(0xFFC98A1B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        added ? '✦ NEW' : 'FIX',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      ),
    );
  }
}
