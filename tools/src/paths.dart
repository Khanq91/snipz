// Repo-root anchored paths shared by all tools.

import 'dart:io';

const String componentsDir = 'lib/components';
const String indexPath = 'assets/index.json';
const String sourcesDir = 'assets/sources';
const String registryPath = 'lib/registry.dart';
const String pubspecPath = 'pubspec.yaml';
const String pubspecLockPath = 'pubspec.lock';

/// All tools must run from the repo root (CI does). Fails fast otherwise.
void requireRepoRoot() {
  if (!File(pubspecPath).existsSync()) {
    stderr.writeln(
      'Run from the repo root — pubspec.yaml not found in '
      '${Directory.current.path}',
    );
    exit(2);
  }
}

String idOfFolder(Directory dir) => dir.path.split(RegExp(r'[\\/]')).last;

/// Component folders under lib/components/, sorted for determinism.
List<Directory> componentFolders() {
  final Directory root = Directory(componentsDir);
  if (!root.existsSync()) {
    return [];
  }
  return root.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Names of the .dart files directly inside [folder], sorted.
List<String> dartFileNames(Directory folder) =>
    folder
        .listSync()
        .whereType<File>()
        .map((f) => f.path.split(RegExp(r'[\\/]')).last)
        .where((n) => n.endsWith('.dart'))
        .toList()
      ..sort();
