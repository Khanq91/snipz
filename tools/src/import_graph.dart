// Import graph built with regex over import/export/part directives (§0.4a).
// Deliberately NOT package:analyzer — this must survive every Flutter
// upgrade. `export` edges are required: entries re-export support files, and
// without them those files would look orphaned (check #4 would fail wrongly).
// Known regex limits (accepted): conditional-import URIs and directives
// inside block comments are not seen.

import 'dart:io';

final RegExp _directiveRe = RegExp(
  r'''^\s*(import|export|part)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
// `part of 'x.dart';` never matches (the `of` sits before the quote) — good:
// part-of is the reverse edge of `part`, which is already followed.

class Directive {
  const Directive(this.kind, this.uri);

  final String kind; // import | export | part
  final String uri;
}

List<Directive> directivesOf(String source) => _directiveRe
    .allMatches(source)
    .map((m) => Directive(m.group(1)!, m.group(2)!))
    .toList();

class ComponentGraph {
  const ComponentGraph({required this.reachable, required this.firstImporter});

  /// File names reachable from the entry (entry included), insertion-ordered
  /// by BFS discovery.
  final Set<String> reachable;

  /// file -> the file that first reached it (role text for --fix).
  final Map<String, String> firstImporter;
}

/// BFS from the entry over in-folder relative URIs. Package/dart URIs are
/// portability's concern (check #2), not the graph's. Component folders are
/// flat — any relative URI containing `/` is treated as leaving the folder
/// and is reported by check #2.
ComponentGraph buildComponentGraph({
  required Directory folder,
  required String entryName,
  required Set<String> allDartFiles,
}) {
  final Set<String> reachable = {entryName};
  final Map<String, String> firstImporter = {};
  final List<String> queue = [entryName];
  while (queue.isNotEmpty) {
    final String current = queue.removeAt(0);
    final File file = File('${folder.path}/$current');
    if (!file.existsSync()) {
      continue;
    }
    for (final Directive d in directivesOf(file.readAsStringSync())) {
      if (d.uri.startsWith('dart:') || d.uri.startsWith('package:')) {
        continue;
      }
      final String rel = d.uri.startsWith('./') ? d.uri.substring(2) : d.uri;
      if (rel.contains('/') || !allDartFiles.contains(rel)) {
        continue; // escaping or missing — surfaced by other checks
      }
      if (reachable.add(rel)) {
        firstImporter[rel] = current;
        queue.add(rel);
      }
    }
  }
  return ComponentGraph(reachable: reachable, firstImporter: firstImporter);
}

/// True when the entry declares at least one public top-level symbol or
/// re-exports something — the machine-checkable form of "entry exposes the
/// public API" (decision #8a).
bool entryHasPublicApi(String source) {
  final RegExp decl = RegExp(
    r'^(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*'
    r'(?:class|mixin|enum|extension|typedef)\s+[a-zA-Z]',
    multiLine: true,
  );
  final RegExp topLevelValueOrFn = RegExp(
    r'^(?:const\s+|final\s+|late\s+)?[A-Za-z][\w<>,.? ]*\s[a-zA-Z]\w*\s*[(=]',
    multiLine: true,
  );
  return decl.hasMatch(source) ||
      topLevelValueOrFn.hasMatch(source) ||
      directivesOf(source).any((d) => d.kind == 'export');
}
