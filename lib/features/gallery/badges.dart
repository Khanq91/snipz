// The two badge families of spec §8.4 — the payoff that makes metadata worth
// writing. Both are derived, never stored: compat from Test History vs the
// user's target version, reuse-cost from `portability`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snipz/app/providers.dart';
import 'package:snipz/core/compat.dart';
import 'package:snipz/core/models.dart';

/// 🟢 / 🟡 / 🔴 per decision #11, plus the runtime 🟡-stale state
/// (decision #5). Tooltip carries the why.
class CompatBadgeDot extends ConsumerWidget {
  const CompatBadgeDot({super.key, required this.meta});

  final ComponentMeta meta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? target = ref.watch(effectiveTargetProvider);
    if (target == null) return const SizedBox.shrink();
    final Compat compat = resolveCompat(
      meta,
      target: target,
      today: DateTime.now(),
    );
    final (String emoji, String label) = switch (compat.badge) {
      CompatBadge.broken => ('🔴', compat.reason),
      CompatBadge.good when compat.stale => (
        '🟡',
        'stale — last_verified ${meta.lastVerified} quá 6 tháng',
      ),
      CompatBadge.good => ('🟢', compat.reason),
      CompatBadge.unknown => ('🟡', compat.reason),
    };
    return Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.tap,
      child: Text(
        emoji,
        key: ValueKey('badge-compat-${meta.id}'),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

/// Reuse-cost badge (spec §8.4): answers "cái nào paste 10 giây" before the
/// detail screen ever opens.
class PortabilityBadge extends StatelessWidget {
  const PortabilityBadge({super.key, required this.meta});

  final ComponentMeta meta;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (meta.portability) {
      Portability.singleFile => (const Color(0xFF2196F3), 'single'),
      Portability.folder => (
        const Color(0xFFFFC107),
        'folder (${meta.fileCount})',
      ),
      Portability.folderWithAssets => (
        const Color(0xFFF44336),
        'folder + assets',
      ),
    };
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: ValueKey('badge-portability-${meta.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color.lerp(color, dark ? Colors.white : Colors.black, 0.25),
        ),
      ),
    );
  }
}
