// Machine-read versions. Hard rule (§10): NEVER hand-typed — verify.dart and
// new_component.dart snapshot `flutter --version` and pubspec.lock.

import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'paths.dart';

class FlutterEnv {
  const FlutterEnv({required this.flutter, required this.dart});

  final String flutter;
  final String dart;
}

Future<FlutterEnv> readFlutterEnv() async {
  final ProcessResult r = await Process.run('flutter', [
    '--version',
    '--machine',
  ], runInShell: true);
  if (r.exitCode != 0) {
    stderr.writeln('flutter --version --machine failed:\n${r.stderr}');
    exit(2);
  }
  final String out = r.stdout as String;
  final int brace = out.indexOf('{'); // tolerate upgrade-notice noise
  final Map<String, Object?> json =
      jsonDecode(out.substring(brace)) as Map<String, Object?>;
  return FlutterEnv(
    flutter: json['frameworkVersion']! as String,
    dart: (json['dartSdkVersion']! as String).split(' ').first,
  );
}

/// Resolved versions from pubspec.lock — the truth about what actually runs
/// (§10: pubspec.yaml holds ranges, not facts).
Map<String, String> lockedDepVersions() {
  final File lock = File(pubspecLockPath);
  if (!lock.existsSync()) {
    return {};
  }
  final Object? doc = loadYaml(lock.readAsStringSync());
  if (doc is! YamlMap) {
    return {};
  }
  final Object? packages = doc['packages'];
  if (packages is! YamlMap) {
    return {};
  }
  final Map<String, String> out = {};
  for (final MapEntry<Object?, Object?> e in packages.entries) {
    final Object? info = e.value;
    if (info is YamlMap) {
      out['${e.key}'] = '${info['version']}';
    }
  }
  return out;
}

/// Numeric compare of dotted versions ("3.44.5"); missing parts are 0,
/// non-numeric suffixes ignored.
int compareVersions(String a, String b) {
  List<int> nums(String v) {
    final List<int> n = RegExp(
      r'\d+',
    ).allMatches(v).take(3).map((m) => int.parse(m.group(0)!)).toList();
    while (n.length < 3) {
      n.add(0);
    }
    return n;
  }

  final List<int> na = nums(a);
  final List<int> nb = nums(b);
  for (int i = 0; i < 3; i++) {
    if (na[i] != nb[i]) {
      return na[i].compareTo(nb[i]);
    }
  }
  return 0;
}

String today() {
  final DateTime now = DateTime.now();
  final String m = now.month.toString().padLeft(2, '0');
  final String d = now.day.toString().padLeft(2, '0');
  return '${now.year}-$m-$d';
}
