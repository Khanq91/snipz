import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'models.dart';

/// Per-frame shader factory of a §2.3 shader-contract paint, produced by
/// [CarrierShaderSpec.prepare]. [build] must be cheap and synchronous — the
/// carrier hosts call it every frame with the carrier bounds, the carrier's
/// detail [scale] (§9.1) and elapsed [time] in seconds.
class CarrierShaderHandle {
  const CarrierShaderHandle({required this.build, this.dispose});

  final ui.Shader Function(ui.Rect bounds, double scale, double time) build;

  /// Frees a reused [ui.FragmentShader], if any. Null for allocation-free
  /// shaders (ui.Gradient.*).
  final void Function()? dispose;
}

/// How the app obtains the Shader of a §2.3 shader-contract paint. [prepare]
/// runs once per stage mount and hosts the async part (e.g.
/// FragmentProgram.fromAsset); after that everything is synchronous.
class CarrierShaderSpec {
  const CarrierShaderSpec({required this.prepare, this.animated = true});

  final Future<CarrierShaderHandle> Function() prepare;

  /// False for genuinely static shaders — the host then skips its ticker.
  final bool animated;
}

/// Runtime demo entry for one component (spec §6). Registered in
/// lib/registry.dart by tools/new_component.dart. Metadata lives ONLY in the
/// component's README frontmatter — never here.
class ComponentDemo {
  const ComponentDemo({
    required this.id,
    required this.builder,
    this.thumbnailBuilder,
    this.carrierBuilders = const {},
    this.shader,
  });

  final String id;

  /// Default preview.
  final WidgetBuilder builder;

  /// Optional lighter build for the gallery grid (mobile perf, §8.3).
  final WidgetBuilder? thumbnailBuilder;

  /// Fallback for `kind: paint` components that cannot expose a Shader
  /// factory (§2.3). Shader-contract paints leave this empty — the app builds
  /// carriers itself via [shader].
  final Map<Carrier, WidgetBuilder> carrierBuilders;

  /// §2.3 shader contract hook. Non-null means the app can put this paint on
  /// ANY carrier (text included) with no hand-built combinators.
  final CarrierShaderSpec? shader;
}
