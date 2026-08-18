// dart tools/new_component.dart <id> <kind> [--files=n]
//
// Scaffolds a component folder (entry, demo, README with pre-filled
// frontmatter — versions machine-read, never typed), registers it in
// lib/registry.dart and regenerates the artifacts (§10).
// --files=n creates the entry plus (n-1) _partN.dart placeholders
// (decision #15), already exported from the entry so the import-graph and
// orphan checks pass out of the box.

import 'dart:io';

import 'src/build_index_lib.dart';
import 'src/flutter_env.dart';
import 'src/paths.dart';
import 'src/registry_edit.dart';
import 'src/schema.dart';

Future<void> main(List<String> args) async {
  requireRepoRoot();
  final List<String> positional = args
      .where((a) => !a.startsWith('--'))
      .toList();
  if (positional.length != 2) {
    stderr.writeln(
      'usage: dart tools/new_component.dart <id> <kind> [--files=n]',
    );
    exitCode = 2;
    return;
  }
  final String id = positional[0];
  final String kind = positional[1];
  int fileCount = 1;
  for (final String a in args) {
    if (a.startsWith('--files=')) {
      fileCount = int.tryParse(a.substring(8)) ?? 0;
    }
  }
  if (!idRe.hasMatch(id)) {
    stderr.writeln("id '$id' must be snake_case ([a-z][a-z0-9_]*)");
    exitCode = 2;
    return;
  }
  if (!kinds.contains(kind)) {
    stderr.writeln("kind '$kind' must be one of $kinds");
    exitCode = 2;
    return;
  }
  if (fileCount < 1) {
    stderr.writeln('--files must be >= 1');
    exitCode = 2;
    return;
  }
  final Directory folder = Directory('$componentsDir/$id');
  if (folder.existsSync()) {
    stderr.writeln('${folder.path} already exists');
    exitCode = 2;
    return;
  }

  final FlutterEnv env = await readFlutterEnv();
  final String pascal = _pascal(id);
  final String camel = pascal[0].toLowerCase() + pascal.substring(1);
  final List<String> parts = [
    for (int i = 1; i < fileCount; i++) '_part$i.dart',
  ];

  folder.createSync(recursive: true);
  File('${folder.path}/$id.dart').writeAsStringSync(
    _entryTemplate(id: id, pascal: pascal, parts: parts, env: env),
  );
  for (int i = 0; i < parts.length; i++) {
    File(
      '${folder.path}/${parts[i]}',
    ).writeAsStringSync(_partTemplate(pascal: pascal, index: i + 1));
  }
  File(
    '${folder.path}/${id}_demo.dart',
  ).writeAsStringSync(_demoTemplate(id: id, pascal: pascal, camel: camel));
  File('${folder.path}/README.md').writeAsStringSync(
    _readmeTemplate(id: id, pascal: pascal, kind: kind, parts: parts, env: env),
  );

  final File registry = File(registryPath);
  registry.writeAsStringSync(
    insertIntoRegistry(registry.readAsStringSync(), id, '${camel}Demo'),
  );

  writeArtifacts(env);

  stdout.writeln(
    'created ${folder.path}/ (${parts.length + 2} dart files + README)',
  );
  stdout.writeln('registered in $registryPath and regenerated artifacts');
  stdout.writeln('next: implement the component, then run:');
  stdout.writeln('  dart tools/validate.dart');
  stdout.writeln(
    '  dart tools/verify.dart $id <pass|pass_warning|needs_patch|fail> --note "..."',
  );
}

String _pascal(String id) => id
    .split('_')
    .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
    .join();

String _entryTemplate({
  required String id,
  required String pascal,
  required List<String> parts,
  required FlutterEnv env,
}) {
  final String exports = parts.isEmpty
      ? ''
      : '\n${parts.map((p) => "export '$p';").join('\n')}\n';
  return '''
/// $pascal
/// Origin: original — written for the Snipz vault
/// Deps: flutter only
/// Flutter: ${env.flutter}
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'package:flutter/material.dart';
$exports
/// TODO: describe what $pascal is.
class $pascal extends StatelessWidget {
  const $pascal({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
''';
}

