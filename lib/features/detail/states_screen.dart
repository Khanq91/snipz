// State board (the bloub `#planche` idea): every declared variant of a
// component frozen side by side — a quick visual check without N animation
// loops running. Tapping a tile reopens the detail on that variant, frozen
// (`?variant=<id>&frozen=1`).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snipz/core/component_demo.dart';
import 'package:snipz/registry.dart';

class StatesScreen extends StatelessWidget {
  const StatesScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final ComponentDemo? demo = componentRegistry[id];
    final List<DemoVariant> variants = demo?.variants ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text('$id — states')),
      body: variants.isEmpty
          ? const Center(child: Text('This component declares no variants'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: variants.length,
              itemBuilder: (context, i) => _tile(context, variants[i]),
            ),
    );
  }

  Widget _tile(BuildContext context, DemoVariant variant) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('state-tile-${variant.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go('/component/$id?variant=${variant.id}&frozen=1'),
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                // Each tile is one still frame: the deterministic one when
                // the component provides it (sample(t) convention), else the
                // live builder with its tickers disabled.
                child: RepaintBoundary(
                  child: IgnorePointer(
                    child: variant.frozenBuilder != null
                        ? Builder(builder: variant.frozenBuilder!)
                        : TickerMode(
                            enabled: false,
                            child: Builder(builder: variant.builder),
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                variant.label,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
