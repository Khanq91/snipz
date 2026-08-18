// dart tools/build_index.dart
//
// Scans lib/components/*/README.md + sources and regenerates the committed
// artifacts: assets/index.json and assets/sources/<id>.json (§10, §5.0).
// Frontmatter errors report the component id and line — the build stops,
// nothing is silently skipped and nothing is written.

import 'dart:io';

import 'src/build_index_lib.dart';
import 'src/flutter_env.dart';
import 'src/paths.dart';

Future<void> main() async {
  requireRepoRoot();
  try {
    final int n = writeArtifacts(await readFlutterEnv());
    stdout.writeln(
      'build_index: wrote $indexPath + $n source file(s) under $sourcesDir/',
    );
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln('build_index: FAILED — nothing was written.');
    exitCode = 1;
  }
}
