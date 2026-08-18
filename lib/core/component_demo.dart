import 'package:flutter/widgets.dart';

import 'models.dart';

/// Runtime demo entry for one component (spec §6). Registered in
/// lib/registry.dart by tools/new_component.dart. Metadata lives ONLY in the
/// component's README frontmatter — never here.
class ComponentDemo {
  const ComponentDemo({
    required this.id,
    required this.builder,
    this.thumbnailBuilder,
    this.carrierBuilders = const {},
  });

  final String id;

  /// Default preview.
  final WidgetBuilder builder;

  /// Optional lighter build for the gallery grid (mobile perf, §8.3).
  final WidgetBuilder? thumbnailBuilder;

  /// Fallback for `kind: paint` components that cannot expose a Shader
  /// factory (§2.3). Shader-contract paints leave this empty — the app builds
  /// carriers itself via ShaderMask (Phase 3).
  final Map<Carrier, WidgetBuilder> carrierBuilders;
}
