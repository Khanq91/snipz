// README.md frontmatter: parsing (yaml package) and line-level surgery for
// the fields scripts own. The README stays the single source of truth (§5) —
// scripts edit it surgically instead of round-tripping YAML, so hand-written
// comments and formatting survive.

import 'package:yaml/yaml.dart';

class Frontmatter {
  const Frontmatter({
    required this.yamlText,
    required this.body,
    required this.map,
  });

  /// Raw text between the `---` fences (fences excluded).
  final String yamlText;

  /// Everything after the closing fence.
  final String body;

  /// Deep plain-Dart copy of the parsed YAML.
  final Map<String, Object?> map;
}

/// Splits and parses README frontmatter. Errors carry the component id and a
/// 1-based line number in README.md (§10: report id + line, never swallow).
Frontmatter parseFrontmatter(String readme, {required String id}) {
  final List<String> lines = readme.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    throw const FormatException(
      'README.md line 1: file must start with a --- frontmatter fence',
    ).withId(id);
  }
  int close = -1;
  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      close = i;
      break;
    }
  }
  if (close == -1) {
    throw const FormatException(
      'README.md: closing --- fence not found',
    ).withId(id);
  }
  final String yamlText = lines.sublist(1, close).join('\n');
  final String body = lines.sublist(close + 1).join('\n');
  Object? doc;
  try {
    doc = loadYaml(yamlText);
  } on YamlException catch (e) {
    final int line = (e.span?.start.line ?? 0) + 2; // 0-based + leading fence
    throw FormatException(
      'README.md line $line: frontmatter YAML error — ${e.message}',
    ).withId(id);
  }
  if (doc is! YamlMap) {
    throw const FormatException(
      'README.md: frontmatter is not a YAML map',
    ).withId(id);
  }
  return Frontmatter(yamlText: yamlText, body: body, map: _plainMap(doc));
}

/// Rebuilds a README from (possibly edited) parts.
String assembleReadme(String yamlText, String body) =>
    '---\n$yamlText\n---\n$body';

extension _WithId on FormatException {
  FormatException withId(String id) => FormatException('[$id] $message');
}

Map<String, Object?> _plainMap(YamlMap node) => {
  for (final MapEntry<Object?, Object?> e in node.entries)
    '${e.key}': _plain(e.value),
};

Object? _plain(Object? node) {
  if (node is YamlMap) {
    return _plainMap(node);
  }
  if (node is YamlList) {
    return node.map(_plain).toList();
  }
  return node;
}

/// `deps: []` / `files:` style values: a list of single-entry maps
/// (`- blur: ^4.0.1`) or a direct map. Returns an ordered name -> value map.
Map<String, String> pairsToMap(
  Object? node, {
  required String id,
  required String field,
}) {
  if (node == null) {
    return {};
  }
  if (node is Map<String, Object?>) {
    return node.map((k, v) => MapEntry(k, '$v'));
  }
  if (node is List) {
    final Map<String, String> out = {};
    for (final Object? item in node) {
      if (item is! Map<String, Object?> || item.length != 1) {
        throw FormatException(
          '[$id] $field: each item must be a single `name: value` pair',
        );
      }
      final MapEntry<String, Object?> e = item.entries.first;
      out[e.key] = '${e.value}';
    }
    return out;
  }
  throw FormatException('[$id] $field: expected a list or a map');
}

List<String> stringList(Object? node) =>
    (node as List<Object?>? ?? []).map((e) => '$e').toList();

/// Replaces the value of one top-level scalar key in frontmatter text,
/// keeping any trailing comment on that line. Appends the key if absent.
String setScalar(String yamlText, String key, String value) {
  final RegExp re = RegExp('^$key:[^#\\n]*(#.*)?\$', multiLine: true);
  if (!re.hasMatch(yamlText)) {
    return '$yamlText\n$key: $value';
  }
  return yamlText.replaceFirstMapped(re, (m) {
    final String? comment = m.group(1);
    return comment == null ? '$key: $value' : '$key: $value  $comment';
  });
}

/// Rewrites the `files:` block from computed (name, role) entries — used by
/// validate --fix (decision #7). Inserts after `entry:` if the block is
/// missing entirely.
String setFilesBlock(String yamlText, List<MapEntry<String, String>> files) {
  final List<String> block = [
    'files:',
    for (final MapEntry<String, String> f in files)
      '  - ${f.key}: "${f.value}"',
  ];
  final List<String> lines = yamlText.split('\n');
  final int start = lines.indexWhere((l) => l.startsWith('files:'));
  if (start == -1) {
    final int entryAt = lines.indexWhere((l) => l.startsWith('entry:'));
    final int at = entryAt == -1 ? lines.length : entryAt + 1;
    lines.insertAll(at, block);
    return lines.join('\n');
  }
  int end = start + 1;
  while (end < lines.length && lines[end].trimLeft().startsWith('- ')) {
    end++;
  }
  lines.replaceRange(start, end, block);
  return lines.join('\n');
}
