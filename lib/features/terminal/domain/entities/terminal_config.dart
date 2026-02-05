// @telos L1:function:lib/features/terminal/domain/entities:terminal_config

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Configuration for a terminal instance.
///
/// Contains settings for fonts, colors, dimensions, and behavior.
class TerminalConfig extends Equatable {
  const TerminalConfig({
    // Use Nerd Font version for Unicode glyph support (Starship, Powerline, etc.)
    this.fontFamily = 'JetBrainsMonoNF',
    this.fontSize = 14.0,
    this.lineHeight = 1.2,
    this.cursorBlinkInterval = const Duration(milliseconds: 500),
    this.scrollbackLines = 10000,
    this.minColumns = 20,
    this.minRows = 5,
    this.enableSemanticBlocks = true,
    this.customPromptPatterns = const [],
  });

  /// Font family for terminal text.
  final String fontFamily;

  /// Font size in logical pixels.
  final double fontSize;

  /// Line height multiplier.
  final double lineHeight;

  /// Interval for cursor blinking.
  final Duration cursorBlinkInterval;

  /// Maximum lines to keep in scrollback buffer.
  final int scrollbackLines;

  /// Minimum number of columns.
  final int minColumns;

  /// Minimum number of rows.
  final int minRows;

  /// Whether semantic blocks are enabled.
  ///
  /// When true, commands and output are grouped into collapsible blocks.
  /// When false, classic continuous terminal output is used.
  final bool enableSemanticBlocks;

  /// Custom regex patterns for shell prompt detection.
  ///
  /// These patterns are used in addition to the default patterns
  /// to detect when a new command is being entered.
  final List<String> customPromptPatterns;

  /// Calculate the character height based on font size and line height.
  double get charHeight => fontSize * lineHeight;

  /// Create a copy with modified values.
  TerminalConfig copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    Duration? cursorBlinkInterval,
    int? scrollbackLines,
    int? minColumns,
    int? minRows,
    bool? enableSemanticBlocks,
    List<String>? customPromptPatterns,
  }) {
    return TerminalConfig(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      cursorBlinkInterval: cursorBlinkInterval ?? this.cursorBlinkInterval,
      scrollbackLines: scrollbackLines ?? this.scrollbackLines,
      minColumns: minColumns ?? this.minColumns,
      minRows: minRows ?? this.minRows,
      enableSemanticBlocks: enableSemanticBlocks ?? this.enableSemanticBlocks,
      customPromptPatterns: customPromptPatterns ?? this.customPromptPatterns,
    );
  }

  @override
  List<Object?> get props => [
        fontFamily,
        fontSize,
        lineHeight,
        cursorBlinkInterval,
        scrollbackLines,
        minColumns,
        minRows,
        enableSemanticBlocks,
        customPromptPatterns,
      ];
}

/// Terminal dimensions in columns and rows.
class TerminalDimensions extends Equatable {
  const TerminalDimensions({
    required this.columns,
    required this.rows,
  });

  /// Number of character columns.
  final int columns;

  /// Number of character rows.
  final int rows;

  @override
  List<Object?> get props => [columns, rows];

  @override
  String toString() => 'TerminalDimensions($columns x $rows)';
}

/// Calculates terminal dimensions from available size.
TerminalDimensions calculateTerminalDimensions({
  required Size availableSize,
  required double charWidth,
  required double charHeight,
  required int minColumns,
  required int minRows,
}) {
  final columns = (availableSize.width / charWidth).floor();
  final rows = (availableSize.height / charHeight).floor();

  return TerminalDimensions(
    columns: columns.clamp(minColumns, 500),
    rows: rows.clamp(minRows, 200),
  );
}
