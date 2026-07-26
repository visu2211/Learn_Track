import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Builds the two ThemeData objects MaterialApp switches between (see
// main.dart: theme/darkTheme/themeMode). The important bit is `extensions:
// [colors]` below - that's what makes `Theme.of(context).extension<AppColorsExt>()`
// resolve to AppColorsExt.light or .dark depending on the active mode, which
// is how every widget in the app picks its colors without ever checking
// brightness itself.
class AppTheme {
  static ThemeData get light => _build(AppColorsExt.light, Brightness.light);
  static ThemeData get dark => _build(AppColorsExt.dark, Brightness.dark);

  static ThemeData _build(AppColorsExt colors, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.surface,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary),
      dividerTheme: DividerThemeData(color: colors.border),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent
              : colors.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.accent.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
    );
  }
}
