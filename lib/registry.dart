// Manual barrel mapping component id -> demo (spec §8.1 — no reflection, no
// codegen). Maintained by tools/new_component.dart, which inserts the import
// and the map entry in alphabetical order. Keep it sorted by id.

import 'package:snipz/components/aurora_stack/aurora_stack_demo.dart';
import 'package:snipz/components/blur_text/blur_text_demo.dart';
import 'package:snipz/components/dither/dither_demo.dart';
import 'package:snipz/components/elastic_slider/elastic_slider_demo.dart';
import 'package:snipz/components/glass_card/glass_card_demo.dart';
import 'package:snipz/components/gradient_text/gradient_text_demo.dart';
import 'package:snipz/components/gradient_waves/gradient_waves_demo.dart';
import 'package:snipz/components/particle_field/particle_field_demo.dart';
import 'package:snipz/components/pixel_blast/pixel_blast_demo.dart';
import 'package:snipz/components/pixel_transition/pixel_transition_demo.dart';
import 'package:snipz/components/reveal_list/reveal_list_demo.dart';
import 'package:snipz/components/spectrum_sweep/spectrum_sweep_demo.dart';
import 'package:snipz/components/text_type/text_type_demo.dart';
import 'package:snipz/core/component_demo.dart';

final Map<String, ComponentDemo> componentRegistry = <String, ComponentDemo>{
  'aurora_stack': auroraStackDemo,
  'blur_text': blurTextDemo,
  'dither': ditherDemo,
  'elastic_slider': elasticSliderDemo,
  'glass_card': glassCardDemo,
  'gradient_text': gradientTextDemo,
  'gradient_waves': gradientWavesDemo,
  'particle_field': particleFieldDemo,
  'pixel_blast': pixelBlastDemo,
  'pixel_transition': pixelTransitionDemo,
  'reveal_list': revealListDemo,
  'spectrum_sweep': spectrumSweepDemo,
  'text_type': textTypeDemo,
};
