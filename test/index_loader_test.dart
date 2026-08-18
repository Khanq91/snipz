// §0.4c: the reader is injected, so this test counts asset reads directly —
// startup must cost exactly ONE read (assets/index.json); sources load
// lazily and cache per id.

import 'package:flutter_test/flutter_test.dart';
import 'package:snipz/core/index_loader.dart';
import 'package:snipz/core/models.dart';

const String _indexJson = '''
{
  "_generated": true,
  "_generated_at": "2026-08-18T00:00:00Z",
  "_generated_flutter": "3.44.5",
  "_generated_dart": "3.12.2",
  "components": [
    {
      "id": "demo_x",
      "title": "Demo X",
      "kind": "paint",
      "tags": ["a", "b"],
      "paint_source": "shader",
      "carriers_verified": ["fullscreen", "card"],
      "carriers_failed": {"icon": "too small"},
      "scale_aware": true,
      "portability": "folder",
      "entry": "demo_x.dart",
      "files": {"demo_x.dart": "entry", "_part.dart": "helper"},
      "vendored_from": null,
      "assets_required": [],
      "shaders_required": [],
      "deps": {"blur": "^4.0.1"},
      "origin": "reimplemented",
      "source": null,
      "author": "Khang",
      "license": null,
      "created": "2026-08-18",
      "created_flutter": "3.44.5",
      "created_dart": "3.12.2",
      "created_deps": {"blur": "4.0.1"},
      "platforms_initial": ["android"],
      "version": "1.1.0",
      "latest_known_good": "3.44.5",
      "last_verified": "2026-08-18",
      "status": "verified",
      "preview": null,
      "file_count": 2,
      "test_history": [
        {
          "date": "2026-08-18",
          "flutter": "3.44.5",
          "dart": "3.12.2",
          "deps_resolved": "blur 4.0.1",
          "platform": "android",
          "result": "pass",
          "note": "—"
        }
      ]
    }
  ]
}
''';

const String _sourcesJson = '''
{
  "_generated": true,
  "id": "demo_x",
  "readme_body": "# Demo X",
  "files": {"demo_x.dart": "// source"}
}
''';

void main() {
  test('startup reads exactly one asset, repeated calls stay cached', () async {
    final List<String> reads = [];
    final IndexLoader loader = IndexLoader((path) async {
      reads.add(path);
      return _indexJson;
    });

    final ComponentIndex index = await loader.loadIndex();
    await loader.loadIndex();

    expect(reads, ['assets/index.json']);
    expect(index.generatedFlutter, '3.44.5');
    expect(index.components, hasLength(1));
  });

  test('models parse the full meta shape', () async {
    final IndexLoader loader = IndexLoader((path) async => _indexJson);
    final ComponentMeta meta = (await loader.loadIndex()).components.single;

    expect(meta.id, 'demo_x');
    expect(meta.kind, Kind.paint);
    expect(meta.paintSource, PaintSource.shader);
    expect(meta.carriersVerified, [Carrier.fullscreen, Carrier.card]);
    expect(meta.carriersFailed[Carrier.icon], 'too small');
    expect(meta.portability, Portability.folder);
    expect(meta.deps, {'blur': '^4.0.1'});
    expect(meta.origin, Origin.reimplemented);
    expect(meta.status, ComponentStatus.verified);
    expect(meta.fileCount, 2);
    expect(meta.testHistory.single.result, VerifyResult.pass);
  });

  test('null status (never verified) is allowed', () async {
    final String withNullStatus = _indexJson
        .replaceAll('"status": "verified"', '"status": null')
        .replaceAll(
          '"latest_known_good": "3.44.5"',
          '"latest_known_good": null',
        );
    final IndexLoader loader = IndexLoader((path) async => withNullStatus);
    final ComponentMeta meta = (await loader.loadIndex()).components.single;

    expect(meta.status, isNull);
    expect(meta.latestKnownGood, isNull);
  });

  test('sources load lazily and cache per id', () async {
    final List<String> reads = [];
    final IndexLoader loader = IndexLoader((path) async {
      reads.add(path);
      return path.contains('sources') ? _sourcesJson : _indexJson;
    });

    final ComponentSources sources = await loader.loadSources('demo_x');
    await loader.loadSources('demo_x');

    expect(reads, ['assets/sources/demo_x.json']);
    expect(sources.readmeBody, '# Demo X');
    expect(sources.files['demo_x.dart'], '// source');
  });
}
