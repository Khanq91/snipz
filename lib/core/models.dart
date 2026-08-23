// Pure-data models mirroring the generated artifacts (assets/index.json and
// assets/sources/<id>.json). No Flutter imports — usable from plain Dart
// unit tests. Hand-written fromJson per spec §11 (no Freezed/codegen).

/// Component kind (spec §2).
enum Kind {
  paint('paint'),
  carrier('carrier'),
  effect('effect'),
  composite('composite');

  const Kind(this.wire);
  final String wire;

  static Kind fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown kind: '$value'"),
  );
}

/// How the paint is produced (spec §2.2).
enum PaintSource {
  shader('shader'),
  painter('painter'),
  widget('widget'),
  none('none');

  const PaintSource(this.wire);
  final String wire;

  static PaintSource fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown paint_source: '$value'"),
  );
}

/// Things that can receive a paint (spec §2.1).
enum Carrier {
  fullscreen('fullscreen'),
  card('card'),
  button('button'),
  text('text'),
  border('border'),
  icon('icon'),
  divider('divider');

  const Carrier(this.wire);
  final String wire;

  static Carrier fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown carrier: '$value'"),
  );
}

/// Reuse cost of a component (spec §3).
enum Portability {
  singleFile('single_file'),
  folder('folder'),
  folderWithAssets('folder_with_assets');

  const Portability(this.wire);
  final String wire;

  static Portability fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown portability: '$value'"),
  );
}

/// Result of the last verify run. `stale` is intentionally absent — the app
/// derives staleness from [ComponentMeta.lastVerified] at runtime
/// (spec decision #5).
enum ComponentStatus {
  verified('verified'),
  needsPatch('needs_patch'),
  broken('broken');

  const ComponentStatus(this.wire);
  final String wire;

  static ComponentStatus fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown status: '$value'"),
  );
}

/// Where the code came from (spec §0.3, decision #17).
enum Origin {
  original('original'),
  reimplemented('reimplemented'),
  adapted('adapted'),
  copied('copied');

  const Origin(this.wire);
  final String wire;

  static Origin fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown origin: '$value'"),
  );
}

/// Outcome of a single Test History row (spec §5.2).
enum VerifyResult {
  pass('pass'),
  passWarning('pass_warning'),
  needsPatch('needs_patch'),
  fail('fail');

  const VerifyResult(this.wire);
  final String wire;

  static VerifyResult fromWire(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => throw FormatException("Unknown result: '$value'"),
  );
}

/// One row of the append-only Test History table (spec §5.1 layer 3).
class TestRecord {
  const TestRecord({
    required this.date,
    required this.flutter,
    required this.dart,
    required this.depsResolved,
    required this.platform,
    required this.result,
    required this.note,
  });

  factory TestRecord.fromJson(Map<String, Object?> json) => TestRecord(
    date: json['date']! as String,
    flutter: json['flutter']! as String,
    dart: json['dart']! as String,
    depsResolved: json['deps_resolved']! as String,
    platform: json['platform']! as String,
    result: VerifyResult.fromWire(json['result']! as String),
    note: json['note']! as String,
  );

  final String date;
  final String flutter;
  final String dart;
  final String depsResolved;
  final String platform;
  final VerifyResult result;
  final String note;
}

/// Frontmatter of one component as stored in assets/index.json.
class ComponentMeta {
  const ComponentMeta({
    required this.id,
    required this.title,
    required this.kind,
    required this.tags,
    required this.paintSource,
    required this.carriersVerified,
    required this.carriersFailed,
    required this.scaleAware,
    required this.portability,
    required this.entry,
    required this.files,
    required this.vendoredFrom,
    required this.assetsRequired,
    required this.shadersRequired,
    required this.deps,
    required this.origin,
    required this.source,
    required this.author,
    required this.license,
    required this.created,
    required this.createdFlutter,
    required this.createdDart,
    required this.createdDeps,
    required this.platformsInitial,
    required this.version,
    required this.latestKnownGood,
    required this.lastVerified,
    required this.status,
    required this.preview,
    required this.testHistory,
  });

  factory ComponentMeta.fromJson(Map<String, Object?> json) => ComponentMeta(
    id: json['id']! as String,
    title: json['title']! as String,
    kind: Kind.fromWire(json['kind']! as String),
    tags: _stringList(json['tags']),
    paintSource: PaintSource.fromWire(json['paint_source']! as String),
    carriersVerified: _stringList(
      json['carriers_verified'],
    ).map(Carrier.fromWire).toList(),
    carriersFailed: _stringMap(
      json['carriers_failed'],
    ).map((k, v) => MapEntry(Carrier.fromWire(k), v)),
    scaleAware: json['scale_aware']! as bool,
    portability: Portability.fromWire(json['portability']! as String),
    entry: json['entry']! as String,
    files: _stringMap(json['files']),
    vendoredFrom: json['vendored_from'] as String?,
    assetsRequired: _stringList(json['assets_required']),
    shadersRequired: _stringList(json['shaders_required']),
    deps: _stringMap(json['deps']),
    origin: Origin.fromWire(json['origin']! as String),
    source: json['source'] as String?,
    author: json['author'] as String?,
    license: json['license'] as String?,
    created: json['created']! as String,
    createdFlutter: json['created_flutter']! as String,
    createdDart: json['created_dart']! as String,
    createdDeps: _stringMap(json['created_deps']),
    platformsInitial: _stringList(json['platforms_initial']),
    version: json['version']! as String,
    latestKnownGood: json['latest_known_good'] as String?,
    lastVerified: json['last_verified'] as String?,
    status: json['status'] == null
        ? null
        : ComponentStatus.fromWire(json['status']! as String),
    preview: json['preview'] as String?,
    testHistory: (json['test_history'] as List<Object?>? ?? [])
        .map((r) => TestRecord.fromJson(r! as Map<String, Object?>))
        .toList(),
  );

