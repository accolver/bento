// @telos L1:function:lib/features/terminal/presentation/providers:terminal_provider

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/constants/terminal_colors.dart';
import 'terminal_config_provider.dart';

part 'terminal_provider.g.dart';

/// Manages terminal instance lifecycle.
///
/// Creates and disposes Terminal instances, configuring them with
/// the appropriate settings.
@riverpod
class TerminalController extends _$TerminalController {
  @override
  Terminal build() {
    final config = ref.watch(terminalConfigProvider);

    final terminal = Terminal(
      maxLines: config.scrollbackLines,
    );

    // Clean up when provider is disposed
    ref.onDispose(() {
      // Terminal doesn't have a dispose method, but we could
      // clean up any listeners here if needed
    });

    return terminal;
  }

  /// Write a string to the terminal.
  void write(String text) {
    state.write(text);
  }

  /// Write bytes to the terminal.
  void writeBytes(List<int> data) {
    state.write(String.fromCharCodes(data));
  }

  /// Clear the terminal screen.
  void clear() {
    state.write('\x1b[2J\x1b[H');
  }

  /// Resize the terminal.
  void resize(int cols, int rows) {
    state.resize(cols, rows);
  }
}

/// Provides an xterm TerminalTheme from our color scheme.
@riverpod
TerminalTheme terminalTheme(
  TerminalThemeRef ref,
  Brightness brightness,
) {
  final colors = TerminalColors.forBrightness(brightness);

  return TerminalTheme(
    cursor: colors.cursor,
    selection: colors.selection,
    foreground: colors.foreground,
    background: colors.background,
    black: colors.black,
    red: colors.red,
    green: colors.green,
    yellow: colors.yellow,
    blue: colors.blue,
    magenta: colors.magenta,
    cyan: colors.cyan,
    white: colors.white,
    brightBlack: colors.brightBlack,
    brightRed: colors.brightRed,
    brightGreen: colors.brightGreen,
    brightYellow: colors.brightYellow,
    brightBlue: colors.brightBlue,
    brightMagenta: colors.brightMagenta,
    brightCyan: colors.brightCyan,
    brightWhite: colors.brightWhite,
    searchHitBackground: colors.selection,
    searchHitBackgroundCurrent: colors.yellow,
    searchHitForeground: colors.foreground,
  );
}
