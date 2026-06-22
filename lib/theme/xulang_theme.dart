import 'package:flutter/material.dart';

abstract final class XulangColors {
  static const ink = Color(0xFF090A0B);
  static const surface = Color(0xFF151617);
  static const elevated = Color(0xFF202123);
  static const paper = Color(0xFFE8E0D3);
  static const muted = Color(0xFF9A968F);
  static const accent = Color(0xFFD2B48C);
  static const line = Color(0xFF3B3B3B);
}

ThemeData buildXulangTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: XulangColors.accent,
    brightness: Brightness.dark,
    surface: XulangColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: XulangColors.ink,
    fontFamilyFallback: const ['Noto Sans CJK SC', 'Noto Sans SC'],
    dividerColor: XulangColors.line,
    dialogTheme: const DialogThemeData(
      backgroundColor: XulangColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: XulangColors.paper,
        foregroundColor: XulangColors.ink,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: XulangColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
