// @telos L1:function:lib/app:theme

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration.
///
/// Provides light and dark themes optimized for terminal usage
/// with monospace fonts and high-contrast colors.
abstract class BentoTheme {
  BentoTheme._();

  // Terminal-inspired color palette
  static const _terminalGreen = Color(0xFF00FF00);
  static const _terminalAmber = Color(0xFFFFB000);
  static const _terminalCyan = Color(0xFF00FFFF);

  /// Light theme configuration.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _terminalCyan,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// Dark theme configuration.
  ///
  /// Optimized for terminal usage with dark backgrounds.
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _terminalGreen,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        surface: const Color(0xFF0D1117),
        surfaceContainerHighest: const Color(0xFF161B22),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// Build text theme with monospace font for terminal content.
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    // Use system fonts initially, Google Fonts will be loaded async
    final baseTextTheme = ThemeData(
      brightness: colorScheme.brightness,
    ).textTheme;

    // Apply monospace font for code/terminal content
    final monoTextStyle = GoogleFonts.jetBrainsMono();

    return baseTextTheme.copyWith(
      // Terminal output uses monospace
      bodySmall: monoTextStyle.copyWith(
        fontSize: 12,
        color: colorScheme.onSurface,
      ),
      labelSmall: monoTextStyle.copyWith(
        fontSize: 10,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Terminal-specific theme extensions.
extension TerminalTheme on ThemeData {
  /// Terminal text color (green on dark, dark on light).
  Color get terminalTextColor => brightness == Brightness.dark
      ? const Color(0xFF00FF00)
      : const Color(0xFF1A1A2E);

  /// Terminal background color.
  Color get terminalBackgroundColor => brightness == Brightness.dark
      ? const Color(0xFF0D1117)
      : const Color(0xFFF6F8FA);

  /// Terminal cursor color.
  Color get terminalCursorColor => brightness == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);

  /// Error text color in terminal.
  Color get terminalErrorColor => colorScheme.error;

  /// Warning text color in terminal.
  Color get terminalWarningColor =>
      brightness == Brightness.dark ? const Color(0xFFFFB000) : Colors.orange;

  /// Success text color in terminal.
  Color get terminalSuccessColor =>
      brightness == Brightness.dark ? const Color(0xFF00FF00) : Colors.green;
}
