// lib/registry.dart surgery for new_component.dart, plus the id listing used
// by validate.dart check #7 (registry sync).

final RegExp _entryRe = RegExp(
  r"^\s{2}'([a-z][a-z0-9_]*)':\s*\w+,\s*$",
  multiLine: true,
);

List<String> registryIds(String source) =>
    _entryRe.allMatches(source).map((m) => m.group(1)!).toList();

/// Inserts the demo import and the map entry, both in alphabetical order.
/// Idempotent — returns the source unchanged if the id is already there.
String insertIntoRegistry(String source, String id, String demoVar) {
  if (registryIds(source).contains(id)) {
    return source;
  }
  final String importLine =
      "import 'package:snipz/components/$id/${id}_demo.dart';";
  final String entryLine = "  '$id': $demoVar,";
  final List<String> lines = source.split('\n');

  int importAt = -1;
  for (int i = 0; i < lines.length; i++) {
    final String l = lines[i];
    if (l.startsWith("import 'package:snipz/components/")) {
      importAt = i + 1;
      if (l.compareTo(importLine) > 0) {
        importAt = i;
        break;
      }
    } else if (l.startsWith("import 'package:snipz/core/") && importAt == -1) {
      importAt = i;
      break;
    }
  }
  if (importAt == -1) {
    importAt = 0;
  }
  lines.insert(importAt, importLine);

  int entryAt = -1;
  for (int i = 0; i < lines.length; i++) {
    final String l = lines[i];
    if (_entryRe.hasMatch(l)) {
      entryAt = i + 1;
      if (l.compareTo(entryLine) > 0) {
        entryAt = i;
        break;
      }
    } else if (l.startsWith('};') && entryAt == -1) {
      entryAt = i;
      break;
    }
  }
  if (entryAt == -1) {
    entryAt = lines.length;
  }
  lines.insert(entryAt, entryLine);
  return lines.join('\n');
}
