// Manual barrel mapping component id -> demo (spec §8.1 — no reflection, no
// codegen). Maintained by tools/new_component.dart, which inserts the import
// and the map entry in alphabetical order. Keep it sorted by id.

import 'package:snipz/components/animated_content/animated_content_demo.dart';
import 'package:snipz/components/aurora_stack/aurora_stack_demo.dart';
import 'package:snipz/components/bloub_bot/bloub_bot_demo.dart';
import 'package:snipz/components/blur_text/blur_text_demo.dart';
import 'package:snipz/components/bounce_cards/bounce_cards_demo.dart';
import 'package:snipz/components/dither/dither_demo.dart';
import 'package:snipz/components/dock/dock_demo.dart';
import 'package:snipz/components/elastic_slider/elastic_slider_demo.dart';
import 'package:snipz/components/faulty_terminal/faulty_terminal_demo.dart';
import 'package:snipz/components/fluid_glass/fluid_glass_demo.dart';
import 'package:snipz/components/glass_card/glass_card_demo.dart';
import 'package:snipz/components/gradient_text/gradient_text_demo.dart';
import 'package:snipz/components/gradient_waves/gradient_waves_demo.dart';
import 'package:snipz/components/gradual_blur/gradual_blur_demo.dart';
import 'package:snipz/components/infinite_menu/infinite_menu_demo.dart';
import 'package:snipz/components/jelly_blob/jelly_blob_demo.dart';
import 'package:snipz/components/morph_slider/morph_slider_demo.dart';
import 'package:snipz/components/option_wheel/option_wheel_demo.dart';
import 'package:snipz/components/particle_field/particle_field_demo.dart';
import 'package:snipz/components/pixel_blast/pixel_blast_demo.dart';
import 'package:snipz/components/pixel_card/pixel_card_demo.dart';
import 'package:snipz/components/pixel_loader/pixel_loader_demo.dart';
import 'package:snipz/components/pixel_transition/pixel_transition_demo.dart';
import 'package:snipz/components/pixel_walker/pixel_walker_demo.dart';
import 'package:snipz/components/pull_reveal_refresh/pull_reveal_refresh_demo.dart';
import 'package:snipz/components/reveal_list/reveal_list_demo.dart';
import 'package:snipz/components/scroll_expand/scroll_expand_demo.dart';
import 'package:snipz/components/shape_morph/shape_morph_demo.dart';
import 'package:snipz/components/spectrum_sweep/spectrum_sweep_demo.dart';
import 'package:snipz/components/split_flap_text/split_flap_text_demo.dart';
import 'package:snipz/components/star_border/star_border_demo.dart';
import 'package:snipz/components/stepper/stepper_demo.dart';
import 'package:snipz/components/text_type/text_type_demo.dart';
import 'package:snipz/components/true_focus/true_focus_demo.dart';
import 'package:snipz/core/component_demo.dart';

final Map<String, ComponentDemo> componentRegistry = <String, ComponentDemo>{
  'animated_content': animatedContentDemo,
  'aurora_stack': auroraStackDemo,
  'bloub_bot': bloubBotDemo,
  'blur_text': blurTextDemo,
  'bounce_cards': bounceCardsDemo,
  'dither': ditherDemo,
  'dock': dockDemo,
  'elastic_slider': elasticSliderDemo,
  'faulty_terminal': faultyTerminalDemo,
  'fluid_glass': fluidGlassDemo,
  'glass_card': glassCardDemo,
  'gradient_text': gradientTextDemo,
  'gradient_waves': gradientWavesDemo,
  'gradual_blur': gradualBlurDemo,
  'infinite_menu': infiniteMenuDemo,
  'jelly_blob': jellyBlobDemo,
  'morph_slider': morphSliderDemo,
  'option_wheel': optionWheelDemo,
  'particle_field': particleFieldDemo,
  'pixel_blast': pixelBlastDemo,
  'pixel_card': pixelCardDemo,
  'pixel_loader': pixelLoaderDemo,
  'pixel_transition': pixelTransitionDemo,
  'pixel_walker': pixelWalkerDemo,
  'pull_reveal_refresh': pullRevealRefreshDemo,
  'reveal_list': revealListDemo,
  'scroll_expand': scrollExpandDemo,
  'shape_morph': shapeMorphDemo,
  'spectrum_sweep': spectrumSweepDemo,
  'split_flap_text': splitFlapTextDemo,
  'star_border': starBorderDemo,
  'stepper': stepperDemo,
  'text_type': textTypeDemo,
  'true_focus': trueFocusDemo,
};
