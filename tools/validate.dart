// dart tools/validate.dart [--fix]
//
// The most important script (§10). Exit code != 0 on any failure — wired
// into CI (and later the pre-commit hook). The manifest cannot lie because
// it is verified, not trusted (§3.2).
//
// Checks:
//   #1  real import graph vs `files:` manifest (set of names)
//   #2  portability — no relative import out of the folder, no package
//       outside `deps` (NOT created_deps — decision #3)
//   #3  entry exists + named after the folder + has a public API
//   #4  no orphans — every _*.dart reachable from the entry (§0.4a: the
//       graph follows import AND export AND part)
//   #5  naming — support files start with `_`; <id>_demo.dart is exempt from
//       portability but must not import junk from outside the repo
//   #6  frontmatter schema — required fields, enums, dates; `stale` is
//       rejected (decision #5)
//   #7  registry sync — lib/registry.dart matches the folders
//   #8  artifact sync — committed assets match READMEs + sources
//       (stale → fail, hint to run build_index)
//   #9  origin/license — adapted/copied require source + license != unknown
//   #10 warning (no fail) — kind: paint with scale_aware: false
//   #11 session — SESSION.yaml well-formed, ids exist, no id in both lists;
//       the embedded `session` in index.json must match (via #8)
//
// --fix rewrites the `files:` block from the real graph (decision #7) and
// regenerates the artifacts, then re-checks.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'src/build_index_lib.dart';
import 'src/flutter_env.dart';
import 'src/frontmatter.dart';
import 'src/import_graph.dart';
import 'src/paths.dart';
import 'src/registry_edit.dart';
import 'src/schema.dart';
import 'src/session.dart';
import 'src/test_history.dart';

final List<String> _failures = [];
final List<String> _warnings = [];

void fail(String id, String check, String message) =>
    _failures.add('FAIL [$id] $check: $message');

void warn(String id, String message) => _warnings.add('WARN [$id] $message');

Future<void> main(List<String> args) async {
  requireRepoRoot();
  if (args.contains('--fix')) {
    await _fixFilesBlocks();
  }

  final List<Directory> folders = componentFolders();
  for (final Directory folder in folders) {
    _checkComponent(folder);
  }
  _checkRegistrySync(folders);
  _checkSession(folders);
  _checkArtifactSync();

  _warnings.forEach(stdout.writeln);
  _failures.forEach(stdout.writeln);
  if (_failures.isEmpty) {
    stdout.writeln(
      'validate: OK — ${folders.length} component(s), '
      '${_warnings.length} warning(s)',
    );
  } else {
    stdout.writeln('validate: ${_failures.length} failure(s)');
    exitCode = 1;
  }
}

void _checkComponent(Directory folder) {
  final String id = idOfFolder(folder);
  final File readme = File('${folder.path}/README.md');
  if (!readme.existsSync()) {
    fail(id, '#6 schema', 'README.md is missing');
    return;
  }
  final Frontmatter fm;
  try {
    fm = parseFrontmatter(readme.readAsStringSync(), id: id);
  } on FormatException catch (e) {
    fail(id, '#6 schema', e.message);
    return;
  }
  final Map<String, Object?> m = fm.map;
  _checkSchema(id, m);
  try {
    parseTestHistory(fm.body, id);
  } on FormatException catch (e) {
    fail(id, '#6 schema', e.message);
  }

  final List<String> allDart = dartFileNames(folder);
  final String entryName = '$id.dart';
  final String demoName = '${id}_demo.dart';

  // #3 entry
  if (!allDart.contains(entryName)) {
    fail(
      id,
      '#3 entry',
      '$entryName not found (entry must match the folder name)',
    );
  } else if (!entryHasPublicApi(
    File('${folder.path}/$entryName').readAsStringSync(),
  )) {
    fail(id, '#3 entry', '$entryName has no public symbol and no export');
  }
  if (m['entry'] != null && m['entry'] != entryName) {
    fail(
      id,
      '#3 entry',
      "frontmatter entry is '${m['entry']}', expected '$entryName'",
    );
  }

  // #5 naming
  for (final String f in allDart) {
    if (f != entryName && f != demoName && !f.startsWith('_')) {
      fail(id, '#5 naming', '$f: support files must be prefixed with _');
    }
  }

  // graph: #1 manifest + #4 orphans
  final Set<String> graphFiles = allDart.where((f) => f != demoName).toSet();
  final ComponentGraph graph = buildComponentGraph(
    folder: folder,
    entryName: entryName,
    allDartFiles: graphFiles,
  );
  Map<String, String> manifest = {};
  try {
    manifest = pairsToMap(m['files'], id: id, field: 'files');
  } on FormatException catch (e) {
    fail(id, '#6 schema', e.message);
  }
  final Set<String> manifestSet = manifest.keys.toSet();
  for (final String missing in graph.reachable.difference(manifestSet)) {
    fail(
      id,
      '#1 manifest',
      '$missing is in the import graph but not in files: '
          '(run: dart tools/validate.dart --fix)',
    );
  }
  for (final String extra in manifestSet.difference(graph.reachable)) {
    fail(
      id,
      '#1 manifest',
      '$extra is listed in files: but not reachable '
          'from $entryName (run: dart tools/validate.dart --fix)',
    );
  }
  for (final String f in graphFiles) {
    if (f != entryName && !graph.reachable.contains(f)) {
      fail(
        id,
        '#4 orphan',
        '$f is not reachable from $entryName '
            '(import graph follows import/export/part)',
      );
    }
  }

  // #2 portability (all non-demo files) + demo hygiene (#5 second half)
  Map<String, String> deps = {};
  try {
    deps = pairsToMap(m['deps'], id: id, field: 'deps');
  } on FormatException {
    // already reported via schema
  }
  for (final String f in allDart) {
    final bool isDemo = f == demoName;
    for (final Directive d in directivesOf(
      File('${folder.path}/$f').readAsStringSync(),
    )) {
      _checkDirective(id, f, d, isDemo: isDemo, deps: deps);
    }
  }

  // #10 warning
  if (m['kind'] == 'paint' && m['scale_aware'] != true) {
    warn(
      id,
      'kind: paint without scale_aware: true — small carriers will '
      'flatten the paint (§9.1)',
    );
  }
}

