// dart tools/verify.dart <id> <result> [--note "..."] [--platform android]
//
// Appends one row to the component's Test History (append-only, §5.1 layer
// 3) and refreshes the derived fields. Hard rule (§10): versions are NEVER
// typed by hand — Flutter/Dart come from `flutter --version`, resolved deps
// from pubspec.lock. You only supply <result> and the note.

import 'dart:io';

import 'src/build_index_lib.dart';
import 'src/flutter_env.dart';
import 'src/frontmatter.dart';
import 'src/paths.dart';
import 'src/schema.dart';
import 'src/test_history.dart';

Future<void> main(List<String> args) async {
  requireRepoRoot();
  final List<String> positional = [];
  String? note;
  String platform = 'android';
  for (int i = 0; i < args.length; i++) {
    final String a = args[i];
    if (a == '--note' && i + 1 < args.length) {
      note = args[++i];
    } else if (a.startsWith('--note=')) {
      note = a.substring(7);
    } else if (a == '--platform' && i + 1 < args.length) {
      platform = args[++i];
    } else if (a.startsWith('--platform=')) {
      platform = a.substring(11);
    } else if (!a.startsWith('--')) {
      positional.add(a);
    }
  }
  if (positional.length != 2 || !verifyResults.contains(positional[1])) {
    stderr.writeln(
      'usage: dart tools/verify.dart <id> <${verifyResults.join('|')}> '
      '[--note "..."] [--platform android]',
    );
    exitCode = 2;
    return;
  }
  final String id = positional[0];
  final String result = positional[1];
  final File readme = File('$componentsDir/$id/README.md');
  if (!readme.existsSync()) {
    stderr.writeln('${readme.path} not found');
    exitCode = 2;
    return;
  }

  final FlutterEnv env = await readFlutterEnv();
  final Frontmatter fm = parseFrontmatter(readme.readAsStringSync(), id: id);
  final Map<String, String> deps = pairsToMap(
    fm.map['deps'],
    id: id,
    field: 'deps',
  );
  final Map<String, String> locked = lockedDepVersions();
  final String depsResolved = deps.isEmpty
      ? '—'
      : deps.keys
            .map((n) => '$n ${locked[n] ?? '(NOT IN pubspec.lock)'}')
            .join(', ');

  final String rawNote = (note ?? '—').replaceAll('|', '/').trim();
  final String cleanNote = rawNote.isEmpty ? '—' : rawNote;
  final TestRow row = TestRow(
    date: today(),
    flutter: env.flutter,
    dart: env.dart,
    depsResolved: depsResolved,
    platform: platform,
    result: result,
    note: cleanNote,
  );

  final String newBody = appendTestRow(fm.body, row);
  final List<TestRow> rows = parseTestHistory(newBody, id);
  final String status = switch (result) {
    'pass' || 'pass_warning' => 'verified',
    'needs_patch' => 'needs_patch',
    _ => 'broken',
  };
  String yaml = fm.yamlText;
  yaml = setScalar(yaml, 'latest_known_good', latestKnownGood(rows) ?? 'null');
  yaml = setScalar(yaml, 'last_verified', row.date);
  yaml = setScalar(yaml, 'status', status);
  readme.writeAsStringSync(assembleReadme(yaml, newBody));

  writeArtifacts(env);

  stdout.writeln('verify [$id]: appended ${row.toLine()}');
  stdout.writeln(
    'derived: status=$status last_verified=${row.date} '
    'latest_known_good=${latestKnownGood(rows) ?? 'null'}',
  );
  stdout.writeln('artifacts regenerated');
}
