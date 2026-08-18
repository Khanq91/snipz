import 'package:flutter/material.dart';

/// Single theme builder for both app-level light/dark and the detail
/// preview-stage toggle (§8.5), so the stage matches the real app themes.
ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C4DFF),
    brightness: brightness,
  ),
);