void _checkDirective(
  String id,
  String file,
  Directive d, {
  required bool isDemo,
  required Map<String, String> deps,
}) {
  final String uri = d.uri;
  final String check = isDemo ? '#5 demo' : '#2 portability';
  if (uri.startsWith('dart:')) {
    return;
  }
  if (uri.startsWith('package:')) {
    final int slash = uri.indexOf('/');
    final String pkg = uri.substring(8, slash == -1 ? uri.length : slash);
    if (pkg == 'flutter') {
      return;
    }
    if (isDemo) {
      if (pkg == 'snipz' || _appDeps().contains(pkg)) {
        return;
      }
      fail(id, check, "$file imports '$uri' — package not in the app pubspec");
      return;
    }
    if (deps.containsKey(pkg)) {
      return;
    }
    fail(
      id,
      check,
      "$file imports '$uri' — '$pkg' is not declared in deps "
      '(created_deps does not count, decision #3)',
    );
    return;
  }
  final String rel = uri.startsWith('./') ? uri.substring(2) : uri;
  if (rel.startsWith('../')) {
    fail(id, check, "$file imports '$uri' — relative import leaves the folder");
  } else if (rel.contains('/')) {
    fail(id, check, "$file imports '$uri' — keep component folders flat");
  }
}

Set<String>? _appDepsCache;

/// Direct dependencies of the app pubspec — what demo files may import.
Set<String> _appDeps() {
  if (_appDepsCache != null) {
    return _appDepsCache!;
  }
  final Object? doc = loadYaml(File(pubspecPath).readAsStringSync());
  final Set<String> out = {};
  if (doc is YamlMap) {
    final Object? deps = doc['dependencies'];
    if (deps is YamlMap) {
      for (final MapEntry<Object?, Object?> e in deps.entries) {
        out.add('${e.key}');
      }
    }
  }
  return _appDepsCache = out;
}

