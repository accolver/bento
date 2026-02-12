// @telos-test L2:contract:lib/features/ai/presentation/widgets:remote_ai_status

import 'package:bento/features/ai/data/services/cloud_proxy_backend.dart';
import 'package:bento/features/ai/data/services/ollama_backend.dart';
import 'package:bento/features/ai/data/services/remote_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:bento/features/ai/presentation/providers/remote_ai_providers.dart';
import 'package:bento/features/ai/presentation/widgets/remote_ai_status.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSSHClient extends Mock implements SSHClient {}

void main() {
  const testHostId = 'test-host:22';
  const testHostname = 'my-server';

  late MockSSHClient mockClient;

  setUp(() {
    mockClient = MockSSHClient();
  });

  final ollamaModel = OllamaModel(
    name: 'llama3:8b',
    sizeBytes: 4661224676,
    modifiedAt: DateTime(2025, 1, 1),
  );

  final anthropicConfig = RemoteProviderRegistry.forProvider(
    RemoteCloudProvider.anthropic,
  )!;

  Widget createTestWidget({
    RemoteAiService? service,
    VoidCallback? onTap,
  }) {
    return ProviderScope(
      overrides: [
        remoteAiServiceControllerProvider(testHostId).overrideWith(
          () {
            final controller = _TestServiceController();
            controller.testService = service;
            return controller;
          },
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RemoteAiStatus(
            hostId: testHostId,
            hostname: testHostname,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('RemoteAiStatus', () {
    // @telos-scenario L2:contract:...:remote_ai_status:disconnected-state
    testWidgets('shows Disconnected when service is null', (tester) async {
      await tester.pumpWidget(createTestWidget(service: null));
      await tester.pump();

      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:ollama-connected
    testWidgets('shows Ollama backend name when connected', (tester) async {
      final service = RemoteAiService(
        client: mockClient,
        backend: OllamaBackend(
          selectedModel: 'llama3:8b',
          availableModels: [ollamaModel],
        ),
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      // OllamaBackend.displayName is "Ollama (llama3:8b)"
      expect(find.textContaining('Ollama'), findsOneWidget);
      expect(find.byIcon(Icons.memory), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:cloud-connected
    testWidgets('shows cloud backend name when connected', (tester) async {
      final service = RemoteAiService(
        client: mockClient,
        backend: CloudProxyBackend(
          providerConfig: anthropicConfig,
          envVarName: 'ANTHROPIC_API_KEY',
        ),
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      // CloudProxyBackend.displayName is the provider's displayName
      expect(find.textContaining('Claude'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:green-dot-connected
    testWidgets('shows green dot when connected', (tester) async {
      final service = RemoteAiService(
        client: mockClient,
        backend: OllamaBackend(
          selectedModel: 'llama3:8b',
          availableModels: [ollamaModel],
        ),
      );

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      // Find the green status dot container
      final greenDot = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == const Color(0xFF4CAF50) &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(greenDot, findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:red-dot-disconnected
    testWidgets('shows red dot when disconnected', (tester) async {
      await tester.pumpWidget(createTestWidget(service: null));
      await tester.pump();

      // Find the status dot — it should be the error color, not green
      final greenDot = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == const Color(0xFF4CAF50) &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(greenDot, findsNothing);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:tappable
    testWidgets('calls onTap when tapped', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(createTestWidget(
        service: null,
        onTap: () => tapCount++,
      ));
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    // @telos-scenario L2:contract:...:remote_ai_status:unfold-icon-when-tappable
    testWidgets('shows unfold_more icon when onTap provided', (tester) async {
      await tester.pumpWidget(createTestWidget(
        service: null,
        onTap: () {},
      ));
      await tester.pump();

      expect(find.byIcon(Icons.unfold_more), findsOneWidget);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:no-unfold-when-not-tappable
    testWidgets('no unfold_more icon when onTap is null', (tester) async {
      await tester.pumpWidget(createTestWidget(
        service: null,
        onTap: null,
      ));
      await tester.pump();

      expect(find.byIcon(Icons.unfold_more), findsNothing);
    });

    // @telos-scenario L2:contract:...:remote_ai_status:disconnected-after-disconnect
    testWidgets('shows disconnected after service disconnects', (tester) async {
      final service = RemoteAiService(
        client: mockClient,
        backend: OllamaBackend(
          selectedModel: 'llama3:8b',
          availableModels: [ollamaModel],
        ),
      );
      service.onDisconnected();

      await tester.pumpWidget(createTestWidget(service: service));
      await tester.pump();

      expect(find.text('Disconnected'), findsOneWidget);
    });
  });
}

/// Test implementation that returns a fixed service.
class _TestServiceController extends RemoteAiServiceController {
  RemoteAiService? testService;

  @override
  RemoteAiService? build(String hostId) {
    return testService;
  }
}
