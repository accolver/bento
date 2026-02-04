// @telos L1:function:lib/features/terminal/presentation/providers:terminal_config_provider

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/terminal_colors.dart';
import '../../domain/entities/terminal_config.dart';

part 'terminal_config_provider.g.dart';

/// Provides the terminal configuration.
@riverpod
TerminalConfig terminalConfig(TerminalConfigRef ref) {
  return const TerminalConfig();
}

/// Provides the terminal color scheme based on current brightness.
@riverpod
TerminalColorScheme terminalColorScheme(
  TerminalColorSchemeRef ref,
  Brightness brightness,
) {
  return TerminalColors.forBrightness(brightness);
}