void _checkSchema(String id, Map<String, Object?> m) {
  void need(String key) {
    if (!m.containsKey(key) || m[key] == null) {
      fail(id, '#6 schema', 'missing required field: $key');
    }
  }

  void needEnum(String key, List<String> allowed) {
    final Object? v = m[key];
    if (v == null) {
      return; // absence handled by need()
    }
    if (!allowed.contains(v)) {
      fail(id, '#6 schema', "$key: '$v' is not one of $allowed");
    }
  }

  for (final String key in [
    'id',
    'title',
    'kind',
    'tags',
    'paint_source',
    'carriers_verified',
    'scale_aware',
    'portability',
    'entry',
    'files',
    'deps',
    'origin',
    'author',
    'created',
    'created_flutter',
    'created_dart',
    'created_deps',
    'platforms_initial',
    'version',
  ]) {
    need(key);
  }
  if (m['id'] != null && m['id'] != id) {
    fail(id, '#6 schema', "id: '${m['id']}' does not match the folder name");
  }
  needEnum('kind', kinds);
  needEnum('paint_source', paintSources);
  needEnum('portability', portabilities);
  needEnum('origin', origins);
  for (final String c in stringList(m['carriers_verified'])) {
    if (!carrierNames.contains(c)) {
      fail(
        id,
        '#6 schema',
        "carriers_verified: '$c' is not one of $carrierNames",
      );
    }
  }
  try {
    for (final String c in pairsToMap(
      m['carriers_failed'],
      id: id,
      field: 'carriers_failed',
    ).keys) {
      if (!carrierNames.contains(c)) {
        fail(
          id,
          '#6 schema',
          "carriers_failed: '$c' is not one of $carrierNames",
        );
      }
    }
  } on FormatException catch (e) {
    fail(id, '#6 schema', e.message);
  }
  if (m['scale_aware'] != null && m['scale_aware'] is! bool) {
    fail(id, '#6 schema', 'scale_aware must be a bool');
  }
  if (m['created'] != null && !dateRe.hasMatch('${m['created']}')) {
    fail(id, '#6 schema', "created: '${m['created']}' is not YYYY-MM-DD");
  }
  if (m['last_verified'] != null && !dateRe.hasMatch('${m['last_verified']}')) {
    fail(
      id,
      '#6 schema',
      "last_verified: '${m['last_verified']}' is not YYYY-MM-DD",
    );
  }
  if (m['version'] != null && !semverRe.hasMatch('${m['version']}')) {
    fail(id, '#6 schema', "version: '${m['version']}' is not semver (x.y.z)");
  }
  final Object? status = m['status'];
  if (status == 'stale') {
    fail(
      id,
      '#6 schema',
      "status: 'stale' is not storable — the app derives "
          'staleness from last_verified at runtime (decision #5)',
    );
  } else if (status != null && !statuses.contains(status)) {
    fail(
      id,
      '#6 schema',
      "status: '$status' is not one of $statuses (or null "
          'before the first verify)',
    );
  }
  final Object? portability = m['portability'];
  if (portability == 'folder_with_assets' &&
      stringList(m['assets_required']).isEmpty &&
      stringList(m['shaders_required']).isEmpty) {
    fail(
      id,
      '#6 schema',
      'folder_with_assets requires assets_required or '
          'shaders_required to be non-empty',
    );
  }
  if (portability == 'single_file') {
    try {
      final int n = pairsToMap(m['files'], id: id, field: 'files').length;
      if (n != 1) {
        fail(id, '#6 schema', 'single_file but files: lists $n files');
      }
    } on FormatException {
      // already reported
    }
  }

  // #9 origin/license (§0.3)
  final Object? origin = m['origin'];
  if (origin == 'adapted' || origin == 'copied') {
    final String source = '${m['source'] ?? ''}';
    final String license = '${m['license'] ?? ''}';
    if (source.isEmpty || source == 'null') {
      fail(id, '#9 origin', 'origin: $origin requires a non-empty source');
    }
    if (license.isEmpty ||
        license == 'null' ||
        license.toLowerCase() == 'unknown') {
      fail(
        id,
        '#9 origin',
        "origin: $origin requires a real license (got '${m['license']}') — "
            'the original license still binds the copied file (§0.3)',
      );
    }
  }
}

void _checkRegistrySync(List<Directory> folders) {
  final File registry = File(registryPath);
  if (!registry.existsSync()) {
    fail('registry', '#7 registry', '$registryPath is missing');
    return;
  }
  final Set<String> registered = registryIds(
    registry.readAsStringSync(),
  ).toSet();
  final Set<String> folderIds = {
    for (final Directory f in folders) idOfFolder(f),
  };
  for (final String id in folderIds.difference(registered)) {
    fail(
      id,
      '#7 registry',
      'not registered in $registryPath '
          '(new_component.dart inserts this automatically)',
    );
  }
  for (final String id in registered.difference(folderIds)) {
    fail(
      id,
      '#7 registry',
      'registered in $registryPath but '
          '$componentsDir/$id/ does not exist',
    );
  }
}

/// #11 — the current work-batch flag. Optional file; when present every id
/// must be a real component and added/fixed must not overlap.
void _checkSession(List<Directory> folders) {
  final SessionData? session;
  try {
    session = readSession();
  } on FormatException catch (e) {
    fail('session', '#11 session', e.message);
    return;
  }
  if (session == null) {
    return;
  }
  if (!dateRe.hasMatch(session.date)) {
    fail(
      'session',
      '#11 session',
      "date: '${session.date}' is not YYYY-MM-DD",
    );
  }
  final Set<String> known = {for (final Directory f in folders) idOfFolder(f)};
  for (final String id in [...session.added, ...session.fixed]) {
    if (!known.contains(id)) {
      fail(
        'session',
        '#11 session',
        "'$id' is not a component folder under $componentsDir/",
      );
    }
  }
  final Set<String> both =
      session.added.toSet().intersection(session.fixed.toSet());
  for (final String id in both) {
    fail(
      'session',
      '#11 session',
      "'$id' is in both added and fixed — pick one",
    );
  }
}

