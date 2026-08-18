// Core of build_index.dart, shared with validate.dart (artifact-sync check)
// and called by new_component.dart / verify.dart after they touch READMEs.
//
// lib/components/*/README.md + *.dart are the source of truth; the artifacts
// under assets/ are derived, never hand-edited, and committed (§5.0).

import 'dart:convert';
import 'dart:io';

import 'flutter_env.dart';
import 'frontmatter.dart';
import 'paths.dart';
import 'test_history.dart';

class BuiltComponent {
  const BuiltComponent({
    required this.id,
    required this.meta,
    required this.sources,
  });

  final String id;

  /// Normalized entry for assets/index.json `components`.
  final Map<String, Object?> meta;

  /// Payload of `assets/sources/<id>.json`.
  final Map<String, Object?> sources;
}

/// Committed artifacts must be byte-identical no matter how git checked the
/// sources out (core.autocrlf gives CRLF working trees on Windows, LF on CI),
/// so every embedded text is canonicalized to LF.
String _readLf(File f) => f.readAsStringSync().replaceAll('\r\n', '\n');

/// Parses every component into artifact payloads. Collects ALL problems and
/// throws one FormatException — never silently skips a component (§10).
List<BuiltComponent> computeArtifacts() {
  final List<String> errors = [];
  final List<BuiltComponent> out = [];
  for (final Directory folder in componentFolders()) {
    final String id = idOfFolder(folder);
    try {
      final File readme = File('${folder.path}/README.md');
      if (!readme.existsSync()) {
        throw FormatException('[$id] README.md is missing');
      }
      final Frontmatter fm = parseFrontmatter(_readLf(readme), id: id);
      final Map<String, Object?> m = fm.map;
      final Map<String, String> files = pairsToMap(
        m['files'],
        id: id,
        field: 'files',
      );
      final Map<String, Object?> meta = {
        'id': m['id'],
        'title': m['title'],
        'kind': m['kind'],
        'tags': stringList(m['tags']),
        'paint_source': m['paint_source'],
        'carriers_verified': stringList(m['carriers_verified']),
        'carriers_failed': pairsToMap(
          m['carriers_failed'],
          id: id,
          field: 'carriers_failed',
        ),
        'scale_aware': m['scale_aware'],
        'portability': m['portability'],
        'entry': m['entry'],
        'files': files,
        'vendored_from': m['vendored_from'],
        'assets_required': stringList(m['assets_required']),
        'shaders_required': stringList(m['shaders_required']),
        'deps': pairsToMap(m['deps'], id: id, field: 'deps'),
        'origin': m['origin'],
        'source': m['source'],
        'author': m['author'],
        'license': m['license'],
        'created': '${m['created']}',
        'created_flutter': '${m['created_flutter']}',
        'created_dart': '${m['created_dart']}',
        'created_deps': pairsToMap(
          m['created_deps'],
          id: id,
          field: 'created_deps',
        ),
        'platforms_initial': stringList(m['platforms_initial']),
        'version': '${m['version']}',
        'latest_known_good': m['latest_known_good'] == null
            ? null
            : '${m['latest_known_good']}',
        'last_verified': m['last_verified'] == null
            ? null
            : '${m['last_verified']}',
        'status': m['status'],
        'preview': m['preview'],
        'file_count': files.length,
        'test_history': parseTestHistory(
          fm.body,
          id,
        ).map((r) => r.toJson()).toList(),
      };
      final Map<String, Object?> sources = {
        '_generated': true,
        'id': id,
        'readme_body': fm.body,
        'files': {
          for (final String name in dartFileNames(folder))
            name: _readLf(File('${folder.path}/$name')),
        },
      };
      out.add(BuiltComponent(id: id, meta: meta, sources: sources));
    } on FormatException catch (e) {
      errors.add(e.message);
    }
  }
  if (errors.isNotEmpty) {
    throw FormatException(errors.join('\n'));
  }
  return out;
}

const JsonEncoder artifactEncoder = JsonEncoder.withIndent('  ');

String encodeSources(BuiltComponent c) =>
    '${artifactEncoder.convert(c.sources)}\n';

/// Normalized https URL of remote `origin`, or null when the repo has none.
/// Stamped into the index so the app's share sheet can link GitHub (§8.6) —
/// the app cannot run git at runtime.
String? readGitRemote() {
  final ProcessResult r = Process.runSync('git', [
    'config',
    '--get',
    'remote.origin.url',
  ], runInShell: true);
  if (r.exitCode != 0) return null;
  String url = (r.stdout as String).trim();
  if (url.isEmpty) return null;
  final RegExpMatch? ssh = RegExp(r'^git@([^:]+):(.+)$').firstMatch(url);
  if (ssh != null) url = 'https://${ssh.group(1)}/${ssh.group(2)}';
  if (url.endsWith('.git')) url = url.substring(0, url.length - 4);
  return url;
}

String encodeIndex(
  List<BuiltComponent> comps, {
  required String generatedAt,
  required FlutterEnv env,
  String? remote,
}) =>
    '${artifactEncoder.convert({
      '_generated': true,
      '_generated_at': generatedAt,
      '_generated_flutter': env.flutter,
      '_generated_dart': env.dart,
      '_generated_remote': remote,
      'components': [for (final BuiltComponent c in comps) c.meta],
    })}\n';

/// Writes assets/index.json + assets/sources/*.json and removes stale source
/// files for deleted components. Returns the component count.
int writeArtifacts(FlutterEnv env) {
  final List<BuiltComponent> comps = computeArtifacts();
  Directory(sourcesDir).createSync(recursive: true);
  File(indexPath).writeAsStringSync(
    encodeIndex(
      comps,
      generatedAt: DateTime.now().toUtc().toIso8601String(),
      env: env,
      remote: readGitRemote(),
    ),
  );
  final Set<String> keep = {for (final BuiltComponent c in comps) c.id};
  for (final FileSystemEntity e in Directory(sourcesDir).listSync()) {
    if (e is File && e.path.endsWith('.json')) {
      final String name = e.path
          .split(RegExp(r'[\\/]'))
          .last
          .replaceAll('.json', '');
      if (!keep.contains(name)) {
        e.deleteSync();
      }
    }
  }
  for (final BuiltComponent c in comps) {
    File('$sourcesDir/${c.id}.json').writeAsStringSync(encodeSources(c));
  }
  return comps.length;
}
