// Basic Flutter widget test for Bento app
//
// This is a smoke test to verify the app renders without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bento/app/app.dart';

void main() {
  testWidgets('BentoApp renders without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BentoApp(),
      ),
    );

    // Verify that the app renders (MaterialApp is present)
    expect(find.byType(BentoApp), findsOneWidget);
  });
}