void _checkArtifactSync() {
  final List<BuiltComponent> expected;
  try {
    expected = computeArtifacts();
  } on FormatException {
    return; // parse problems already reported per component
  }
  final File indexFile = File(indexPath);
  if (!indexFile.existsSync()) {
    fail(
      'index',
      '#8 artifacts',
      '$indexPath is missing — run: dart tools/build_index.dart',
    );
    return;
  }
  final Map<String, Object?> committed;
  try {
    committed =
        jsonDecode(indexFile.readAsStringSync()) as Map<String, Object?>;
  } on FormatException {
    fail(
      'index',
      '#8 artifacts',
      '$indexPath is not valid JSON — run: dart tools/build_index.dart',
    );
    return;
  }
  final String want = artifactEncoder.convert([
    for (final BuiltComponent c in expected) c.meta,
  ]);
  final String have = artifactEncoder.convert(committed['components']);
  if (want != have) {
    fail(
      'index',
      '#8 artifacts',
      '$indexPath is stale vs the READMEs — '
          'run: dart tools/build_index.dart',
    );
  }
  try {
    final SessionData? session = readSession();
    if (artifactEncoder.convert(session?.toJson()) !=
        artifactEncoder.convert(committed['session'])) {
      fail(
        'session',
        '#8 artifacts',
        '$indexPath session block is stale vs $sessionPath — '
            'run: dart tools/build_index.dart',
      );
    }
  } on FormatException {
    // malformed SESSION.yaml already reported by #11
  }
  final Set<String> ids = {for (final BuiltComponent c in expected) c.id};
  for (final BuiltComponent c in expected) {
    final File f = File('$sourcesDir/${c.id}.json');
    if (!f.existsSync()) {
      fail(
        c.id,
        '#8 artifacts',
        '$sourcesDir/${c.id}.json is missing — '
            'run: dart tools/build_index.dart',
      );
      continue;
    }
    Object? onDisk;
    try {
      onDisk = jsonDecode(f.readAsStringSync());
    } on FormatException {
      onDisk = null;
    }
    if (artifactEncoder.convert(onDisk) != artifactEncoder.convert(c.sources)) {
      fail(
        c.id,
        '#8 artifacts',
        '$sourcesDir/${c.id}.json is stale — '
            'run: dart tools/build_index.dart',
      );
    }
  }
  final Directory sources = Directory(sourcesDir);
  if (sources.existsSync()) {
    for (final FileSystemEntity e in sources.listSync()) {
      if (e is! File || !e.path.endsWith('.json')) {
        continue;
      }
      final String name = e.path
          .split(RegExp(r'[\\/]'))
          .last
          .replaceAll('.json', '');
      if (!ids.contains(name)) {
        fail(
          name,
          '#8 artifacts',
          '$sourcesDir/$name.json has no component '
              'folder — run: dart tools/build_index.dart',
        );
      }
    }
  }
}

/// --fix: rewrite each `files:` block from the real graph, then regenerate
/// the artifacts so check #8 stays green.
Future<void> _fixFilesBlocks() async {
  int fixed = 0;
  for (final Directory folder in componentFolders()) {
    final String id = idOfFolder(folder);
    final File readme = File('${folder.path}/README.md');
    if (!readme.existsSync()) {
      continue;
    }
    final Frontmatter fm;
    try {
      fm = parseFrontmatter(readme.readAsStringSync(), id: id);
    } on FormatException {
      continue; // schema check will report it
    }
    final String entryName = '$id.dart';
    final String demoName = '${id}_demo.dart';
    final Set<String> graphFiles = dartFileNames(
      folder,
    ).where((f) => f != demoName).toSet();
    final ComponentGraph graph = buildComponentGraph(
      folder: folder,
      entryName: entryName,
      allDartFiles: graphFiles,
    );
    Map<String, String> manifest = {};
    try {
      manifest = pairsToMap(fm.map['files'], id: id, field: 'files');
    } on FormatException {
      // rewrite from scratch below
    }
    if (manifest.keys.toSet().difference(graph.reachable).isEmpty &&
        graph.reachable.difference(manifest.keys.toSet()).isEmpty) {
      continue;
    }
    final List<MapEntry<String, String>> entries = [
      for (final String f in graph.reachable)
        MapEntry(
          f,
          f == entryName
              ? 'entry, public API'
              : 'required by ${graph.firstImporter[f]}',
        ),
    ];
    final String newYaml = setFilesBlock(fm.yamlText, entries);
    readme.writeAsStringSync(assembleReadme(newYaml, fm.body));
    stdout.writeln(
      'fix [$id]: rewrote files: block (${entries.length} file(s))',
    );
    fixed++;
  }
  if (fixed > 0) {
    writeArtifacts(await readFlutterEnv());
    stdout.writeln('fix: regenerated artifacts for $fixed component(s)');
  } else {
    stdout.writeln('fix: nothing to fix');
  }
}
