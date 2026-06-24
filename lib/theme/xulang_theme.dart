import 'package:flutter/material.dart';

abstract final class XulangColors {
  static const ink = Color(0xFF0A0B0C);
  static const surface = Color(0xFF131415);
  static const elevated = Color(0xFF1E1F20);
  static const paper = Color(0xFFE8DFCE);
  static const muted = Color(0xFF8C8478);
  static const accent = Color(0xFFC9A87C);
  static const line = Color(0xFF2A2A2B);
  static const highlight = Color(0xFFF2E9D8);
  static const danger = Color(0xFFB85C5C);
}

ThemeData buildXulangTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: XulangColors.accent,
    brightness: Brightness.dark,
    surface: XulangColors.surface,
    primary: XulangColors.accent,
    onPrimary: XulangColors.ink,
    secondary: XulangColors.paper,
    onSecondary: XulangColors.ink,
    surfaceContainerHighest: XulangColors.elevated,
    outline: XulangColors.line,
    error: XulangColors.danger,
  );

  const serifFamily = 'Noto Serif SC';
  const sansFamily = 'Noto Sans SC';
  const fallbackFamilies = [serifFamily, sansFamily, 'PingFang SC', 'Microsoft YaHei'];

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: XulangColors.ink,
    fontFamily: sansFamily,
    fontFamilyFallback: const [...fallbackFamilies, 'sans-serif'],
    dividerColor: XulangColors.line,
    dividerTheme: const DividerThemeData(
      color: XulangColors.line,
      thickness: 0.5,
      space: 1,
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: XulangColors.paper,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        color: XulangColors.paper,
        height: 1.25,
      ),
      displaySmall: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        color: XulangColors.paper,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        color: XulangColors.paper,
        height: 1.35,
      ),
      headlineSmall: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
        color: XulangColors.paper,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: XulangColors.paper,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: XulangColors.paper,
        height: 1.45,
      ),
      titleSmall: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: XulangColors.muted,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: XulangColors.paper,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: XulangColors.paper,
        height: 1.6,
      ),
      bodySmall: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.05,
        color: XulangColors.muted,
        height: 1.55,
      ),
      labelLarge: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: XulangColors.paper,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: XulangColors.muted,
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: XulangColors.muted,
        height: 1.4,
      ),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: XulangColors.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        color: XulangColors.paper,
      ),
    ),

    // Cards - the "mounted print" aesthetic
    cardTheme: CardThemeData(
      color: XulangColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: XulangColors.line, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),

    // Chips - refined gallery tags
    chipTheme: ChipThemeData(
      backgroundColor: XulangColors.elevated,
      selectedColor: XulangColors.accent.withValues(alpha: .18),
      disabledColor: XulangColors.elevated.withValues(alpha: .5),
      labelStyle: const TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: XulangColors.paper,
        letterSpacing: 0.2,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: XulangColors.accent,
        letterSpacing: 0.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: XulangColors.line, width: 0.5),
      ),
      showCheckmark: false,
      side: const BorderSide(color: XulangColors.line, width: 0.5),
      iconTheme: const IconThemeData(color: XulangColors.muted, size: 16),
    ),

    // Icon buttons
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: XulangColors.paper,
        backgroundColor: Colors.transparent,
        hoverColor: XulangColors.paper.withValues(alpha: .06),
        highlightColor: XulangColors.paper.withValues(alpha: .10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    // Filled buttons - warm paper on dark
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: XulangColors.paper,
        foregroundColor: XulangColors.ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: sansFamily,
          fontFamilyFallback: fallbackFamilies,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: XulangColors.paper,
        side: const BorderSide(color: XulangColors.line, width: 0.5),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: sansFamily,
          fontFamilyFallback: fallbackFamilies,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: XulangColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: sansFamily,
          fontFamilyFallback: fallbackFamilies,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: XulangColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: XulangColors.muted,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: XulangColors.line, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: XulangColors.accent, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: XulangColors.danger, width: 1),
      ),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: XulangColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: XulangColors.line, width: 0.5),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: serifFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        color: XulangColors.paper,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 14,
        color: XulangColors.paper,
        height: 1.6,
      ),
    ),

    // Bottom sheets
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: XulangColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      dragHandleColor: XulangColors.muted,
      dragHandleSize: Size(40, 4),
    ),

    // Snack bars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: XulangColors.elevated,
      contentTextStyle: const TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 13,
        color: XulangColors.paper,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: XulangColors.line, width: 0.5),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // Sliders
    sliderTheme: SliderThemeData(
      activeTrackColor: XulangColors.accent,
      inactiveTrackColor: XulangColors.line,
      thumbColor: XulangColors.paper,
      overlayColor: XulangColors.accent.withValues(alpha: .12),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, elevation: 2),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),

    // Switches
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return XulangColors.accent;
        return XulangColors.muted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return XulangColors.accent.withValues(alpha: .35);
        }
        return XulangColors.line;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // List tiles
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 36,
      iconColor: XulangColors.muted,
      textColor: XulangColors.paper,
      titleTextStyle: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: XulangColors.paper,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 12,
        color: XulangColors.muted,
        height: 1.5,
      ),
    ),

    // Popup menus
    popupMenuTheme: PopupMenuThemeData(
      color: XulangColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: XulangColors.line, width: 0.5),
      ),
      textStyle: const TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 13,
        color: XulangColors.paper,
      ),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(
        fontFamily: sansFamily,
        fontFamilyFallback: fallbackFamilies,
        fontSize: 13,
        color: XulangColors.paper,
      )),
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _XulangPageTransitionsBuilder(),
        TargetPlatform.iOS: _XulangPageTransitionsBuilder(),
        TargetPlatform.windows: _XulangPageTransitionsBuilder(),
        TargetPlatform.macOS: _XulangPageTransitionsBuilder(),
        TargetPlatform.linux: _XulangPageTransitionsBuilder(),
        TargetPlatform.fuchsia: _XulangPageTransitionsBuilder(),
      },
    ),
  );
}

/// A gallery-like page transition: a subtle fade with a gentle upward drift.
class _XulangPageTransitionsBuilder extends PageTransitionsBuilder {
  const _XulangPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = Tween<double>(begin: 0, end: 1).animate(curve);
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(curve);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
