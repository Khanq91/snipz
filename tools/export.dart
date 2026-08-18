// dart tools/export.dart <id>
//
// Zips the component folder and prints the paste-ready block (§10): deps
// snippet, import line, file list, asset/shader pubspec keys (they are
// DIFFERENT keys — §3.1.8), caveats and the scale hint. Copy, don't read.

import 'dart:io';

import 'package:archive/archive.dart';

import 'src/frontmatter.dart';
import 'src/paths.dart';

Future<void> main(List<String> args) async {
  requireRepoRoot();
  if (args.length != 1) {
    stderr.writeln('usage: dart tools/export.dart <id>');
    exitCode = 2;
    return;
  }
  final String id = args.first;
  final Directory folder = Directory('$componentsDir/$id');
  if (!folder.existsSync()) {
    stderr.writeln('${folder.path} not found');
    exitCode = 2;
    return;
  }
  final Frontmatter fm = parseFrontmatter(
    File('${folder.path}/README.md').readAsStringSync(),
    id: id,
  );
  final Map<String, Object?> m = fm.map;
  final Map<String, String> deps = pairsToMap(m['deps'], id: id, field: 'deps');
  final Map<String, String> files = pairsToMap(
    m['files'],
    id: id,
    field: 'files',
  );
  final List<String> assetsRequired = stringList(m['assets_required']);
  final List<String> shadersRequired = stringList(m['shaders_required']);

  final Archive archive = Archive();
  final List<File> entries =
      folder.listSync(recursive: true).whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final File f in entries) {
    final String rel = f.path
        .substring(folder.path.length + 1)
        .replaceAll('\\', '/');
    final List<int> bytes = f.readAsBytesSync();
    archive.addFile(ArchiveFile('$id/$rel', bytes.length, bytes));
  }
  final List<int>? zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) {
    stderr.writeln('zip encoding failed');
    exitCode = 1;
    return;
  }
  final File zip = File('build/export/$id.zip');
  zip.parent.createSync(recursive: true);
  zip.writeAsBytesSync(zipBytes);

  final StringBuffer b = StringBuffer()
    ..writeln('=== Snipz export: $id ===')
    ..writeln('zip: ${zip.path}')
    ..writeln();
  if (deps.isEmpty) {
    b.writeln('# deps: none — Flutter SDK only');
  } else {
    b
      ..writeln('# add to pubspec.yaml:')
      ..writeln('dependencies:');
    deps.forEach((n, v) => b.writeln('  $n: $v'));
  }
  b
    ..writeln()
    ..writeln('# copy the whole folder (${files.length} file(s)):')
    ..writeln('#   ${files.keys.join(', ')}')
    ..writeln("import '$id/${m['entry']}';");
  if (assetsRequired.isNotEmpty) {
    b
      ..writeln()
      ..writeln('# add to pubspec.yaml under the `assets:` key:');
    for (final String a in assetsRequired) {
      b.writeln('#   - $a');
    }
  }
  if (shadersRequired.isNotEmpty) {
    b
      ..writeln()
      ..writeln(
        '# add to pubspec.yaml under the `shaders:` key (NOT assets:):',
      );
    for (final String s in shadersRequired) {
      b.writeln('#   - $s');
    }
  }
  final String caveats = _section(fm.body, '## Caveats');
  if (caveats.isNotEmpty) {
    b
      ..writeln()
      ..writeln('# caveats:')
      ..writeln(caveats);
  }
  if (m['scale_aware'] == true) {
    b
      ..writeln()
      ..writeln(
        '# scale hint: this paint takes a `scale` param — lower it on '
        'small carriers (see the Carriers/API tables in the README)',
      );
  }
  stdout.write(b);
}

String _section(String body, String heading) {
  final List<String> lines = body.split('\n');
  final int at = lines.indexWhere((l) => l.trim() == heading);
  if (at == -1) {
    return '';
  }
  final List<String> out = [];
  for (int i = at + 1; i < lines.length; i++) {
    if (lines[i].trim().startsWith('## ')) {
      break;
    }
    out.add(lines[i]);
  }
  return out.join('\n').trim();
}
