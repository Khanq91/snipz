// Paste-ready share block (spec §8.6): the app lives on the phone, the code
// lives on the computer — this text is what crosses the gap. Pure Dart so
// the exact output is unit-tested.

import 'models.dart';

String buildShareBlock(ComponentMeta meta, {String? repoUrl}) {
  final StringBuffer b = StringBuffer()
    ..writeln('Snipz component: ${meta.title} (${meta.id})')
    ..writeln();

  // Deps snippet — copy-paste straight into pubspec.yaml.
  if (meta.deps.isEmpty) {
    b.writeln('Deps: none — Flutter SDK only');
  } else {
    b
      ..writeln('Add to pubspec.yaml:')
      ..writeln('dependencies:');
    meta.deps.forEach((name, range) => b.writeln('  $name: $range'));
  }
  b.writeln();

  // What to copy and the single import line (§3.1.3).
  b
    ..writeln(
      'Copy folder: lib/components/${meta.id}/  '
      '(${meta.fileCount} file${meta.fileCount == 1 ? '' : 's'})',
    )
    ..writeln('Files: ${meta.files.keys.join(', ')}')
    ..writeln("Import: import '${meta.id}/${meta.entry}';");

  // The two DIFFERENT pubspec keys (§3.1.8) — never merged.
  if (meta.assetsRequired.isNotEmpty) {
    b.writeln(
      'Declare under pubspec key `assets:`: '
      '${meta.assetsRequired.join(', ')}',
    );
  }
  if (meta.shadersRequired.isNotEmpty) {
    b.writeln(
      'Declare under pubspec key `shaders:`: '
      '${meta.shadersRequired.join(', ')}',
    );
  }

  // Scale hint (§9.1) — the trap that ruins paints on small carriers.
  if (meta.kind == Kind.paint && meta.scaleAware) {
    b.writeln(
      'Scale hint: pass `scale` when using on small carriers '
      '(button/icon) — see the Carriers table in the README.',
    );
  }
  for (final MapEntry<Carrier, String> f in meta.carriersFailed.entries) {
    b.writeln('Carrier ${f.key.wire}: FAILED — ${f.value}');
  }

  if (repoUrl != null) {
    b
      ..writeln()
      ..writeln('GitHub: $repoUrl/tree/main/lib/components/${meta.id}');
  }
  return b.toString();
}
