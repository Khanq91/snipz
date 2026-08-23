// SESSION.yaml — the single current work-batch flag ("đợt"). The app shows
// NEW/FIX badges and a gallery filter for exactly one latest session; there
// is no history (user decision, 2026-08-23). build_index.dart embeds the
// parsed block into assets/index.json; validate.dart checks it (#11).

import 'dart:io';

import 'package:yaml/yaml.dart';

const String sessionPath = 'SESSION.yaml';

class SessionData {
  const SessionData({
    required this.id,
    required this.title,
    required this.date,
    required this.added,
    required this.fixed,
  });

  final String id;
  final String? title;
  final String date;
  final List<String> added;
  final List<String> fixed;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'added': added,
        'fixed': fixed,
      };
}

/// Parses SESSION.yaml. Returns null when the file does not exist (the flag
/// is optional); throws FormatException on a malformed file — validate turns
/// that into a failure, build_index refuses to write.
SessionData? readSession() {
  final File f = File(sessionPath);
  if (!f.existsSync()) {
    return null;
  }
  final Object? doc;
  try {
    doc = loadYaml(f.readAsStringSync());
  } on YamlException catch (e) {
    throw FormatException('$sessionPath: YAML error — ${e.message}');
  }
  if (doc is! YamlMap) {
    throw const FormatException('$sessionPath: expected a YAML map');
  }
  final YamlMap map = doc;
  final Object? id = map['id'];
  if (id == null || '$id'.trim().isEmpty) {
    throw const FormatException('$sessionPath: missing required field: id');
  }
  final Object? date = map['date'];
  if (date == null) {
    throw const FormatException('$sessionPath: missing required field: date');
  }
  List<String> ids(String key) {
    final Object? node = map[key];
    if (node == null) {
      return const [];
    }
    if (node is! YamlList) {
      throw FormatException('$sessionPath: $key must be a list of ids');
    }
    return node.map((e) => '$e').toList();
  }

  return SessionData(
    id: '$id',
    title: map['title'] == null ? null : '${map['title']}',
    date: '$date',
    added: ids('added'),
    fixed: ids('fixed'),
  );
}
