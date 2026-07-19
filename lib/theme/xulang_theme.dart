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

class XulangPalette extends ThemeExtension<XulangPalette> {
  const XulangPalette({
    required this.ink,
    required this.surface,
    required this.elevated,
    required this.paper,
    required this.muted,
    required this.accent,
    required this.line,
    required this.highlight,
    required this.danger,
  });

  final Color ink;
  final Color surface;
  final Color elevated;
  final Color paper;
  final Color muted;
  final Color accent;
  final Color line;
  final Color highlight;
  final Color danger;

  static XulangPalette of(BuildContext context) {
    return Theme.of(context).extension<XulangPalette>() ?? dark;
  }

  static const dark = XulangPalette(
    ink: XulangColors.ink,
    surface: XulangColors.surface,
    elevated: XulangColors.elevated,
    paper: XulangColors.paper,
    muted: XulangColors.muted,
    accent: XulangColors.accent,
    line: XulangColors.line,
    highlight: XulangColors.highlight,
    danger: XulangColors.danger,
  );

  static const light = XulangPalette(
    ink: Color(0xFFF6F0E4),
    surface: Color(0xFFFFFBF2),
    elevated: Color(0xFFF0E6D5),
    paper: Color(0xFF1B1712),
    muted: Color(0xFF766B5E),
    accent: Color(0xFF9D7444),
    line: Color(0xFFD8CDBB),
    highlight: Color(0xFF2A2117),
    danger: Color(0xFFB85C5C),
  );

  @override
  ThemeExtension<XulangPalette> copyWith({
    Color? ink,
    Color? surface,
    Color? elevated,
    Color? paper,
    Color? muted,
    Color? accent,
    Color? line,
    Color? highlight,
    Color? danger,
  }) {
    return XulangPalette(
      ink: ink ?? this.ink,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      paper: paper ?? this.paper,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      line: line ?? this.line,
      highlight: highlight ?? this.highlight,
      danger: danger ?? this.danger,
    );
  }

  @override
  ThemeExtension<XulangPalette> lerp(
    covariant ThemeExtension<XulangPalette>? other,
    double t,
  ) {
    if (other is! XulangPalette) return this;
    return XulangPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      line: Color.lerp(line, other.line, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

ThemeData buildXulangTheme({Brightness brightness = Brightness.dark}) {
  final palette = brightness == Brightness.dark
      ? XulangPalette.dark
      : XulangPalette.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.accent,
    brightness: brightness,
    surface: palette.surface,
    primary: palette.accent,
    onPrimary: palette.ink,
    secondary: palette.paper,
    onSecondary: palette.ink,
    surfaceContainerHighest: palette.elevated,
    outline: palette.line,
    error: palette.danger,
  );

  const serifFamily = 'Noto Serif SC';
  const sansFamily = 'Noto Sans SC';
  const fallbackFamilies = [
    serifFamily,
    sansFamily,
    'PingFang SC',
    'Microsoft YaHei',
  ];

  TextStyle textStyle(
    double size, {
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
    Color? color,
    String fontFamily = sansFamily,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFamilies,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color ?? palette.paper,
      height: height,
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [palette],
    scaffoldBackgroundColor: palette.ink,
    fontFamily: sansFamily,
    fontFamilyFallback: const [...fallbackFamilies, 'sans-serif'],
    dividerColor: palette.line,
    dividerTheme: DividerThemeData(
      color: palette.line,
      thickness: 0.5,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: textStyle(
        34,
        fontFamily: serifFamily,
        letterSpacing: 3,
        height: 1.2,
      ),
      displayMedium: textStyle(
        28,
        fontFamily: serifFamily,
        letterSpacing: 2,
        height: 1.25,
      ),
      displaySmall: textStyle(
        22,
        fontFamily: serifFamily,
        letterSpacing: 1.5,
        height: 1.3,
      ),
      headlineMedium: textStyle(
        18,
        fontFamily: serifFamily,
        letterSpacing: 1.2,
        height: 1.35,
      ),
      headlineSmall: textStyle(
        16,
        fontFamily: serifFamily,
        letterSpacing: 0.8,
        height: 1.4,
      ),
      titleLarge: textStyle(
        16,
        weight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.4,
      ),
      titleMedium: textStyle(14, weight: FontWeight.w500, letterSpacing: 0.2),
      titleSmall: textStyle(
        12,
        weight: FontWeight.w500,
        letterSpacing: 0.15,
        color: palette.muted,
        height: 1.5,
      ),
      bodyLarge: textStyle(15, letterSpacing: 0.2, height: 1.6),
      bodyMedium: textStyle(14, letterSpacing: 0.1, height: 1.6),
      bodySmall: textStyle(
        12,
        letterSpacing: 0.05,
        color: palette.muted,
        height: 1.55,
      ),
      labelLarge: textStyle(
        13,
        weight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
      ),
      labelMedium: textStyle(
        11,
        weight: FontWeight.w500,
        letterSpacing: 0.3,
        color: palette.muted,
        height: 1.4,
      ),
      labelSmall: textStyle(
        10,
        weight: FontWeight.w500,
        letterSpacing: 0.5,
        color: palette.muted,
        height: 1.4,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textStyle(
        18,
        fontFamily: serifFamily,
        letterSpacing: 1.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: palette.line, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.elevated,
      selectedColor: palette.accent.withValues(alpha: .18),
      disabledColor: palette.elevated.withValues(alpha: .5),
      labelStyle: textStyle(12, letterSpacing: 0.2),
      secondaryLabelStyle: textStyle(
        12,
        weight: FontWeight.w500,
        letterSpacing: 0.2,
        color: palette.accent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: palette.line, width: 0.5),
      ),
      showCheckmark: false,
      side: BorderSide(color: palette.line, width: 0.5),
      iconTheme: IconThemeData(color: palette.muted, size: 16),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.paper,
        backgroundColor: Colors.transparent,
        hoverColor: palette.paper.withValues(alpha: .06),
        highlightColor: palette.paper.withValues(alpha: .10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textStyle(
          14,
          weight: FontWeight.w500,
          letterSpacing: 0.3,
          color: palette.ink,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.paper,
        side: BorderSide(color: palette.line, width: 0.5),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textStyle(14, weight: FontWeight.w500, letterSpacing: 0.3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: textStyle(
          13,
          weight: FontWeight.w500,
          letterSpacing: 0.2,
          color: palette.accent,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(
        color: palette.muted,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.line, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.accent, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.danger, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.line, width: 0.5),
      ),
      titleTextStyle: textStyle(
        20,
        fontFamily: serifFamily,
        letterSpacing: 1.2,
      ),
      contentTextStyle: textStyle(14, height: 1.6),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.elevated,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      dragHandleColor: palette.muted,
      dragHandleSize: const Size(40, 4),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.elevated,
      contentTextStyle: textStyle(13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.line, width: 0.5),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.line,
      thumbColor: palette.paper,
      overlayColor: palette.accent.withValues(alpha: .12),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 6,
        elevation: 2,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return palette.muted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent.withValues(alpha: .35);
        }
        return palette.line;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 36,
      iconColor: palette.muted,
      textColor: palette.paper,
      titleTextStyle: textStyle(14),
      subtitleTextStyle: textStyle(12, color: palette.muted, height: 1.5),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: palette.line, width: 0.5),
      ),
      textStyle: textStyle(13),
      labelTextStyle: WidgetStateProperty.all(textStyle(13)),
    ),
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
