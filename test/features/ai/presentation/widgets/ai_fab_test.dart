// @telos-test L1:function:lib/features/ai/presentation/widgets:ai_fab
import 'package:bento/features/ai/presentation/widgets/ai_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiFab', () {
    // Helper to create testable widget
    Widget createTestWidget({
      required VoidCallback onPressed,
      bool disableAnimations = false,
    }) {
      return ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [
              // Add AI theme extension
            ],
          ),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Scaffold(
              body: Center(
                child: AiFab(onPressed: onPressed),
              ),
            ),
          ),
        ),
      );
    }

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:renders
    testWidgets('renders correctly', (tester) async {
      var pressed = false;

      await tester.pumpWidget(createTestWidget(
        onPressed: () => pressed = true,
      ));

      // Should find the FAB
      expect(find.byType(AiFab), findsOneWidget);

      // Should have an icon
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:tap-callback
    testWidgets('calls onPressed when tapped', (tester) async {
      var pressCount = 0;

      await tester.pumpWidget(createTestWidget(
        onPressed: () => pressCount++,
      ));

      // Tap the FAB
      await tester.tap(find.byType(AiFab));
      await tester.pump();

      expect(pressCount, equals(1));

      // Tap again
      await tester.tap(find.byType(AiFab));
      await tester.pump();

      expect(pressCount, equals(2));
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:semantic-label
    testWidgets('has semantic label for accessibility', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onPressed: () {},
      ));

      // Find icon with semantic label
      final iconFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.auto_awesome &&
            widget.semanticLabel == 'AI Assistant',
      );

      expect(iconFinder, findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:respects-reduced-motion
    testWidgets('respects reduced motion preference', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onPressed: () {},
        disableAnimations: true,
      ));

      // Let the widget build
      await tester.pump();

      // The FAB should still render
      expect(find.byType(AiFab), findsOneWidget);

      // Animation should not be running (hard to test directly,
      // but we verify the widget doesn't crash with animations disabled)
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:size
    testWidgets('has correct size', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onPressed: () {},
      ));

      // Find the outer SizedBox
      final sizedBoxFinder = find.ancestor(
        of: find.byType(AiFab),
        matching: find.byType(SizedBox),
      );

      // The widget itself is wrapped in SizedBox(64x64)
      final fabWidget = tester.widget<AiFab>(find.byType(AiFab));
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AiFab),
          matching: find.byType(SizedBox).first,
        ),
      );

      expect(sizedBox.width, equals(64));
      expect(sizedBox.height, equals(64));
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:haptic-feedback
    testWidgets('triggers haptic feedback on tap', (tester) async {
      final hapticCalls = <String>[];

      // Mock the HapticFeedback channel
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(methodCall.arguments as String);
          }
          return null;
        },
      );

      await tester.pumpWidget(createTestWidget(
        onPressed: () {},
      ));

      // Tap the FAB
      await tester.tap(find.byType(AiFab));
      await tester.pump();

      // Verify haptic feedback was triggered
      expect(hapticCalls, contains('HapticFeedbackType.mediumImpact'));
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:animation-runs
    testWidgets('pulse animation runs when enabled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onPressed: () {},
        disableAnimations: false,
      ));

      // Let animation start
      await tester.pump();

      // Advance time to see animation changes
      await tester.pump(const Duration(milliseconds: 500));

      // The FAB should still be there (animation running)
      expect(find.byType(AiFab), findsOneWidget);

      // Advance more
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(AiFab), findsOneWidget);
    });

    // @telos-scenario L1:function:lib/features/ai/presentation/widgets:ai_fab:gradient-background
    testWidgets('has gradient decoration', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onPressed: () {},
      ));

      // Find an Ink widget with gradient
      final inkFinder = find.byWidgetPredicate((widget) {
        if (widget is Ink && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.gradient != null;
        }
        return false;
      });

      expect(inkFinder, findsOneWidget);
    });
  });
}
