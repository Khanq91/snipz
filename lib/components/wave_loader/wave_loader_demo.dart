// Demo/usage example for WaveLoader. Exempt from portability rules; this is
// also the copy-paste usage reference.

import 'package:flutter/material.dart';
import 'package:snipz/core/component_demo.dart';

import 'wave_loader.dart';

final ComponentDemo waveLoaderDemo = ComponentDemo(
  id: 'wave_loader',
  builder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: WaveLoader()),
  ),
  thumbnailBuilder: (context) => const ColoredBox(
    color: Color(0xFF0E0E10),
    child: Center(child: WaveLoader(frozenAt: 0.36)),
  ),
);
