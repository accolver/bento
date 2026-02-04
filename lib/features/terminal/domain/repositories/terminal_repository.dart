// @telos L1:function:lib/features/terminal/domain/repositories:terminal_repository

import 'dart:typed_data';

import '../entities/terminal_config.dart';

/// Repository interface for terminal operations.
///
/// Abstracts the terminal backend (local, SSH, etc.) from the presentation layer.
abstract class TerminalRepository {
  /// Write data to the terminal.
  void write(Uint8List data);

  /// Write a string to the terminal (convenience method).
  void writeString(String text);

  /// Resize the terminal to new dimensions.
  void resize(TerminalDimensions dimensions);

  /// Get stream of output data from the terminal.
  Stream<Uint8List> get output;

  /// Get stream of title changes from the terminal.
  Stream<String> get titleChanges;

  /// Close the terminal connection.
  Future<void> close();

  /// Check if the terminal is connected.
  bool get isConnected;
}

/// Callback for terminal resize events.
typedef OnTerminalResize = void Function(TerminalDimensions dimensions);

/// Callback for terminal output data.
typedef OnTerminalOutput = void Function(Uint8List data);
