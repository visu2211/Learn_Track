import 'package:flutter/material.dart';

/// Semantic colors used throughout the app. Widgets should read these via
/// `Theme.of(context).extension<AppColorsExt>()!` instead of hardcoding hex
/// values, so both the light and dark themes stay in sync automatically.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color accent;
  final Color accentGradientStart;
  final Color accentGradientEnd;
  final Color accentSurface;
  final Color success;
  final Color successSurface;
  final Color successText;
  final Color error;
  final Color shadow;

  const AppColorsExt({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.accent,
    required this.accentGradientStart,
    required this.accentGradientEnd,
    required this.accentSurface,
    required this.success,
    required this.successSurface,
    required this.successText,
    required this.error,
    required this.shadow,
  });

  static const light = AppColorsExt(
    background: Color(0xFFF9FAFB),
    surface: Colors.white,
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    border: Color(0xFFE5E7EB),
    accent: Color(0xFF4F46E5),
    accentGradientStart: Color(0xFF4F46E5),
    accentGradientEnd: Color(0xFF7C3AED),
    accentSurface: Color(0xFFF3F4F6),
    success: Color(0xFF059669),
    successSurface: Color(0xFFDCFCE7),
    successText: Color(0xFF14532D),
    error: Color(0xFFEF4444),
    shadow: Color(0x14000000),
  );

  static const dark = AppColorsExt(
    background: Color(0xFF0D0F17),
    surface: Color(0xFF181B27),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    border: Color(0xFF2D3140),
    accent: Color(0xFF818CF8),
    accentGradientStart: Color(0xFF6366F1),
    accentGradientEnd: Color(0xFF9333EA),
    accentSurface: Color(0xFF232739),
    success: Color(0xFF4ADE80),
    successSurface: Color(0xFF14321F),
    successText: Color(0xFFBBF7D0),
    error: Color(0xFFF87171),
    shadow: Color(0x66000000),
  );

  @override
  AppColorsExt copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? accent,
    Color? accentGradientStart,
    Color? accentGradientEnd,
    Color? accentSurface,
    Color? success,
    Color? successSurface,
    Color? successText,
    Color? error,
    Color? shadow,
  }) {
    return AppColorsExt(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentGradientStart: accentGradientStart ?? this.accentGradientStart,
      accentGradientEnd: accentGradientEnd ?? this.accentGradientEnd,
      accentSurface: accentSurface ?? this.accentSurface,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      successText: successText ?? this.successText,
      error: error ?? this.error,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    return AppColorsExt(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGradientStart:
          Color.lerp(accentGradientStart, other.accentGradientStart, t)!,
      accentGradientEnd:
          Color.lerp(accentGradientEnd, other.accentGradientEnd, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      error: Color.lerp(error, other.error, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Convenience accessor: `context.colors.textPrimary`.
extension AppColorsContext on BuildContext {
  AppColorsExt get colors =>
      Theme.of(this).extension<AppColorsExt>() ?? AppColorsExt.light;
}
