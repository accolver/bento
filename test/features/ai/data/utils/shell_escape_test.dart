// @telos-test L1:function:lib/features/ai/data/utils:shell_escape

import 'package:bento/features/ai/data/utils/shell_escape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShellEscape', () {
    group('escape', () {
      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:plain-string
      test('returns plain strings unchanged', () {
        expect(ShellEscape.escape('hello world'), 'hello world');
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:single-quotes
      test('escapes single quotes correctly', () {
        expect(
          ShellEscape.escape("it's a test"),
          "it'\\''s a test",
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:multiple-single-quotes
      test('handles multiple single quotes', () {
        expect(
          ShellEscape.escape("can't won't don't"),
          "can'\\''t won'\\''t don'\\''t",
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:empty-string
      test('handles empty string', () {
        expect(ShellEscape.escape(''), '');
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:json-content
      test('handles JSON content with double quotes', () {
        const json = '{"model":"llama3","messages":[]}';
        expect(ShellEscape.escape(json), json);
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:special-chars
      test('leaves dollar signs and backticks unchanged', () {
        // These are safe inside single quotes (the outer quoting context)
        const input = r'$HOME `whoami`';
        expect(ShellEscape.escape(input), input);
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:newlines
      test('preserves newlines', () {
        const input = 'line1\nline2';
        expect(ShellEscape.escape(input), input);
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:unicode
      test('preserves unicode characters', () {
        const input = 'Hello 世界 🌍';
        expect(ShellEscape.escape(input), input);
      });
    });

    group('quote', () {
      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:quote-wrapping
      test('wraps string in single quotes with escaping', () {
        expect(ShellEscape.quote('hello'), "'hello'");
      });

      // @telos-scenario L1:function:lib/features/ai/data/utils:shell_escape:quote-with-single-quotes
      test('wraps and escapes single quotes', () {
        expect(
          ShellEscape.quote("it's"),
          "'it'\\''s'",
        );
      });
    });
  });
}
