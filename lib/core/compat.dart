// Compat resolver (spec §8.4, decision #11). Pure Dart — no Flutter imports
// — so every rule is unit-testable. All comparisons are against the user's
// TARGET Flutter version (decision #2), never the build machine's.

import 'models.dart';

enum CompatBadge { good, unknown, broken }

class Compat {
  const Compat({required this.badge, required this.stale, required this.reason});

  final CompatBadge badge;

  /// last_verified more than 6 months before `today` — computed at runtime,
  /// never stored in the index (decision #5).
  final bool stale;

  /// Human-readable why, shown as tooltip.
  final String reason;
}

/// Numeric dotted-version compare ("3.44.5" style). Missing parts count as 0;
/// non-numeric parts count as 0 (defensive — versions come from `flutter
/// --version` via verify.dart, so they are normally clean).
int compareFlutterVersions(String a, String b) {
  final List<int> pa = _parts(a);
  final List<int> pb = _parts(b);
  for (int i = 0; i < 3; i++) {
    final int d = pa[i].compareTo(pb[i]);
    if (d != 0) return d;
  }
  return 0;
}

List<int> _parts(String v) {
  final List<String> raw = v.trim().split('.');
  return List<int>.generate(
    3,
    (i) => i < raw.length ? int.tryParse(raw[i]) ?? 0 : 0,
  );
}

/// Decision #11, applied in order:
///  1. A Test History row with Flutter == target → that row's result decides.
///  2. 🔴 broken only when some `fail` row at version <= target has no
///     pass/pass_warning row at a HIGHER version.
///  3. Otherwise compare latest_known_good: >= target → 🟢, < target → 🟡
///     unknown-on-this-version.
/// Staleness (rule 4) is independent: last_verified > 6 months before today.
Compat resolveCompat(
  ComponentMeta meta, {
  required String target,
  required DateTime today,
}) {
  final bool stale = _isStale(meta.lastVerified, today);

  // Rule 1 — exact match. Rows are append-only; the LAST matching row is the
  // most recent verdict on that version.
  TestRecord? exact;
  for (final TestRecord r in meta.testHistory) {
    if (compareFlutterVersions(r.flutter, target) == 0) exact = r;
  }
  if (exact != null) {
    return Compat(
      badge: switch (exact.result) {
        VerifyResult.pass || VerifyResult.passWarning => CompatBadge.good,
        VerifyResult.needsPatch => CompatBadge.unknown,
        VerifyResult.fail => CompatBadge.broken,
      },
      stale: stale,
      reason: 'Test History @ $target: ${exact.result.wire}',
    );
  }

  // Rule 2 — broken: a fail at or below target that no higher-version pass
  // ever redeemed.
  for (final TestRecord f in meta.testHistory) {
    if (f.result != VerifyResult.fail) continue;
    if (compareFlutterVersions(f.flutter, target) > 0) continue;
    final bool redeemed = meta.testHistory.any(
      (p) =>
          (p.result == VerifyResult.pass ||
              p.result == VerifyResult.passWarning) &&
          compareFlutterVersions(p.flutter, f.flutter) > 0,
    );
    if (!redeemed) {
      return Compat(
        badge: CompatBadge.broken,
        stale: stale,
        reason: 'fail @ ${f.flutter} (≤ $target), chưa có pass ở version cao hơn',
      );
    }
  }

  // Rule 3 — latest_known_good vs target.
  final String? lkg = meta.latestKnownGood;
  if (lkg != null && compareFlutterVersions(lkg, target) >= 0) {
    return Compat(
      badge: CompatBadge.good,
      stale: stale,
      reason: 'latest_known_good $lkg ≥ target $target',
    );
  }
  return Compat(
    badge: CompatBadge.unknown,
    stale: stale,
    reason: lkg == null
        ? 'chưa verify lần nào'
        : 'latest_known_good $lkg < target $target — unknown on this version',
  );
}

bool _isStale(String? lastVerified, DateTime today) {
  if (lastVerified == null) return false;
  final DateTime? d = DateTime.tryParse(lastVerified);
  if (d == null) return false;
  return today.difference(d).inDays > 183; // ~6 months
}
