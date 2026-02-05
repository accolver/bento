// @telos L1:function:lib/core/constants:block_colors

import 'package:flutter/material.dart';

import '../../features/terminal/domain/entities/block_status.dart';

/// Colors for terminal block status indicators.
///
/// Provides colors that work in both light and dark themes.
class BlockColors {
  BlockColors._();

  // Status colors - Light theme
  static const successLight = Color(0xFF22C55E); // Green 500
  static const failedLight = Color(0xFFEF4444); // Red 500
  static const runningLight = Color(0xFF3B82F6); // Blue 500
  static const cancelledLight = Color(0xFFF59E0B); // Amber 500

  // Status colors - Dark theme (slightly brighter for visibility)
  static const successDark = Color(0xFF4ADE80); // Green 400
  static const failedDark = Color(0xFFF87171); // Red 400
  static const runningDark = Color(0xFF60A5FA); // Blue 400
  static const cancelledDark = Color(0xFFFBBF24); // Amber 400

  // Border widths
  static const statusBorderWidth = 3.0;
  static const statusBorderRadius = 4.0;

  /// Gets the color for a block status.
  static Color forStatus(BlockStatus status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (status) {
      case BlockStatus.running:
        return isDark ? runningDark : runningLight;
      case BlockStatus.success:
        return isDark ? successDark : successLight;
      case BlockStatus.failed:
        return isDark ? failedDark : failedLight;
      case BlockStatus.cancelled:
        return isDark ? cancelledDark : cancelledLight;
    }
  }

  /// Gets the icon for a block status.
  static IconData iconForStatus(BlockStatus status) {
    switch (status) {
      case BlockStatus.running:
        return Icons.play_circle_outline;
      case BlockStatus.success:
        return Icons.check_circle_outline;
      case BlockStatus.failed:
        return Icons.error_outline;
      case BlockStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
