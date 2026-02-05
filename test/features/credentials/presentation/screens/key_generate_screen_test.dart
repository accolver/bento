// @telos-test L1:function:lib/features/credentials/presentation/screens:key_generate_screen

import 'package:bento/features/credentials/domain/entities/credential.dart';
import 'package:bento/features/credentials/presentation/screens/key_generate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyGenerateScreen', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: KeyGenerateScreen(),
        ),
      );
    }

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:renders-generation-form
    testWidgets('renders key generation form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show description
      expect(find.text('Generate a new SSH key pair'), findsOneWidget);

      // Should show key type section
      expect(find.text('Key Type'), findsOneWidget);

      // Should show generate button
      expect(find.text('Generate Key'), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:has-app-bar
    testWidgets('has correct app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Generate SSH Key'), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:shows-key-type-options
    testWidgets('shows Ed25519 and RSA key type options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show both key types in segmented button
      expect(find.text('Ed25519'), findsOneWidget);
      expect(find.text('RSA-4096'), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:ed25519-recommended
    testWidgets('shows Ed25519 recommendation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Default selection should be Ed25519, which shows the recommendation text
      expect(
        find.textContaining('Ed25519 is the recommended choice'),
        findsOneWidget,
      );
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:generate-button-enabled
    testWidgets('generate button is enabled initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The generate button text should exist and be tappable
      final button = find.text('Generate Key');
      expect(button, findsOneWidget);

      // The button should be part of a tappable widget
      // FilledButton.icon creates a _FilledButtonWithIcon which is a subclass
      expect(
        find.ancestor(
          of: button,
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
        findsOneWidget,
      );
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:can-switch-key-type
    testWidgets('can switch between key types', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially shows Ed25519 recommendation
      expect(
        find.textContaining('Ed25519 is the recommended'),
        findsOneWidget,
      );

      // Tap RSA option
      await tester.tap(find.text('RSA-4096'));
      await tester.pumpAndSettle();

      // Should now show RSA description
      expect(
        find.textContaining('RSA-4096 offers maximum compatibility'),
        findsOneWidget,
      );
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:shows-icons
    testWidgets('shows appropriate icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // SegmentedButton contains ButtonSegment widgets which have icons
      // The key icon is on the generate button
      expect(find.byType(SegmentedButton<CredentialType>), findsOneWidget);
      expect(find.byIcon(Icons.key), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/credentials/presentation/screens:key_generate_screen:security-note
    testWidgets('shows security note about storage', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('stored securely on your device'),
        findsOneWidget,
      );
    });
  });
}
