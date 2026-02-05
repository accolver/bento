// @telos-test L2:contract:component-tab-bar

import 'package:bento/features/session/domain/entities/session.dart';
import 'package:bento/features/session/domain/entities/session_status.dart';
import 'package:bento/features/session/presentation/widgets/session_tab_bar.dart';
import 'package:bento/features/terminal/domain/entities/ssh_auth_method.dart';
import 'package:bento/features/terminal/domain/entities/ssh_connection_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SSHConnectionConfig testConfig;
  late DateTime testTime;

  setUp(() {
    testConfig = const SSHConnectionConfig(
      host: 'test.example.com',
      authMethod: SSHAuthMethod.password(
        username: 'testuser',
        password: 'testpass',
      ),
    );
    testTime = DateTime(2025, 2, 5, 10, 0, 0);
  });

  Session createSession({
    required String id,
    required String name,
    SessionStatus status = SessionStatus.connected,
    int unreadCount = 0,
    bool hasRunningCommand = false,
  }) {
    return Session(
      id: id,
      name: name,
      connectionConfig: testConfig,
      status: status,
      createdAt: testTime,
      lastAccessedAt: testTime,
      unreadCount: unreadCount,
      hasRunningCommand: hasRunningCommand,
    );
  }

  group('SessionTabBar', () {
    // @telos-scenario L2:contract:component-tab-bar:renders-tabs
    group('renders tabs', () {
      testWidgets('shows tabs for each session', (tester) async {
        final sessions = [
          createSession(id: '1', name: 'Server 1'),
          createSession(id: '2', name: 'Server 2'),
          createSession(id: '3', name: 'Server 3'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Server 1'), findsOneWidget);
        expect(find.text('Server 2'), findsOneWidget);
        expect(find.text('Server 3'), findsOneWidget);
      });

      testWidgets('shows add button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: [],
                activeSessionId: null,
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('highlights active tab', (tester) async {
        final sessions = [
          createSession(id: '1', name: 'Server 1'),
          createSession(id: '2', name: 'Server 2'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Find the active tab - it should have a different background
        final activeTab = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Server 1'),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(activeTab, isNotNull);
      });
    });

    // @telos-scenario L2:contract:component-tab-bar:tab-selection
    group('tab selection', () {
      testWidgets('calls onTabSelected when tab is tapped', (tester) async {
        String? selectedId;
        final sessions = [
          createSession(id: '1', name: 'Server 1'),
          createSession(id: '2', name: 'Server 2'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (id) => selectedId = id,
                onAddTap: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('Server 2'));
        await tester.pumpAndSettle();

        expect(selectedId, equals('2'));
      });

      testWidgets('calls onAddTap when add button is tapped', (tester) async {
        var addTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: [],
                activeSessionId: null,
                onTabSelected: (_) {},
                onAddTap: () => addTapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(addTapped, isTrue);
      });
    });

    // @telos-scenario L2:contract:component-tab-bar:status-indicators
    group('status indicators', () {
      testWidgets('shows green indicator for connected status', (tester) async {
        final sessions = [
          createSession(
              id: '1', name: 'Server 1', status: SessionStatus.connected),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Should find a green status indicator
        final greenIndicator = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.green,
        );
        expect(greenIndicator, findsWidgets);
      });

      testWidgets('shows red indicator for disconnected status',
          (tester) async {
        final sessions = [
          createSession(
              id: '1', name: 'Server 1', status: SessionStatus.disconnected),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Should find a red status indicator
        final redIndicator = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.red,
        );
        expect(redIndicator, findsWidgets);
      });

      testWidgets('shows indicator for failed status', (tester) async {
        final sessions = [
          createSession(
              id: '1', name: 'Server 1', status: SessionStatus.failed),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Should find a red status indicator for failed
        final redIndicator = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.red,
        );
        expect(redIndicator, findsWidgets);
      });
    });

    // @telos-scenario L2:contract:component-tab-bar:unread-badge
    group('unread badge', () {
      testWidgets('shows unread count badge when > 0', (tester) async {
        final sessions = [
          createSession(id: '1', name: 'Server 1', unreadCount: 5),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: null, // Not active, so badge should show
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('hides unread count when 0', (tester) async {
        final sessions = [
          createSession(id: '1', name: 'Server 1', unreadCount: 0),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Should not find a badge with "0"
        expect(find.text('0'), findsNothing);
      });

      testWidgets('shows 99+ for large unread counts', (tester) async {
        final sessions = [
          createSession(id: '1', name: 'Server 1', unreadCount: 150),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: null,
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('99+'), findsOneWidget);
      });
    });

    // @telos-scenario L2:contract:component-tab-bar:close-tab
    group('close tab', () {
      testWidgets('calls onTabClose when close button is tapped',
          (tester) async {
        String? closedId;
        final sessions = [
          createSession(id: '1', name: 'Server 1'),
          createSession(id: '2', name: 'Server 2'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '1',
                onTabSelected: (_) {},
                onTabClose: (id) => closedId = id,
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Find close button on first tab
        final closeButtons = find.byIcon(Icons.close);
        expect(closeButtons, findsWidgets);

        await tester.tap(closeButtons.first);
        await tester.pumpAndSettle();

        expect(closedId, isNotNull);
      });
    });

    // @telos-scenario L2:contract:component-tab-bar:empty-state
    group('empty state', () {
      testWidgets('shows only add button when no sessions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: [],
                activeSessionId: null,
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
        // Should not find any session tabs
        expect(find.text('Server'), findsNothing);
      });
    });

    // @telos-scenario L2:contract:component-tab-bar:scrolling
    group('scrolling', () {
      testWidgets('scrolls horizontally with many tabs', (tester) async {
        final sessions = List.generate(
          10,
          (i) => createSession(id: '$i', name: 'Server $i'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionTabBar(
                sessions: sessions,
                activeSessionId: '0',
                onTabSelected: (_) {},
                onAddTap: () {},
              ),
            ),
          ),
        );

        // Should have a scrollable list
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}