  final String id;
  final String title;
  final Kind kind;
  final List<String> tags;
  final PaintSource paintSource;
  final List<Carrier> carriersVerified;
  final Map<Carrier, String> carriersFailed;
  final bool scaleAware;
  final Portability portability;
  final String entry;

  /// File name -> role description. The set of names is verified against the
  /// real import graph by validate.dart (spec §3.2).
  final Map<String, String> files;
  final String? vendoredFrom;
  final List<String> assetsRequired;
  final List<String> shadersRequired;

  /// Current deps (mutable layer — decision #3). Name -> version range.
  final Map<String, String> deps;
  final Origin origin;
  final String? source;
  final String? author;
  final String? license;
  final String created;
  final String createdFlutter;
  final String createdDart;

  /// Immutable creation snapshot from pubspec.lock (decision #3).
  final Map<String, String> createdDeps;
  final List<String> platformsInitial;
  final String version;
  final String? latestKnownGood;
  final String? lastVerified;

  /// Null until the first verify.dart run.
  final ComponentStatus? status;
  final String? preview;
  final List<TestRecord> testHistory;

  int get fileCount => files.length;
}

/// How a component relates to the current work session, if at all.
enum SessionFlag { added, fixed }

/// The latest work batch ("đợt"), embedded from SESSION.yaml by
/// build_index.dart. Exactly one session exists at a time — no history —
/// and its badges live until the next batch replaces it.
class SessionInfo {
  SessionInfo({
    required this.id,
    required this.title,
    required this.date,
    required List<String> added,
    required List<String> fixed,
  })  : added = Set.unmodifiable(added),
        fixed = Set.unmodifiable(fixed);

  factory SessionInfo.fromJson(Map<String, Object?> json) => SessionInfo(
    id: json['id']! as String,
    title: json['title'] as String?,
    date: json['date']! as String,
    added: _stringList(json['added']),
    fixed: _stringList(json['fixed']),
  );

  final String id;
  final String? title;
  final String date;
  final Set<String> added;
  final Set<String> fixed;

  bool get isEmpty => added.isEmpty && fixed.isEmpty;

  bool contains(String componentId) =>
      added.contains(componentId) || fixed.contains(componentId);

  SessionFlag? flagOf(String componentId) => added.contains(componentId)
      ? SessionFlag.added
      : fixed.contains(componentId)
          ? SessionFlag.fixed
          : null;
}

/// Parsed assets/index.json.
class ComponentIndex {
  const ComponentIndex({
    required this.generatedAt,
    required this.generatedFlutter,
    required this.generatedDart,
    required this.remoteUrl,
    required this.session,
    required this.components,
  });

  factory ComponentIndex.fromJson(Map<String, Object?> json) => ComponentIndex(
    generatedAt: json['_generated_at']! as String,
    generatedFlutter: json['_generated_flutter']! as String,
    generatedDart: json['_generated_dart']! as String,
    remoteUrl: json['_generated_remote'] as String?,
    session: json['session'] == null
        ? null
        : SessionInfo.fromJson(json['session']! as Map<String, Object?>),
    components: (json['components']! as List<Object?>)
        .map((c) => ComponentMeta.fromJson(c! as Map<String, Object?>))
        .toList(),
  );

  final String generatedAt;

  /// Flutter version of the machine that built the index — the default
  /// "target Flutter version" in settings (decision #2).
  final String generatedFlutter;
  final String generatedDart;

  /// https URL of the repo's `origin`, stamped by build_index.dart — used by
  /// the share sheet to link GitHub (§8.6). Null when the repo has no remote.
  final String? remoteUrl;

  /// Current work-batch flag, or null when SESSION.yaml is absent.
  final SessionInfo? session;
  final List<ComponentMeta> components;
}

/// Parsed `assets/sources/<id>.json` — loaded lazily on detail open (§5.0).
class ComponentSources {
  const ComponentSources({
    required this.id,
    required this.readmeBody,
    required this.files,
  });

  factory ComponentSources.fromJson(Map<String, Object?> json) =>
      ComponentSources(
        id: json['id']! as String,
        readmeBody: json['readme_body']! as String,
        files: _stringMap(json['files']),
      );

  final String id;
  final String readmeBody;

  /// File name -> full source text.
  final Map<String, String> files;
}

List<String> _stringList(Object? node) =>
    (node as List<Object?>? ?? []).map((e) => e! as String).toList();

Map<String, String> _stringMap(Object? node) =>
    (node as Map<String, Object?>? ?? {}).map(
      (k, v) => MapEntry(k, v! as String),
    );