String _partTemplate({required String pascal, required int index}) =>
    '''
// Support file for $pascal — TODO: implement (or delete and run
// dart tools/validate.dart --fix to shrink the files: block).

/// TODO: real content. Placeholder so the export from the entry resolves.
class ${pascal}Part$index {
  const ${pascal}Part$index();
}
''';

String _demoTemplate({
  required String id,
  required String pascal,
  required String camel,
}) =>
    '''
// Demo/usage example for $pascal. Exempt from portability rules (§3.1.9);
// also serves as the copy-paste usage reference (§6).

import 'package:snipz/core/component_demo.dart';

import '$id.dart';

final ComponentDemo ${camel}Demo = ComponentDemo(
  id: '$id',
  builder: (context) => const $pascal(),
);
''';

String _readmeTemplate({
  required String id,
  required String pascal,
  required String kind,
  required List<String> parts,
  required FlutterEnv env,
}) {
  final String title = _pascal(
    id,
  ).replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}').trim();
  final String filesBlock = [
    '  - $id.dart: "entry, public API"',
    for (final String p in parts) '  - $p: "required by $id.dart"',
  ].join('\n');
  final String paintSource = kind == 'paint' ? 'widget' : 'none';
  final String portability = parts.isEmpty ? 'single_file' : 'folder';
  final String paintNote = kind == 'paint'
      ? '\n> TODO (kind: paint): add a `scale` param (§9.1, detail density — '
            'then set `scale_aware: true`), and if the paint can be a Shader, '
            'expose `Shader create${pascal}Shader(Rect bounds, {...})` (§2.3).\n'
      : '';
  return '''
---
# --- IDENTITY ---
id: $id
title: $title
kind: $kind
tags: []

# --- TAXONOMY (§2) ---
paint_source: $paintSource
carriers_verified: []
carriers_failed: []
scale_aware: false

# --- PORTABILITY (§3 — files block is script-written, do not hand-edit) ---
portability: $portability
entry: $id.dart
files:
$filesBlock
vendored_from: null
assets_required: []
shaders_required: []

# --- CURRENT DEPS (mutable — validate checks THIS) ---
deps: []

# --- ORIGIN (§0.3) ---
origin: original
source: null
author: "Khang"
license: null

# --- CREATION SNAPSHOT (immutable, archaeology only) ---
created: ${today()}
created_flutter: ${env.flutter}
created_dart: ${env.dart}
created_deps: []
platforms_initial: [android]

# --- COMPONENT VERSION ---
version: 1.0.0

# --- DERIVED (computed from Test History by verify.dart, do not hand-edit) ---
latest_known_good: null
last_verified: null
status: null

preview: null
---

# $title

TODO: 2-3 lines — what it is, when to use it, what it looks like.
$paintNote
## Install

```yaml
# no external dependencies — Flutter SDK only
```

## Reuse

- **Copy:** the whole `$id/` folder (${parts.length + 1} dart file(s), see `files`)
- **Import:** `import '$id/$id.dart';` — one line
- **Or:** `dart tools/export.dart $id` → zip + paste-ready block

## API

| Param | Type | Default | Meaning |
|---|---|---|---|

## Caveats

- TODO

## Changelog

- **1.0.0** (${today()}) — created

## Test History

| Date | Flutter | Dart | Deps resolved | Platform | Result | Note |
|---|---|---|---|---|---|---|

## AI Integration Prompt

Tích hợp component `$pascal` vào project này.

**Context**
- Chức năng: <1-2 dòng>
- Public API: xem bảng API trong README.
- Portability: $portability — copy cả `$id/` (${parts.length + 1} file), import duy nhất `$id.dart`.
- Deps: không có — Flutter SDK only.

**Việc cần làm**
1. Copy folder `$id/` vào <thư mục widget của project đích>.
2. Import entry file, wire vào widget tree tại <chỗ tôi chỉ định>.

**Việc cần adapt theo project đích**
- Color/theme token: đổi default param sang token của project.
- State management: nối callback vào state layer của project.

**Rào (constraints)**
- KHÔNG sửa logic bên trong. Chỉ đổi styling qua constructor params.
- KHÔNG tách entry file ra nhiều file. KHÔNG gộp các file `_*.dart` lại.
- Deps xung đột version với project → BÁO LẠI, đừng tự downgrade.
- Flutter version của project thấp hơn `latest_known_good` → đọc Test History trước.
''';
}
