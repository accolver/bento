// @telos-test L1:function:lib/features/credentials/presentation/screens:key_import_screen

import 'package:bento/features/credentials/presentation/screens/key_import_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyImportScreen', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: KeyImportScreen(),
        ),
      );
    }

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_import_screen:renders-import-options
    testWidgets('renders import options when no key loaded', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show import description
      expect(find.text('Import an existing SSH private key'), findsOneWidget);

      // Should show file picker button
      expect(find.text('Choose File'), findsOneWidget);

      // Should show clipboard button
      expect(find.text('Paste from Clipboard'), findsOneWidget);

      // Should show security note
      expect(
        find.textContaining('stored encrypted'),
        findsOneWidget,
      );
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_import_screen:has-app-bar
    testWidgets('has correct app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Import SSH Key'), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_import_screen:shows-supported-formats
    testWidgets('shows supported key formats', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('RSA, Ed25519, and ECDSA'),
        findsOneWidget,
      );
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_import_screen:file-picker-button-tappable
    testWidgets('file picker button is tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final button = find.text('Choose File');
      expect(button, findsOneWidget);

      // Button should be enabled
      final buttonWidget = tester.widget<OutlinedButton>(
        find.ancestor(
          of: button,
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNotNull);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_import_screen:clipboard-button-tappable
    testWidgets('clipboard button is tappable', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final button = find.text('Paste from Clipboard');
      expect(button, findsOneWidget);

      // Button should be enabled
      final buttonWidget = tester.widget<OutlinedButton>(
        find.ancestor(
          of: button,
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNotNull);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_import_screen:shows-icons
    testWidgets('shows appropriate icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // File picker icon
      expect(find.byIcon(Icons.folder_open), findsOneWidget);

      // Clipboard icon
      expect(find.byIcon(Icons.content_paste), findsOneWidget);

      // Security icon
      expect(find.byIcon(Icons.security), findsOneWidget);
    });
  });
}
