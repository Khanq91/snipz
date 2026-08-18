// Unit tests for the compat resolver — every rule of decision #11 plus the
// runtime stale rule (decision #5). Pure Dart, no widgets.

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/core/compat.dart';
import 'package:snipz/core/models.dart';

final DateTime _today = DateTime(2026, 8, 18);

Map<String, Object?> _row(String flutter, String result, {String? date}) => {
  'date': date ?? '2026-08-18',
  'flutter': flutter,
  'dart': '3.12.2',
  'deps_resolved': '—',
  'platform': 'android',
  'result': result,
  'note': '—',
};

ComponentMeta _meta({
  List<Map<String, Object?>> history = const [],
  String? latestKnownGood,
  String? lastVerified,
}) => ComponentMeta.fromJson({
  'id': 'x',
  'title': 'X',
  'kind': 'paint',
  'tags': <Object?>[],
  'paint_source': 'shader',
  'carriers_verified': <Object?>[],
  'carriers_failed': <String, Object?>{},
  'scale_aware': true,
  'portability': 'single_file',
  'entry': 'x.dart',
  'files': {'x.dart': 'entry'},
  'vendored_from': null,
  'assets_required': <Object?>[],
  'shaders_required': <Object?>[],
  'deps': <String, Object?>{},
  'origin': 'original',
  'source': null,
  'author': 'test',
  'license': null,
  'created': '2026-01-01',
  'created_flutter': '3.44.5',
  'created_dart': '3.12.2',
  'created_deps': <String, Object?>{},
  'platforms_initial': ['android'],
  'version': '1.0.0',
  'latest_known_good': latestKnownGood,
  'last_verified': lastVerified,
  'status': null,
  'preview': null,
  'test_history': history,
});

Compat _resolve(ComponentMeta m, String target) =>
    resolveCompat(m, target: target, today: _today);

void main() {
  test('version compare is numeric, not lexicographic', () {
    expect(compareFlutterVersions('3.9.0', '3.44.5'), lessThan(0));
    expect(compareFlutterVersions('3.44.5', '3.44.5'), 0);
    expect(compareFlutterVersions('4.0.0', '3.99.9'), greaterThan(0));
  });

  test('rule 1: exact-version row decides — pass, needs_patch, fail', () {
    final m = _meta(
      history: [
        _row('3.44.5', 'pass'),
        _row('3.40.0', 'needs_patch'),
        _row('3.30.0', 'fail'),
      ],
      latestKnownGood: '3.44.5',
    );
    expect(_resolve(m, '3.44.5').badge, CompatBadge.good);
    expect(_resolve(m, '3.40.0').badge, CompatBadge.unknown);
    // fail@3.30.0 exact — rule 1 wins even though higher passes exist.
    expect(_resolve(m, '3.30.0').badge, CompatBadge.broken);
  });

  test('rule 1: the LAST row for a version wins (append-only history)', () {
    final m = _meta(
      history: [
        _row('3.44.5', 'fail', date: '2026-01-01'),
        _row('3.44.5', 'pass', date: '2026-08-01'), // fixed later
      ],
    );
    expect(_resolve(m, '3.44.5').badge, CompatBadge.good);
  });

  test('rule 2: fail at <= target with no higher pass -> broken', () {
    final m = _meta(history: [_row('3.40.0', 'fail')], latestKnownGood: null);
    expect(_resolve(m, '3.44.5').badge, CompatBadge.broken);
  });

  test('rule 2: a pass at a higher version redeems the old fail', () {
    final m = _meta(
      history: [_row('3.40.0', 'fail'), _row('3.44.5', 'pass')],
      latestKnownGood: '3.44.5',
    );
    // Target above both rows: not broken; lkg 3.44.5 < 3.50.0 -> unknown.
    expect(_resolve(m, '3.50.0').badge, CompatBadge.unknown);
  });

  test('rule 3: latest_known_good >= target -> good, < target -> unknown', () {
    final m = _meta(
      history: [_row('3.44.5', 'pass')],
      latestKnownGood: '3.44.5',
    );
    expect(_resolve(m, '3.42.0').badge, CompatBadge.good);
    expect(_resolve(m, '3.50.0').badge, CompatBadge.unknown);
  });

  test('never verified -> unknown', () {
    expect(_resolve(_meta(), '3.44.5').badge, CompatBadge.unknown);
  });

  test('stale: last_verified 8 months ago flags stale, recent does not', () {
    final old = _meta(lastVerified: '2025-12-17'); // 8 months before _today
    expect(_resolve(old, '3.44.5').stale, isTrue);
    final fresh = _meta(lastVerified: '2026-08-01');
    expect(_resolve(fresh, '3.44.5').stale, isFalse);
  });
}
