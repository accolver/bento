// @telos-test L1:function:lib/features/terminal/domain/entities:terminal_config

import 'dart:ui';

import 'package:bento/features/terminal/domain/entities/terminal_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalConfig', () {
    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:default-values
    test('has sensible default values', () {
      const config = TerminalConfig();

      expect(
          config.fontFamily, 'JetBrainsMonoNF'); // Nerd Font for Unicode glyphs
      expect(config.fontSize, 14.0);
      expect(config.lineHeight, 1.2);
      expect(config.scrollbackLines, 10000);
      expect(config.minColumns, 20);
      expect(config.minRows, 5);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:char-height
    test('calculates character height correctly', () {
      const config = TerminalConfig(fontSize: 14.0, lineHeight: 1.2);

      expect(config.charHeight, 14.0 * 1.2);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:copy-with
    test('copyWith creates modified copy', () {
      const original = TerminalConfig();
      final modified = original.copyWith(fontSize: 16.0);

      expect(modified.fontSize, 16.0);
      expect(modified.fontFamily, original.fontFamily);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:equality
    test('equality works correctly', () {
      const config1 = TerminalConfig();
      const config2 = TerminalConfig();
      const config3 = TerminalConfig(fontSize: 16.0);

      expect(config1, config2);
      expect(config1, isNot(config3));
    });
  });

  group('TerminalDimensions', () {
    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:dimensions-equality
    test('equality works correctly', () {
      const dims1 = TerminalDimensions(columns: 80, rows: 24);
      const dims2 = TerminalDimensions(columns: 80, rows: 24);
      const dims3 = TerminalDimensions(columns: 120, rows: 40);

      expect(dims1, dims2);
      expect(dims1, isNot(dims3));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:dimensions-tostring
    test('toString is readable', () {
      const dims = TerminalDimensions(columns: 80, rows: 24);

      expect(dims.toString(), 'TerminalDimensions(80 x 24)');
    });
  });

  group('calculateTerminalDimensions', () {
    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:calculate-dimensions
    test('calculates dimensions from size', () {
      final dims = calculateTerminalDimensions(
        availableSize: const Size(480, 320),
        charWidth: 8.0,
        charHeight: 16.0,
        minColumns: 20,
        minRows: 5,
      );

      expect(dims.columns, 60); // 480 / 8 = 60
      expect(dims.rows, 20); // 320 / 16 = 20
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:min-columns-enforced
    test('enforces minimum columns', () {
      final dims = calculateTerminalDimensions(
        availableSize: const Size(100, 320),
        charWidth: 8.0,
        charHeight: 16.0,
        minColumns: 20,
        minRows: 5,
      );

      expect(dims.columns, 20); // Would be 12, clamped to 20
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_config:min-rows-enforced
    test('enforces minimum rows', () {
      final dims = calculateTerminalDimensions(
        availableSize: const Size(480, 32),
        charWidth: 8.0,
        charHeight: 16.0,
        minColumns: 20,
        minRows: 5,
      );

      expect(dims.rows, 5); // Would be 2, clamped to 5
    });
  });
}
