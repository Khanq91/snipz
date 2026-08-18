// Test History table (spec §5.1 layer 3): append-only markdown table in the
// README body. verify.dart appends rows (newest first); build_index parses
// them into index.json so compat badges work from a single startup read.

import 'flutter_env.dart';
import 'schema.dart';

const String historyHeading = '## Test History';
const String historyTableHeader =
    '| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |';
const String historyTableSep = '|---|---|---|---|---|---|---|';

class TestRow {
  const TestRow({
    required this.date,
    required this.flutter,
    required this.dart,
    required this.depsResolved,
    required this.platform,
    required this.result,
    required this.note,
  });

  final String date;
  final String flutter;
  final String dart;
  final String depsResolved;
  final String platform;
  final String result;
  final String note;

  String toLine() =>
      '| $date | $flutter | $dart | $depsResolved | $platform | $result | $note |';

  Map<String, Object?> toJson() => {
    'date': date,
    'flutter': flutter,
    'dart': dart,
    'deps_resolved': depsResolved,
    'platform': platform,
    'result': result,
    'note': note,
  };
}

List<TestRow> parseTestHistory(String body, String id) {
  final List<String> lines = body.split('\n');
  final int at = lines.indexWhere((l) => l.trim() == historyHeading);
  if (at == -1) {
    return []; // authored components may not have the section yet (§0.3 flow)
  }
  final List<TestRow> rows = [];
  bool inTable = false;
  for (int i = at + 1; i < lines.length; i++) {
    final String line = lines[i].trim();
    if (line.startsWith('## ')) {
      break;
    }
    if (!line.startsWith('|')) {
      if (inTable) {
        break;
      }
      continue;
    }
    inTable = true;
    final List<String> parts = line.split('|');
    if (parts.length < 3) {
      continue;
    }
    final List<String> cells = parts
        .sublist(1, parts.length - 1)
        .map((c) => c.trim())
        .toList();
    if (cells.isNotEmpty && cells.every((c) => RegExp(r'^-*$').hasMatch(c))) {
      continue; // separator
    }
    if (cells.isNotEmpty && cells.first == 'Date') {
      continue; // header
    }
    if (cells.length != 7) {
      throw FormatException(
        '[$id] Test History row must have 7 cells, got ${cells.length}: $line',
      );
    }
    if (!verifyResults.contains(cells[5])) {
      throw FormatException(
        "[$id] Test History result '${cells[5]}' is not one of "
        '$verifyResults',
      );
    }
    rows.add(
      TestRow(
        date: cells[0],
        flutter: cells[1],
        dart: cells[2],
        depsResolved: cells[3],
        platform: cells[4],
        result: cells[5],
        note: cells[6],
      ),
    );
  }
  return rows;
}

/// Inserts [row] right under the table separator (newest first). Creates the
/// whole section when missing — before `## AI Integration Prompt` if that
/// exists, else at the end of the body.
String appendTestRow(String body, TestRow row) {
  final List<String> lines = body.split('\n');
  final int at = lines.indexWhere((l) => l.trim() == historyHeading);
  if (at == -1) {
    final List<String> section = [
      historyHeading,
      '',
      historyTableHeader,
      historyTableSep,
      row.toLine(),
      '',
    ];
    final int aiAt = lines.indexWhere(
      (l) => l.trim() == '## AI Integration Prompt',
    );
    if (aiAt == -1) {
      return '${body.trimRight()}\n\n${section.join('\n')}';
    }
    lines.insertAll(aiAt, section);
    return lines.join('\n');
  }
  for (int i = at + 1; i < lines.length; i++) {
    final String line = lines[i].trim();
    if (line.startsWith('## ')) {
      break;
    }
    if (line.startsWith('|') &&
        line.replaceAll(RegExp(r'[|\-\s]'), '').isEmpty) {
      lines.insert(i + 1, row.toLine());
      return lines.join('\n');
    }
  }
  // Heading exists but no table under it — create one.
  lines.insertAll(at + 1, [
    '',
    historyTableHeader,
    historyTableSep,
    row.toLine(),
  ]);
  return lines.join('\n');
}

/// Highest Flutter version with a pass / pass_warning row.
String? latestKnownGood(List<TestRow> rows) {
  String? best;
  for (final TestRow r in rows) {
    if (r.result != 'pass' && r.result != 'pass_warning') {
      continue;
    }
    if (best == null || compareVersions(r.flutter, best) > 0) {
      best = r.flutter;
    }
  }
  return best;
}
