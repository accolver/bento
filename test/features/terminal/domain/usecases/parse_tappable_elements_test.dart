// @telos-test L1:function:lib/features/terminal/domain/usecases:parseTappableElements
import 'package:bento/features/terminal/domain/usecases/parse_tappable_elements.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseTappableElements', () {
    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:detect-ipv4
    test('Detect IPv4 address', () {
      // GIVEN output contains "Server running at 192.168.1.100:8080"
      const output = 'Server running at 192.168.1.100:8080';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains a TappableElement
      // AND element.type equals TappableType.ipAddress
      // AND element.value equals "192.168.1.100"
      expect(result, isNotEmpty);
      final ipElement = result.firstWhere(
        (e) => e.type == TappableType.ipAddress,
      );
      expect(ipElement.value, equals('192.168.1.100'));
      expect(ipElement.startOffset, equals(18));
      expect(ipElement.endOffset, equals(31));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:detect-multiple-ipv4
    test('Detect multiple IPv4 addresses', () {
      // GIVEN output contains "Source: 10.0.0.1 -> Destination: 10.0.0.2"
      const output = 'Source: 10.0.0.1 -> Destination: 10.0.0.2';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains 2 TappableElements with type ipAddress
      final ips =
          result.where((e) => e.type == TappableType.ipAddress).toList();
      expect(ips.length, equals(2));
      expect(ips[0].value, equals('10.0.0.1'));
      expect(ips[1].value, equals('10.0.0.2'));
      // AND elements are sorted by startOffset
      expect(ips[0].startOffset, lessThan(ips[1].startOffset));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:detect-unix-path
    test('Detect Unix file path', () {
      // GIVEN output contains "Error in /var/log/nginx/error.log at line 42"
      const output = 'Error in /var/log/nginx/error.log at line 42';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains a TappableElement
      // AND element.type equals TappableType.filePath
      // AND element.value equals "/var/log/nginx/error.log"
      final pathElement = result.firstWhere(
        (e) => e.type == TappableType.filePath,
      );
      expect(pathElement.value, equals('/var/log/nginx/error.log'));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:detect-http-url
    test('Detect HTTP URL', () {
      // GIVEN output contains "Visit https://example.com/api/v1/users for docs"
      const output = 'Visit https://example.com/api/v1/users for docs';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains a TappableElement
      // AND element.type equals TappableType.url
      // AND element.value equals "https://example.com/api/v1/users"
      final urlElement = result.firstWhere(
        (e) => e.type == TappableType.url,
      );
      expect(urlElement.value, equals('https://example.com/api/v1/users'));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:detect-url-with-query
    test('Detect URL with query parameters', () {
      // GIVEN output contains "Redirect to https://example.com/auth?token=abc&redirect=/home"
      const output =
          'Redirect to https://example.com/auth?token=abc&redirect=/home';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains a TappableElement
      // AND element.type equals TappableType.url
      final urlElement = result.firstWhere(
        (e) => e.type == TappableType.url,
      );
      expect(
        urlElement.value,
        equals('https://example.com/auth?token=abc&redirect=/home'),
      );
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:detect-email
    test('Detect email address', () {
      // GIVEN output contains "Contact: admin@example.com for support"
      const output = 'Contact: admin@example.com for support';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains a TappableElement
      // AND element.type equals TappableType.email
      // AND element.value equals "admin@example.com"
      final emailElement = result.firstWhere(
        (e) => e.type == TappableType.email,
      );
      expect(emailElement.value, equals('admin@example.com'));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:no-elements
    test('No tappable elements', () {
      // GIVEN output contains "Operation completed successfully"
      const output = 'Operation completed successfully';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result is an empty list
      expect(result, isEmpty);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:overlapping-priority
    test('Overlapping patterns - URL takes priority over embedded IP', () {
      // GIVEN output contains "http://192.168.1.1/admin"
      const output = 'http://192.168.1.1/admin';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains one TappableElement
      // AND element.type equals TappableType.url
      // AND the URL takes priority over the embedded IP
      expect(result.length, equals(1));
      expect(result.first.type, equals(TappableType.url));
      expect(result.first.value, equals('http://192.168.1.1/admin'));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:performance-large-output
    test('Large output performance', () {
      // GIVEN output contains 10000 lines of log data
      final output = List.generate(
        10000,
        (i) => 'Log line $i: 192.168.1.${i % 256}',
      ).join('\n');

      // WHEN parseTappableElements is called
      final stopwatch = Stopwatch()..start();
      final result = parseTappableElements(output);
      stopwatch.stop();

      // THEN result is returned within reasonable time
      // AND all valid elements are detected
      expect(result, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:multiple-types-one-line
    test('Multiple types in one line', () {
      // GIVEN output contains "User admin@example.com logged in from 10.0.0.1 - see /var/log/auth.log"
      const output =
          'User admin@example.com logged in from 10.0.0.1 - see /var/log/auth.log';

      // WHEN parseTappableElements is called
      final result = parseTappableElements(output);

      // THEN result contains 3 TappableElements
      // AND elements are sorted by startOffset
      expect(result.length, equals(3));
      expect(result[0].type, equals(TappableType.email));
      expect(result[1].type, equals(TappableType.ipAddress));
      expect(result[2].type, equals(TappableType.filePath));
      // Verify sorted by startOffset
      for (var i = 1; i < result.length; i++) {
        expect(result[i].startOffset, greaterThan(result[i - 1].startOffset));
      }
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:empty-input
    test('Empty input returns empty list', () {
      final result = parseTappableElements('');
      expect(result, isEmpty);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/usecases:parseTappableElements:invalid-ip
    test('Does not match invalid IP addresses', () {
      const output = 'Not an IP: 999.999.999.999';
      final result = parseTappableElements(output);
      final ips = result.where((e) => e.type == TappableType.ipAddress);
      expect(ips, isEmpty);
    });
  });
}
