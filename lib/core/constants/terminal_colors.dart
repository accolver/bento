// @telos L1:function:lib/core/constants:terminal_colors

import 'package:flutter/material.dart';

/// Terminal color scheme definitions.
///
/// Provides ANSI 16-color palette for both light and dark themes,
/// following standard terminal color conventions.
abstract class TerminalColors {
  TerminalColors._();

  /// Dark theme terminal colors (default).
  static const TerminalColorScheme dark = TerminalColorScheme(
    // Standard colors (0-7)
    black: Color(0xFF1D1F21),
    red: Color(0xFFCC6666),
    green: Color(0xFFB5BD68),
    yellow: Color(0xFFF0C674),
    blue: Color(0xFF81A2BE),
    magenta: Color(0xFFB294BB),
    cyan: Color(0xFF8ABEB7),
    white: Color(0xFFC5C8C6),
    // Bright colors (8-15)
    brightBlack: Color(0xFF969896),
    brightRed: Color(0xFFDE935F),
    brightGreen: Color(0xFFB5BD68),
    brightYellow: Color(0xFFF0C674),
    brightBlue: Color(0xFF81A2BE),
    brightMagenta: Color(0xFFB294BB),
    brightCyan: Color(0xFF8ABEB7),
    brightWhite: Color(0xFFFFFFFF),
    // UI colors
    foreground: Color(0xFFC5C8C6),
    background: Color(0xFF1D1F21),
    cursor: Color(0xFFC5C8C6),
    selection: Color(0xFF373B41),
  );

  /// Light theme terminal colors.
  static const TerminalColorScheme light = TerminalColorScheme(
    // Standard colors (0-7)
    black: Color(0xFF000000),
    red: Color(0xFFC82829),
    green: Color(0xFF718C00),
    yellow: Color(0xFFEAB700),
    blue: Color(0xFF4271AE),
    magenta: Color(0xFF8959A8),
    cyan: Color(0xFF3E999F),
    white: Color(0xFFFFFFFF),
    // Bright colors (8-15)
    brightBlack: Color(0xFF8E908C),
    brightRed: Color(0xFFF5871F),
    brightGreen: Color(0xFF718C00),
    brightYellow: Color(0xFFEAB700),
    brightBlue: Color(0xFF4271AE),
    brightMagenta: Color(0xFF8959A8),
    brightCyan: Color(0xFF3E999F),
    brightWhite: Color(0xFFFFFFFF),
    // UI colors
    foreground: Color(0xFF4D4D4C),
    background: Color(0xFFFFFFFF),
    cursor: Color(0xFF4D4D4C),
    selection: Color(0xFFD6D6D6),
  );

  /// Get color scheme for brightness.
  static TerminalColorScheme forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// A complete terminal color scheme.
class TerminalColorScheme {
  const TerminalColorScheme({
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
    required this.brightBlack,
    required this.brightRed,
    required this.brightGreen,
    required this.brightYellow,
    required this.brightBlue,
    required this.brightMagenta,
    required this.brightCyan,
    required this.brightWhite,
    required this.foreground,
    required this.background,
    required this.cursor,
    required this.selection,
  });

  // Standard colors (0-7)
  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color magenta;
  final Color cyan;
  final Color white;

  // Bright colors (8-15)
  final Color brightBlack;
  final Color brightRed;
  final Color brightGreen;
  final Color brightYellow;
  final Color brightBlue;
  final Color brightMagenta;
  final Color brightCyan;
  final Color brightWhite;

  // UI colors
  final Color foreground;
  final Color background;
  final Color cursor;
  final Color selection;

  /// Get color by ANSI index (0-15).
  Color getAnsiColor(int index) {
    return switch (index) {
      0 => black,
      1 => red,
      2 => green,
      3 => yellow,
      4 => blue,
      5 => magenta,
      6 => cyan,
      7 => white,
      8 => brightBlack,
      9 => brightRed,
      10 => brightGreen,
      11 => brightYellow,
      12 => brightBlue,
      13 => brightMagenta,
      14 => brightCyan,
      15 => brightWhite,
      _ => foreground,
    };
  }

  /// Convert to xterm ColorPalette list.
  List<Color> toColorList() {
    return [
      black,
      red,
      green,
      yellow,
      blue,
      magenta,
      cyan,
      white,
      brightBlack,
      brightRed,
      brightGreen,
      brightYellow,
      brightBlue,
      brightMagenta,
      brightCyan,
      brightWhite,
    ];
  }
}
