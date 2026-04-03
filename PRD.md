# Bento - Product Requirements Document

**Version:** 1.0\
**Last Updated:** February 4, 2026\
**Status:** Draft for Development\
**Document Owner:** Product Team

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Goals](#2-product-vision--goals)
3. [Target Users & Use Cases](#3-target-users--use-cases)
4. [Technical Architecture](#4-technical-architecture)
5. [Core Features](#5-core-features)
6. [AI Integration Architecture](#6-ai-integration-architecture)
7. [Security Model](#7-security-model)
8. [UX/Interaction Design](#8-uxinteraction-design)
9. [Data Model](#9-data-model)
10. [Success Metrics](#10-success-metrics)
11. [MVP Scope (Phase 1)](#11-mvp-scope-phase-1)
12. [Future Roadmap](#12-future-roadmap)
13. [Open Source Considerations](#13-open-source-considerations)
14. [Appendix](#14-appendix)

---

## 1. Executive Summary

**Bento** is a next-generation mobile terminal application that transforms the
traditional "teletype-on-glass" experience into an organized, intuitive, and
powerful interface for developers on the go. The name references the Japanese
bento box - a meal organized into discrete, digestible compartments - reflecting
our core UI paradigm of **Semantic Blocks**.

### The Problem

Current mobile terminal applications suffer from:

- **Input friction**: Physical keyboards designed for desktop don't translate to
  touch
- **Visual chaos**: Scrolling walls of text with no structure or navigation
- **Connection fragility**: SSH sessions drop on network changes, losing context
- **Cognitive overload**: No assistance for complex command syntax or error
  resolution

### The Solution

Bento addresses these challenges through:

- **Semantic Block Interface**: Every command and its output is a discrete,
  collapsible, searchable unit
- **Context-Aware Input**: Predictive ribbons, gesture-based modifiers, and
  AI-powered suggestions
- **Resilient Connectivity**: Mosh-first architecture that survives network
  transitions
- **AI Ghostwriter**: Local-first intelligence for command generation, error
  healing, and output summarization

### Key Differentiators

| Feature        | Traditional Mobile Terminals  | Bento                                  |
| -------------- | ----------------------------- | -------------------------------------- |
| Output Display | Continuous scroll             | Semantic Blocks with collapse/expand   |
| Command Input  | Basic keyboard                | Predictive ribbons + gesture modifiers |
| Connection     | SSH (drops on network change) | Mosh primary (survives roaming)        |
| History        | Basic scrollback              | Searchable, persistent SQLite database |
| AI Assistance  | None or cloud-only            | Hybrid local/cloud with user choice    |
| Monitoring     | Raw TUI output                | Auto-widgetized native charts          |

### Business Model

- **Open Source**: Core application under MIT license
- **Sustainability**: GitHub Sponsors, Open Collective donations
- **No Premium Tier**: All features available to all users

### Timeline

- **Phase 1 (MVP)**: Months 1-4 - Core terminal, blocks, basic connectivity
- **Phase 2**: Months 5-7 - AI integration, dashboard overlay, SFTP
- **Phase 3**: Months 8-10 - Polish, performance, advanced features
- **Phase 4**: Months 11-12 - Beta testing, community feedback, v1.0 release

---

## 2. Product Vision & Goals

### Vision Statement

> Enable developers to be genuinely productive on mobile devices by reimagining
> the terminal as a structured, intelligent, and resilient interface that adapts
> to touch-first interaction.

### Primary Goals

1. **Eliminate Input Friction**
   - Reduce keystrokes by 50% through predictive suggestions and AI assistance
   - Provide desktop-equivalent precision through gesture-based cursor control
   - Support voice input for hands-free scenarios

2. **Structure the Chaos**
   - Transform continuous output streams into navigable, searchable blocks
   - Auto-summarize verbose output while preserving full detail on demand
   - Enable instant navigation to any historical command or output

3. **Ensure Connection Resilience**
   - Maintain sessions through Wi-Fi/cellular transitions
   - Provide immediate visual feedback despite network latency
   - Support offline command composition and history browsing

4. **Augment with Intelligence**
   - Convert natural language to CLI commands
   - Offer one-tap error resolution
   - Summarize complex output into actionable insights

### Secondary Goals

1. **Performance Excellence**
   - Achieve 60fps rendering on mid-range devices (2023+)
   - Keystroke-to-render latency under 50ms on 4G networks
   - App launch to usable terminal under 2 seconds

2. **Accessibility**
   - Full VoiceOver/TalkBack support
   - Configurable font sizes and color schemes
   - High contrast mode for outdoor use

3. **Community Building**
   - Foster active open-source contributor community
   - Establish plugin/extension architecture for future expansion
   - Create comprehensive documentation and tutorials

### Non-Goals (Explicit Exclusions)

- **Desktop Application**: Focus exclusively on mobile for v1.0
- **IDE Features**: No code editing, syntax highlighting for files, or project
  management
- **Container Orchestration UI**: No Kubernetes dashboards or Docker management
  GUIs
- **Team Collaboration**: No shared sessions or team features in v1.0

---

## 3. Target Users & Use Cases

### Primary Personas

#### Persona 1: The On-Call Engineer

**Name:** Sarah Chen\
**Role:** Site Reliability Engineer\
**Context:** Receives alerts while away from desk, needs to quickly diagnose and
resolve issues

**Pain Points:**

- Current mobile terminals make it hard to navigate log output
- SSH sessions drop when moving between networks
- Typing complex kubectl commands on phone is error-prone

**Jobs to Be Done:**

- Quickly SSH into production servers during incidents
- Navigate and search through log files efficiently
- Execute memorized runbook commands without typos

**Success Criteria:**

- Can resolve P1 incidents from phone as effectively as laptop
- Session survives commute from home to office
- Command snippets eliminate typing errors in critical moments

#### Persona 2: The Homelab Enthusiast

**Name:** Marcus Rodriguez\
**Role:** Software Developer (hobbyist sysadmin)\
**Context:** Manages personal servers, NAS, and smart home infrastructure

**Pain Points:**

- Juggling multiple SSH sessions to different home devices
- Remembering syntax for infrequently-used commands
- Monitoring system health requires multiple commands

**Jobs to Be Done:**

- Check on homelab status from anywhere
- Quickly restart services or update containers
- Monitor resource usage across multiple machines

**Success Criteria:**

- Tailscale integration shows all home devices automatically
- Saved snippets for common maintenance tasks
- Dashboard view shows system health at a glance

#### Persona 3: The Cloud Developer

**Name:** Priya Sharma\
**Role:** Full-Stack Developer\
**Context:** Works with cloud infrastructure, deploys from various locations

**Pain Points:**

- AWS/GCP CLI commands are verbose and complex
- Needs to check deployment status while traveling
- Error messages are cryptic and require googling

**Jobs to Be Done:**

- Deploy and monitor cloud applications
- Debug failed deployments quickly
- Manage multiple cloud environments

**Success Criteria:**

- AI suggests correct AWS CLI syntax from natural language
- One-tap error healing for common deployment failures
- Session tabs for dev/staging/prod environments

### Use Cases

#### UC-1: Incident Response

```
GIVEN Sarah receives a PagerDuty alert on her phone
WHEN she opens Bento and taps her "prod-web-01" saved connection
THEN she connects via Mosh within 3 seconds
AND her previous session context is restored
AND she can search blocks for recent error patterns
```

#### UC-2: Quick Health Check

```
GIVEN Marcus wants to check his homelab status
WHEN he opens Bento and runs "htop" on his server
THEN the TUI output is auto-widgetized into native charts
AND he can see CPU/memory trends without parsing ASCII
AND the view updates in real-time
```

#### UC-3: Command Assistance

```
GIVEN Priya needs to list S3 buckets with specific tags
WHEN she types "show s3 buckets tagged with env=prod" in AI mode
THEN Bento suggests: aws s3api list-buckets --query "..."
AND she can edit, approve, or regenerate the suggestion
AND the command is added to her history for future use
```

#### UC-4: Error Recovery

```
GIVEN a deployment command fails with a permission error
WHEN Bento detects the error pattern in stderr
THEN it offers a "Heal" button with suggested fix
AND the fix is explained before execution
AND successful resolution is logged for learning
```

#### UC-5: Offline Preparation

```
GIVEN the user is on a flight without connectivity
WHEN they open Bento
THEN they can browse full command history
AND compose commands in draft mode
AND review saved snippets and documentation
AND commands queue for execution on reconnection
```

---

## 4. Technical Architecture

### 4.1 Technology Stack Overview

```
+------------------------------------------------------------------+
|                        BENTO APPLICATION                          |
+------------------------------------------------------------------+
|                                                                    |
|  +------------------------+    +-----------------------------+    |
|  |    PRESENTATION        |    |      STATE MANAGEMENT       |    |
|  |------------------------|    |-----------------------------|    |
|  | Flutter Widgets        |    | Riverpod Providers          |    |
|  | xterm Terminal View    |    | AsyncNotifier for async ops |    |
|  | fl_chart Dashboards    |    | StateNotifier for UI state  |    |
|  | Custom Block Widgets   |    | Family providers for params |    |
|  +------------------------+    +-----------------------------+    |
|                                                                    |
|  +------------------------+    +-----------------------------+    |
|  |    NAVIGATION          |    |      BUSINESS LOGIC         |    |
|  |------------------------|    |-----------------------------|    |
|  | go_router              |    | Session Manager             |    |
|  | Deep linking support   |    | Block Parser                |    |
|  | Tab management         |    | AI Gateway                  |    |
|  | Modal routes           |    | Command Predictor           |    |
|  +------------------------+    +-----------------------------+    |
|                                                                    |
|  +------------------------+    +-----------------------------+    |
|  |    CONNECTIVITY        |    |      DATA PERSISTENCE       |    |
|  |------------------------|    |-----------------------------|    |
|  | dartssh2 (SSH/SFTP)    |    | Drift (SQLite)              |    |
|  | Mosh client (FFI)      |    | flutter_secure_storage      |    |
|  | Tailscale query        |    | Hive (fast KV cache)        |    |
|  +------------------------+    +-----------------------------+    |
|                                                                    |
|  +------------------------+    +-----------------------------+    |
|  |    AI LAYER            |    |      PLATFORM SERVICES      |    |
|  |------------------------|    |-----------------------------|    |
|  | Local LLM (GGML)       |    | local_auth (biometrics)     |    |
|  | Cloud API clients      |    | speech_to_text              |    |
|  | Prompt templates       |    | flutter_haptic_feedback     |    |
|  | Response parsers       |    | url_launcher                |    |
|  +------------------------+    +-----------------------------+    |
|                                                                    |
+------------------------------------------------------------------+
|                     FLUTTER FRAMEWORK                              |
|                     Impeller Rendering Engine                      |
+------------------------------------------------------------------+
|                     iOS / Android Platform                         |
+------------------------------------------------------------------+
```

### 4.2 Package Dependencies

```yaml
# pubspec.yaml - Core Dependencies

name: bento
description: Next-generation mobile terminal with semantic blocks
version: 1.0.0+1
publish_to: none

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter

  # Terminal Emulation
  xterm: ^4.0.0 # GPU-accelerated terminal, 60fps mobile-optimized

  # SSH/SFTP Connectivity
  dartssh2: ^2.13.0 # Pure Dart SSH2/SFTP implementation

  # State Management
  flutter_riverpod: ^3.2.1 # Async-first state management
  riverpod_annotation: ^2.5.0 # Code generation for providers

  # Navigation
  go_router: ^17.1.0 # Declarative routing with deep links

  # Data Persistence
  drift: ^2.18.0 # Type-safe SQLite with migrations
  sqlite3_flutter_libs: ^0.5.24 # SQLite binaries for mobile
  hive_flutter: ^1.1.0 # Fast key-value storage for cache

  # Security
  flutter_secure_storage: ^10.0.0 # Encrypted credential storage
  local_auth: ^3.0.0 # Biometric authentication
  cryptography: ^2.7.0 # AES-256 encryption utilities

  # UI Components
  fl_chart: ^1.1.1 # Native charts for dashboard
  flutter_svg: ^2.0.10 # SVG icon support
  shimmer: ^3.0.0 # Loading state animations

  # Input & Interaction
  speech_to_text: ^7.3.0 # Voice command input
  flutter_haptic_feedback: ^0.1.0 # Tactile feedback patterns

  # Functional Programming
  fpdart: ^1.2.0 # Option/Either for error handling

  # Utilities
  uuid: ^4.4.0 # Unique identifiers
  intl: ^0.19.0 # Internationalization
  logger: ^2.3.0 # Structured logging
  collection: ^1.18.0 # Enhanced collections
  equatable: ^2.0.5 # Value equality
  freezed_annotation: ^2.4.1 # Immutable data classes
  json_annotation: ^4.9.0 # JSON serialization

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.9
  riverpod_generator: ^2.6.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  drift_dev: ^2.18.0

  # Testing
  mocktail: ^1.0.3
  golden_toolkit: ^0.15.0

  # Linting
  flutter_lints: ^4.0.0
  custom_lint: ^0.6.4

flutter:
  uses-material-design: true

  assets:
    - assets/icons/
    - assets/fonts/
    - assets/models/ # Local LLM model files

  fonts:
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
```

### 4.3 Architecture Patterns

#### Clean Architecture Layers

```
lib/
├── main.dart                       # App entry point
├── app/
│   ├── app.dart                    # MaterialApp configuration
│   ├── router.dart                 # go_router configuration
│   └── theme.dart                  # Theme definitions
│
├── core/                           # Shared utilities
│   ├── constants/
│   ├── errors/
│   │   ├── failures.dart           # Failure types (fpdart)
│   │   └── exceptions.dart
│   ├── extensions/
│   ├── utils/
│   └── di/                         # Dependency injection
│       └── providers.dart          # Global Riverpod providers
│
├── features/
│   ├── terminal/                   # Terminal feature module
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── ssh_datasource.dart
│   │   │   │   └── mosh_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── block_model.dart
│   │   │   │   └── session_model.dart
│   │   │   └── repositories/
│   │   │       └── terminal_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── block.dart
│   │   │   │   └── session.dart
│   │   │   ├── repositories/
│   │   │   │   └── terminal_repository.dart
│   │   │   └── usecases/
│   │   │       ├── execute_command.dart
│   │   │       └── connect_session.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── terminal_provider.dart
│   │       │   └── block_provider.dart
│   │       ├── screens/
│   │       │   └── terminal_screen.dart
│   │       └── widgets/
│   │           ├── block_widget.dart
│   │           ├── command_ribbon.dart
│   │           └── modifier_drawer.dart
│   │
│   ├── connections/                # Connection management
│   ├── ai/                         # AI Ghostwriter
│   ├── dashboard/                  # Visual dashboard overlay
│   ├── sftp/                       # File transfer
│   ├── snippets/                   # Command templates
│   └── settings/                   # App configuration
│
├── shared/                         # Shared widgets/utilities
│   ├── widgets/
│   └── services/
│
└── database/                       # Drift database
    ├── database.dart
    ├── tables/
    └── daos/
```

#### State Management with Riverpod

```dart
// Example: Terminal Session Provider

@riverpod
class TerminalSession extends _$TerminalSession {
  @override
  FutureOr<Session> build(String sessionId) async {
    final repository = ref.watch(terminalRepositoryProvider);
    return repository.getSession(sessionId);
  }
  
  Future<void> executeCommand(String command) async {
    final session = await future;
    state = const AsyncLoading();
    
    final result = await ref
        .read(executeCommandUseCaseProvider)
        .call(ExecuteCommandParams(
          sessionId: session.id,
          command: command,
        ));
    
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (block) {
        ref.read(blockListProvider(session.id).notifier).addBlock(block);
        state = AsyncData(session);
      },
    );
  }
}

@riverpod
class BlockList extends _$BlockList {
  @override
  List<Block> build(String sessionId) {
    // Load blocks from database on init
    _loadBlocks(sessionId);
    return [];
  }
  
  Future<void> _loadBlocks(String sessionId) async {
    final blocks = await ref
        .read(blockRepositoryProvider)
        .getBlocksForSession(sessionId);
    state = blocks;
  }
  
  void addBlock(Block block) {
    state = [...state, block];
    // Persist to database
    ref.read(blockRepositoryProvider).saveBlock(block);
  }
}
```

### 4.4 Connectivity Architecture

#### Protocol Selection Logic

```dart
enum ConnectionProtocol { mosh, ssh, et }

class ConnectionManager {
  /// Determines optimal protocol based on conditions
  ConnectionProtocol selectProtocol({
    required HostConfig host,
    required NetworkConditions network,
  }) {
    // 1. Check if Mosh is available on server
    if (host.moshSupported && network.isUnstable) {
      return ConnectionProtocol.mosh;
    }
    
    // 2. Check if Eternal Terminal is preferred for scrollback
    if (host.etSupported && host.preferNativeScrollback) {
      return ConnectionProtocol.et;
    }
    
    // 3. Default to SSH
    return ConnectionProtocol.ssh;
  }
}
```

#### Mosh Integration via FFI

```dart
// Mosh requires native code integration
// We'll use platform channels + precompiled Mosh libraries

class MoshClient {
  static const _channel = MethodChannel('dev.bento/mosh');
  
  Future<MoshSession> connect({
    required String host,
    required int port,
    required String user,
    required String privateKey,
  }) async {
    final result = await _channel.invokeMethod('connect', {
      'host': host,
      'port': port,
      'user': user,
      'privateKey': privateKey,
    });
    
    return MoshSession.fromMap(result);
  }
  
  Stream<Uint8List> get outputStream {
    return _channel
        .receiveBroadcastStream('output')
        .map((data) => data as Uint8List);
  }
  
  Future<void> sendInput(String input) async {
    await _channel.invokeMethod('input', {'data': input});
  }
}
```

#### SSH Implementation with dartssh2

```dart
class SSHClient {
  SSHClient? _client;
  SSHSession? _session;
  
  Future<Either<Failure, void>> connect({
    required String host,
    required int port,
    required String username,
    required String privateKey,
    String? passphrase,
  }) async {
    try {
      _client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        identities: [
          SSHKeyPair.fromPem(privateKey, passphrase),
        ],
      );
      
      _session = await _client!.shell(
        pty: SSHPtyConfig(
          width: 80,
          height: 24,
        ),
      );
      
      return const Right(null);
    } on SSHAuthFailure catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on SocketException catch (e) {
      return Left(ConnectionFailure(e.message));
    }
  }
  
  Stream<String> get stdout => _session!.stdout
      .transform(utf8.decoder);
  
  Stream<String> get stderr => _session!.stderr
      .transform(utf8.decoder);
  
  void write(String data) {
    _session?.stdin.add(utf8.encode(data));
  }
}
```

### 4.5 Tailscale Integration

```dart
/// Queries installed Tailscale app for node list
class TailscaleService {
  static const _channel = MethodChannel('dev.bento/tailscale');
  
  /// Check if Tailscale is installed and accessible
  Future<bool> get isAvailable async {
    try {
      return await _channel.invokeMethod('isAvailable');
    } catch (_) {
      return false;
    }
  }
  
  /// Get list of Tailscale nodes
  Future<Either<Failure, List<TailscaleNode>>> getNodes() async {
    try {
      final result = await _channel.invokeMethod('getNodes');
      final nodes = (result as List)
          .map((n) => TailscaleNode.fromMap(n))
          .toList();
      return Right(nodes);
    } on PlatformException catch (e) {
      return Left(TailscaleFailure(e.message ?? 'Unknown error'));
    }
  }
}

@freezed
class TailscaleNode with _$TailscaleNode {
  const factory TailscaleNode({
    required String id,
    required String name,
    required String ipv4,
    required String ipv6,
    required bool online,
    required String os,
    String? hostname,
  }) = _TailscaleNode;
}
```

---

## 5. Core Features

### 5.1 Semantic Block Interface

#### Overview

The Semantic Block Interface is Bento's core differentiator. Every command
execution creates a discrete, self-contained block that can be collapsed,
expanded, searched, and navigated independently.

#### Block Anatomy

```
┌─────────────────────────────────────────────────────────────┐
│ [>] $ kubectl get pods -n production          [Copy] [...]  │
│     ┌─ Status: Success (0) ─────── 2.3s ─── 14:32:05 ──┐   │
├─────┴──────────────────────────────────────────────────┴────┤
│ NAME                    READY   STATUS    RESTARTS   AGE    │
│ api-server-7d4f9-abc    1/1     Running   0          3d     │
│ worker-5c8b2-def        1/1     Running   2          3d     │
│ redis-cache-xyz         1/1     Running   0          5d     │
│                                                              │
│ [AI Summary: 3 pods running in production, all healthy]     │
├──────────────────────────────────────────────────────────────┤
│ [Collapse] [Search] [Copy All] [Share] [Pin]                │
└──────────────────────────────────────────────────────────────┘
```

#### Block States

| State     | Visual Indicator    | Behavior                                   |
| --------- | ------------------- | ------------------------------------------ |
| Running   | Pulsing blue border | Output streams in real-time, block expands |
| Success   | Green left border   | Exit code 0, can collapse                  |
| Failed    | Red left border     | Non-zero exit, "Heal" button appears       |
| Cancelled | Yellow left border  | User interrupted (Ctrl+C)                  |
| Collapsed | Chevron right       | Shows command + summary only               |
| Expanded  | Chevron down        | Full output visible                        |
| Pinned    | Pin icon            | Stays visible at top of session            |

#### User Stories

##### US-5.1.1: Block Creation

**As a** user executing a command\
**I want** the output to appear in a discrete block\
**So that** I can distinguish it from other commands

**Acceptance Criteria:**

- Given I type a command and press Enter
- When the command begins executing
- Then a new block is created with "Running" state
- And the command text is shown in the block header
- And a timestamp is recorded

##### US-5.1.2: Block Collapse/Expand

**As a** user reviewing command history\
**I want to** collapse verbose output blocks\
**So that** I can see more commands on screen

**Acceptance Criteria:**

- Given a block is in expanded state
- When I tap the collapse button or swipe left on the block
- Then the output is hidden
- And only the command and summary are visible
- And the block height animates smoothly to collapsed size

##### US-5.1.3: Block Search

**As a** user looking for specific output\
**I want to** search within a block\
**So that** I can find relevant information quickly

**Acceptance Criteria:**

- Given a block with substantial output
- When I tap the search icon and enter a query
- Then matching text is highlighted
- And I can navigate between matches with up/down arrows
- And the match count is displayed

##### US-5.1.4: Tappable Elements

**As a** user viewing command output\
**I want** interactive elements to be tappable\
**So that** I can take action on them directly

**Acceptance Criteria:**

- Given output contains an IP address (e.g., 192.168.1.100)
- When I tap on the IP address
- Then a context menu appears with options:
  - Copy to clipboard
  - SSH to this host
  - Ping this host
  - Add to connections

- Given output contains a file path (e.g., /var/log/syslog)
- When I tap on the file path
- Then a context menu appears with options:
  - Copy path
  - View file (cat)
  - Edit file (nano/vim)
  - Download via SFTP

- Given output contains JSON
- When I tap on the JSON block
- Then it expands into a formatted, navigable tree view

##### US-5.1.5: Auto-Summarization

**As a** user running verbose commands\
**I want** automatic summaries of long output\
**So that** I can quickly understand the result

**Acceptance Criteria:**

- Given a command produces more than 20 lines of output
- When the command completes
- Then an AI-generated summary appears below the header
- And the summary is 1-2 sentences maximum
- And tapping the summary expands full output

#### Technical Specification

```dart
@freezed
class Block with _$Block {
  const factory Block({
    required String id,
    required String sessionId,
    required String command,
    required DateTime timestamp,
    required BlockStatus status,
    required String output,
    String? stderr,
    int? exitCode,
    Duration? executionTime,
    String? aiSummary,
    @Default(false) bool isPinned,
    @Default(false) bool isCollapsed,
    List<TappableElement>? tappableElements,
  }) = _Block;
}

enum BlockStatus { running, success, failed, cancelled }

@freezed
class TappableElement with _$TappableElement {
  const factory TappableElement({
    required TappableType type,
    required String value,
    required int startOffset,
    required int endOffset,
  }) = _TappableElement;
}

enum TappableType { ipAddress, filePath, url, json, email, uuid }
```

#### Block Parser Implementation

```dart
class BlockParser {
  static final _patterns = {
    TappableType.ipAddress: RegExp(
      r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
    ),
    TappableType.filePath: RegExp(
      r'(?:^|[\s"])(/(?:[^/\s"]+/)*[^/\s"]+)'
    ),
    TappableType.url: RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+'
    ),
    TappableType.json: RegExp(
      r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}'
    ),
  };
  
  List<TappableElement> parse(String output) {
    final elements = <TappableElement>[];
    
    for (final entry in _patterns.entries) {
      for (final match in entry.value.allMatches(output)) {
        elements.add(TappableElement(
          type: entry.key,
          value: match.group(0)!,
          startOffset: match.start,
          endOffset: match.end,
        ));
      }
    }
    
    return elements..sort((a, b) => a.startOffset.compareTo(b.startOffset));
  }
}
```

---

### 5.2 Context-Aware Command Ribbons

#### Overview

The Command Ribbon is a horizontal, scrollable strip positioned above the
keyboard that provides intelligent command completion, common symbols, and quick
actions based on context.

#### Ribbon Modes

```
┌─────────────────────────────────────────────────────────────┐
│ MODE: IDLE (no input)                                        │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│ │ ls │ │ cd │ │ cat│ │grep│ │sudo│ │ .. │ │ AI │ │ +  │    │
│ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘    │
│ [Recent commands based on session history]                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ MODE: TYPING "kube"                                          │
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐     │
│ │kubectl │ │kubectx │ │kubens  │ │kubeadm │ │kubelet │     │
│ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘     │
│ [Completions from PATH + history]                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ MODE: AFTER "kubectl " (space after command)                 │
│ ┌────┐ ┌─────┐ ┌──────┐ ┌────────┐ ┌─────┐ ┌──────┐       │
│ │get │ │apply│ │delete│ │describe│ │logs │ │exec  │       │
│ └────┘ └─────┘ └──────┘ └────────┘ └─────┘ └──────┘       │
│ [Subcommand completions for kubectl]                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ MODE: AFTER "kubectl get " (expecting resource type)         │
│ ┌─────┐ ┌────────┐ ┌────────┐ ┌─────┐ ┌───────┐ ┌─────┐   │
│ │pods │ │services│ │deploymt│ │nodes│ │secrets│ │ all │   │
│ └─────┘ └────────┘ └────────┘ └─────┘ └───────┘ └─────┘   │
│ [Resource type completions]                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ MODE: SYMBOLS (long-press on ribbon)                         │
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐    │
│ │ | │ │ > │ │ < │ │ & │ │ ; │ │ $ │ │ ~ │ │ / │ │ \ │    │
│ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘    │
│ [Common shell symbols]                                       │
└─────────────────────────────────────────────────────────────┘
```

#### User Stories

##### US-5.2.1: Predictive Suggestions

**As a** user starting to type a command\
**I want** relevant completions to appear\
**So that** I can select instead of typing fully

**Acceptance Criteria:**

- Given I have typed "gi"
- When the ribbon updates
- Then I see suggestions: "git", "gzip", "gimp" (based on PATH)
- And suggestions are ordered by frequency of use
- And tapping a suggestion inserts it

##### US-5.2.2: Subcommand Completion

**As a** user who has typed a command with subcommands\
**I want** subcommand suggestions\
**So that** I don't need to remember syntax

**Acceptance Criteria:**

- Given I have typed "docker " (with trailing space)
- When the ribbon updates
- Then I see: "run", "ps", "images", "build", "compose"
- And these are the most common docker subcommands
- And tapping inserts with a trailing space

##### US-5.2.3: History-Based Prediction

**As a** user with established patterns\
**I want** suggestions based on my history\
**So that** I can quickly repeat common workflows

**Acceptance Criteria:**

- Given I frequently run "kubectl get pods -n production" after "kubectl get
  nodes"
- When I complete "kubectl get nodes"
- Then "kubectl get pods -n production" appears as a suggestion
- And it's marked with a history icon

##### US-5.2.4: Symbol Quick Access

**As a** user needing shell symbols\
**I want** quick access to |, >, <, &, etc.\
**So that** I don't need to switch keyboard layouts

**Acceptance Criteria:**

- Given I long-press on the ribbon area
- When the symbol tray appears
- Then I see common symbols: | > < & ; $ ~ / \ " ' ` ( ) [ ] { }
- And tapping inserts the symbol at cursor
- And the tray dismisses after selection

#### Technical Specification

```dart
@riverpod
class CommandRibbon extends _$CommandRibbon {
  @override
  RibbonState build(String sessionId) {
    return RibbonState.idle(
      suggestions: _getIdleSuggestions(sessionId),
    );
  }
  
  void onInputChanged(String input) {
    if (input.isEmpty) {
      state = RibbonState.idle(
        suggestions: _getIdleSuggestions(state.sessionId),
      );
      return;
    }
    
    final parts = input.split(' ');
    final command = parts.first;
    
    if (parts.length == 1) {
      // Completing command name
      state = RibbonState.completing(
        suggestions: _getCommandCompletions(command),
      );
    } else {
      // Completing arguments
      state = RibbonState.completing(
        suggestions: _getArgumentCompletions(command, parts.sublist(1)),
      );
    }
  }
  
  List<Suggestion> _getCommandCompletions(String prefix) {
    final historyCommands = ref
        .read(commandHistoryProvider)
        .where((cmd) => cmd.startsWith(prefix))
        .take(5);
    
    final pathCommands = ref
        .read(pathCommandsProvider)
        .where((cmd) => cmd.startsWith(prefix))
        .take(10);
    
    return [
      ...historyCommands.map((c) => Suggestion.history(c)),
      ...pathCommands.map((c) => Suggestion.path(c)),
    ];
  }
}

@freezed
class RibbonState with _$RibbonState {
  const factory RibbonState.idle({
    required List<Suggestion> suggestions,
  }) = _Idle;
  
  const factory RibbonState.completing({
    required List<Suggestion> suggestions,
  }) = _Completing;
  
  const factory RibbonState.symbols() = _Symbols;
}

@freezed
class Suggestion with _$Suggestion {
  const factory Suggestion.history(String command) = _HistorySuggestion;
  const factory Suggestion.path(String command) = _PathSuggestion;
  const factory Suggestion.subcommand(String subcommand) = _SubcommandSuggestion;
  const factory Suggestion.argument(String argument) = _ArgumentSuggestion;
  const factory Suggestion.snippet(Snippet snippet) = _SnippetSuggestion;
}
```

#### Command Knowledge Base

```dart
/// Built-in knowledge of common command structures
class CommandKnowledge {
  static const Map<String, List<String>> subcommands = {
    'git': ['status', 'add', 'commit', 'push', 'pull', 'checkout', 'branch', 'merge', 'rebase', 'log', 'diff', 'stash'],
    'docker': ['run', 'ps', 'images', 'build', 'compose', 'exec', 'logs', 'stop', 'rm', 'pull', 'push'],
    'kubectl': ['get', 'apply', 'delete', 'describe', 'logs', 'exec', 'port-forward', 'scale', 'rollout'],
    'npm': ['install', 'run', 'start', 'test', 'build', 'publish', 'init', 'update', 'audit'],
    'systemctl': ['start', 'stop', 'restart', 'status', 'enable', 'disable', 'daemon-reload'],
    'aws': ['s3', 'ec2', 'ecs', 'lambda', 'iam', 'cloudformation', 'logs', 'ssm'],
    // ... more commands
  };
  
  static const Map<String, Map<String, List<String>>> nestedSubcommands = {
    'kubectl': {
      'get': ['pods', 'services', 'deployments', 'nodes', 'namespaces', 'secrets', 'configmaps', 'ingress'],
      'describe': ['pod', 'service', 'deployment', 'node', 'namespace'],
    },
    'docker': {
      'compose': ['up', 'down', 'ps', 'logs', 'build', 'pull', 'restart'],
    },
    'aws': {
      's3': ['ls', 'cp', 'mv', 'rm', 'sync', 'mb', 'rb'],
      'ec2': ['describe-instances', 'start-instances', 'stop-instances', 'terminate-instances'],
    },
  };
}
```

---

### 5.3 Modifier Drawer

#### Overview

The Modifier Drawer provides access to special keys (Ctrl, Alt, Esc, Tab, Arrow
keys) through a gesture-activated panel, eliminating the need for awkward
keyboard combinations on touch devices.

#### Drawer Layout

```
┌─────────────────────────────────────────────────────────────┐
│                    MODIFIER DRAWER                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ Esc  │  │ Tab  │  │ Ctrl │  │ Alt  │  │ Fn   │          │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘          │
│                                                              │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │  ↑   │  │  ↓   │  │  ←   │  │  →   │  │ Home │          │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘          │
│                                                              │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ End  │  │ PgUp │  │ PgDn │  │ Ins  │  │ Del  │          │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘          │
│                                                              │
│  COMBOS: [Ctrl+C] [Ctrl+D] [Ctrl+Z] [Ctrl+L] [Ctrl+R]      │
└─────────────────────────────────────────────────────────────┘
```

#### Gesture Mappings (User Configurable)

| Gesture                | Default Action        | Configurable |
| ---------------------- | --------------------- | ------------ |
| Swipe up from bottom   | Open modifier drawer  | Yes          |
| Swipe down on terminal | Scroll up             | Yes          |
| Swipe left on block    | Collapse block        | Yes          |
| Swipe right on block   | Expand block          | Yes          |
| Two-finger tap         | Paste clipboard       | Yes          |
| Long press on terminal | Select text           | No           |
| Pinch                  | Zoom font size        | Yes          |
| Double-tap spacebar    | Insert period + space | Yes          |

#### User Stories

##### US-5.3.1: Modifier Key Access

**As a** user needing to send Ctrl+C\
**I want** quick access to modifier combinations\
**So that** I can interrupt commands easily

**Acceptance Criteria:**

- Given I swipe up from the bottom of the screen
- When the modifier drawer appears
- Then I see Ctrl, Alt, Esc, and other modifiers
- And tapping Ctrl highlights it as "active"
- And my next keypress sends Ctrl+[key]
- And the modifier auto-releases after the keypress

##### US-5.3.2: Quick Combos

**As a** user who frequently uses Ctrl+C, Ctrl+D\
**I want** one-tap access to common combinations\
**So that** I don't need two taps

**Acceptance Criteria:**

- Given the modifier drawer is open
- When I see the COMBOS row
- Then I can tap "Ctrl+C" to immediately send the combination
- And haptic feedback confirms the action
- And the drawer optionally auto-closes

##### US-5.3.3: Custom Gesture Mapping

**As a** power user\
**I want to** customize gesture actions\
**So that** the app fits my workflow

**Acceptance Criteria:**

- Given I open Settings > Gestures
- When I tap on "Swipe up from bottom"
- Then I can choose from: Open drawer, Paste, Send Ctrl+C, Custom command
- And my choice is persisted
- And the gesture performs my chosen action

#### Technical Specification

```dart
@freezed
class ModifierState with _$ModifierState {
  const factory ModifierState({
    @Default(false) bool ctrlActive,
    @Default(false) bool altActive,
    @Default(false) bool shiftActive,
    @Default(false) bool metaActive,
  }) = _ModifierState;
  
  bool get hasActiveModifier => 
      ctrlActive || altActive || shiftActive || metaActive;
}

@riverpod
class ModifierDrawer extends _$ModifierDrawer {
  @override
  ModifierState build() => const ModifierState();
  
  void toggleCtrl() {
    state = state.copyWith(ctrlActive: !state.ctrlActive);
    _provideHapticFeedback();
  }
  
  void sendCombo(String combo) {
    // Parse combo like "Ctrl+C" and send to terminal
    final parts = combo.split('+');
    final modifiers = parts.sublist(0, parts.length - 1);
    final key = parts.last;
    
    ref.read(terminalInputProvider.notifier).sendKey(
      key: key,
      ctrl: modifiers.contains('Ctrl'),
      alt: modifiers.contains('Alt'),
      shift: modifiers.contains('Shift'),
    );
    
    // Reset modifiers after combo
    state = const ModifierState();
  }
  
  void _provideHapticFeedback() {
    HapticFeedback.mediumImpact();
  }
}
```

---

### 5.4 Visual Dashboard Overlay

#### Overview

The Dashboard Overlay transforms traditional TUI output (htop, top, nvidia-smi)
into native Flutter widgets with charts, progress bars, and real-time updates.

#### Auto-Widgetization Detection

```dart
class WidgetizationDetector {
  static const _tuiCommands = {
    'htop': TuiType.processMonitor,
    'top': TuiType.processMonitor,
    'btop': TuiType.processMonitor,
    'nvidia-smi': TuiType.gpuMonitor,
    'nvtop': TuiType.gpuMonitor,
    'iotop': TuiType.ioMonitor,
    'nethogs': TuiType.networkMonitor,
    'iftop': TuiType.networkMonitor,
    'watch': TuiType.watchCommand,
  };
  
  static TuiType? detect(String command) {
    final baseCommand = command.split(' ').first;
    return _tuiCommands[baseCommand];
  }
}
```

#### Dashboard Views

##### Process Monitor (htop/top replacement)

```
┌─────────────────────────────────────────────────────────────┐
│ SYSTEM OVERVIEW                              [Raw] [Refresh]│
├─────────────────────────────────────────────────────────────┤
│ CPU ████████████░░░░░░░░ 58%    Load: 2.34 1.89 1.56       │
│ MEM ██████████████░░░░░░ 72%    8.2 GB / 16 GB             │
│ SWP ██░░░░░░░░░░░░░░░░░░  8%    0.4 GB / 4 GB              │
├─────────────────────────────────────────────────────────────┤
│ TOP PROCESSES                                                │
│ ┌────────────────────────────────────────────────────────┐  │
│ │ PID    NAME           CPU%   MEM%   USER               │  │
│ │ 1234   node           23.4   4.2    deploy             │  │
│ │ 5678   postgres       12.1   8.7    postgres           │  │
│ │ 9012   nginx           3.2   1.1    www-data           │  │
│ │ 3456   python          2.8   3.4    deploy             │  │
│ └────────────────────────────────────────────────────────┘  │
│                                                              │
│ [Kill] [Nice] [Filter] [Sort: CPU ▼]                        │
└─────────────────────────────────────────────────────────────┘
```

##### GPU Monitor (nvidia-smi replacement)

```
┌─────────────────────────────────────────────────────────────┐
│ GPU 0: NVIDIA RTX 4090                       [Raw] [Refresh]│
├─────────────────────────────────────────────────────────────┤
│ Utilization  ████████████████░░░░ 78%                       │
│ Memory       ██████████████░░░░░░ 18.2 GB / 24 GB           │
│ Temperature  ████████░░░░░░░░░░░░ 67°C                      │
│ Power        ██████████████░░░░░░ 285W / 350W               │
├─────────────────────────────────────────────────────────────┤
│ PROCESSES                                                    │
│ │ PID    NAME              MEM      │                       │
│ │ 12345  python (train.py) 14.2 GB  │                       │
│ │ 12346  python (infer.py)  3.8 GB  │                       │
└─────────────────────────────────────────────────────────────┘
```

#### Client-Side Command Parsers

For non-TUI commands, Bento includes Dart parsers that convert text output to
structured data:

```dart
/// Parser registry for common commands
class OutputParserRegistry {
  static final Map<String, OutputParser> _parsers = {
    'df': DfParser(),
    'ps': PsParser(),
    'netstat': NetstatParser(),
    'ls': LsParser(),
    'free': FreeParser(),
    'uptime': UptimeParser(),
    'who': WhoParser(),
    'lsblk': LsblkParser(),
  };
  
  static OutputParser? getParser(String command) {
    final baseCommand = command.split(' ').first;
    return _parsers[baseCommand];
  }
}

/// Example: df parser
class DfParser implements OutputParser<List<DiskUsage>> {
  @override
  List<DiskUsage> parse(String output) {
    final lines = output.split('\n').skip(1); // Skip header
    return lines.where((l) => l.isNotEmpty).map((line) {
      final parts = line.split(RegExp(r'\s+'));
      return DiskUsage(
        filesystem: parts[0],
        size: _parseSize(parts[1]),
        used: _parseSize(parts[2]),
        available: _parseSize(parts[3]),
        usePercent: int.parse(parts[4].replaceAll('%', '')),
        mountPoint: parts[5],
      );
    }).toList();
  }
  
  int _parseSize(String size) {
    // Parse sizes like "100G", "50M", "1T"
    final match = RegExp(r'(\d+)([KMGT]?)').firstMatch(size);
    if (match == null) return 0;
    
    final value = int.parse(match.group(1)!);
    final unit = match.group(2) ?? '';
    
    return switch (unit) {
      'K' => value * 1024,
      'M' => value * 1024 * 1024,
      'G' => value * 1024 * 1024 * 1024,
      'T' => value * 1024 * 1024 * 1024 * 1024,
      _ => value,
    };
  }
}

@freezed
class DiskUsage with _$DiskUsage {
  const factory DiskUsage({
    required String filesystem,
    required int size,
    required int used,
    required int available,
    required int usePercent,
    required String mountPoint,
  }) = _DiskUsage;
}
```

#### User Stories

##### US-5.4.1: Auto-Widgetization

**As a** user running htop\
**I want** native chart visualization\
**So that** I can monitor without ASCII art

**Acceptance Criteria:**

- Given I run "htop" in a session
- When Bento detects the TUI command
- Then it offers "View as Dashboard" option
- And selecting it shows native Flutter charts
- And data updates in real-time
- And I can switch back to raw terminal view

##### US-5.4.2: Parsed Command Output

**As a** user running "df -h"\
**I want** visual disk usage bars\
**So that** I can quickly see disk status

**Acceptance Criteria:**

- Given I run "df -h"
- When the output is received
- Then Bento parses it into structured data
- And displays horizontal progress bars for each mount
- And color-codes based on usage (green < 70%, yellow < 90%, red >= 90%)

---

### 5.5 Session Management

#### Overview

Bento supports multiple concurrent sessions organized in tabs, with full
persistence and quick switching.

#### Session Tab Bar

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───┐                  │
│ │●prod-web│ │○staging │ │○homelab │ │ + │                  │
│ └─────────┘ └─────────┘ └─────────┘ └───┘                  │
│ [● = active, ○ = background, colors = connection status]    │
└─────────────────────────────────────────────────────────────┘
```

#### Connection Status Indicators

| Color      | Status                  |
| ---------- | ----------------------- |
| Green dot  | Connected, active       |
| Yellow dot | Connected, background   |
| Red dot    | Disconnected            |
| Pulsing    | Connecting/Reconnecting |

#### User Stories

##### US-5.5.1: Create New Session

**As a** user needing multiple connections\
**I want to** open new session tabs\
**So that** I can work with multiple hosts

**Acceptance Criteria:**

- Given I tap the "+" button in the tab bar
- When the connection picker appears
- Then I see: Recent connections, Saved hosts, Tailscale nodes
- And selecting a host creates a new tab
- And the new tab becomes active

##### US-5.5.2: Session Persistence

**As a** user who closes the app\
**I want** my sessions to persist\
**So that** I can resume where I left off

**Acceptance Criteria:**

- Given I have 3 active sessions
- When I close and reopen the app
- Then all 3 session tabs are restored
- And Mosh sessions reconnect automatically
- And SSH sessions show "Reconnect" prompt
- And block history is fully preserved

##### US-5.5.3: Quick Session Switch

**As a** user with multiple sessions\
**I want** fast tab switching\
**So that** I can multitask efficiently

**Acceptance Criteria:**

- Given I have multiple session tabs
- When I swipe left/right on the terminal area
- Then I switch between adjacent tabs
- And the transition animates smoothly
- And the new session's state is immediately visible

---

### 5.6 SFTP File Browser

#### Overview

Basic file transfer capability integrated into the terminal experience.

#### File Browser UI

```
┌─────────────────────────────────────────────────────────────┐
│ SFTP: prod-web-01:/var/log                    [↑] [⌂] [✕]  │
├─────────────────────────────────────────────────────────────┤
│ 📁 ..                                                        │
│ 📁 nginx/                              drwxr-xr-x  4.0K     │
│ 📁 postgresql/                         drwxr-xr-x  4.0K     │
│ 📄 syslog                              -rw-r-----  2.3M     │
│ 📄 auth.log                            -rw-r-----  156K     │
│ 📄 kern.log                            -rw-r-----  89K      │
├─────────────────────────────────────────────────────────────┤
│ [Upload] [New Folder] [Select Multiple]                     │
└─────────────────────────────────────────────────────────────┘
```

#### User Stories

##### US-5.6.1: Browse Remote Files

**As a** user needing to navigate remote filesystem\
**I want** a visual file browser\
**So that** I don't need to remember paths

**Acceptance Criteria:**

- Given I tap the SFTP icon in a connected session
- When the file browser opens
- Then I see the current directory listing
- And I can tap folders to navigate
- And I can tap ".." to go up
- And file sizes and permissions are shown

##### US-5.6.2: Download File

**As a** user needing a remote file\
**I want to** download it to my device\
**So that** I can view or share it

**Acceptance Criteria:**

- Given I long-press on a file
- When the context menu appears
- Then I see "Download" option
- And tapping it shows download progress
- And completed files open share sheet

##### US-5.6.3: Upload File

**As a** user needing to transfer files to server\
**I want to** upload from my device\
**So that** I can deploy configs or scripts

**Acceptance Criteria:**

- Given I tap "Upload" in the file browser
- When the device file picker opens
- Then I can select one or more files
- And upload progress is shown
- And files appear in the listing on completion

---

### 5.7 Snippets

#### Overview

Saved command templates with variable substitution for frequently used commands.

#### Snippet Structure

```yaml
name: "Deploy to Production"
command: "kubectl set image deployment/${deployment} ${container}=${image}:${tag} -n production"
variables:
  - name: deployment
    description: "Deployment name"
    default: "api-server"
  - name: container
    description: "Container name"
    default: "app"
  - name: image
    description: "Docker image"
    default: "myregistry/api"
  - name: tag
    description: "Image tag"
    required: true
tags: ["kubernetes", "deploy", "production"]
```

#### Snippet Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│ SNIPPET: Deploy to Production                                │
├─────────────────────────────────────────────────────────────┤
│ deployment: [api-server        ]                            │
│ container:  [app               ]                            │
│ image:      [myregistry/api    ]                            │
│ tag:        [v1.2.3            ] *required                  │
├─────────────────────────────────────────────────────────────┤
│ PREVIEW:                                                     │
│ kubectl set image deployment/api-server app=myregistry/...  │
├─────────────────────────────────────────────────────────────┤
│ [Cancel]                              [Copy] [Execute]      │
└─────────────────────────────────────────────────────────────┘
```

#### User Stories

##### US-5.7.1: Create Snippet

**As a** user with repetitive commands\
**I want to** save them as snippets\
**So that** I can reuse them quickly

**Acceptance Criteria:**

- Given I long-press on a command in a block
- When I select "Save as Snippet"
- Then a snippet editor opens
- And I can mark variables with ${name} syntax
- And I can add description and tags
- And the snippet is saved locally

##### US-5.7.2: Execute Snippet

**As a** user with saved snippets\
**I want to** execute them with variable substitution\
**So that** I can run complex commands quickly

**Acceptance Criteria:**

- Given I open the snippet library
- When I select a snippet
- Then I see input fields for each variable
- And defaults are pre-filled
- And I can preview the final command
- And "Execute" runs it in the current session

---

## 6. AI Integration Architecture

### 6.1 AI Gateway Design

```
┌─────────────────────────────────────────────────────────────┐
│                      AI GATEWAY                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Request   │───▶│   Router    │───▶│  Provider   │     │
│  │  Normalizer │    │             │    │  Adapter    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                            │                   │            │
│                            ▼                   ▼            │
│                     ┌─────────────┐    ┌─────────────┐     │
│                     │   Model     │    │  Response   │     │
│                     │  Selector   │    │  Normalizer │     │
│                     └─────────────┘    └─────────────┘     │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ PROVIDERS:                                                   │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│ │  Local   │ │  OpenAI  │ │ Anthropic│ │  Google  │        │
│ │ (GGML)   │ │ (GPT-4o) │ │ (Claude) │ │ (Gemini) │        │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Unified AI Interface

```dart
/// Abstract interface for all AI operations
abstract class AIGateway {
  /// Generate a CLI command from natural language
  Future<Either<AIFailure, CommandSuggestion>> generateCommand({
    required String naturalLanguage,
    required ShellContext context,
  });
  
  /// Suggest a fix for a failed command
  Future<Either<AIFailure, CommandFix>> healError({
    required String command,
    required String stderr,
    required int exitCode,
  });
  
  /// Summarize command output
  Future<Either<AIFailure, String>> summarizeOutput({
    required String output,
    int maxLength = 100,
  });
  
  /// Explain a command
  Future<Either<AIFailure, String>> explainCommand({
    required String command,
  });
}

@freezed
class CommandSuggestion with _$CommandSuggestion {
  const factory CommandSuggestion({
    required String command,
    required String explanation,
    required double confidence,
    List<String>? alternatives,
  }) = _CommandSuggestion;
}

@freezed
class CommandFix with _$CommandFix {
  const factory CommandFix({
    required String originalCommand,
    required String fixedCommand,
    required String explanation,
    required FixType fixType,
  }) = _CommandFix;
}

enum FixType {
  addSudo,
  installPackage,
  fixSyntax,
  changePermissions,
  createDirectory,
  other,
}
```

### 6.3 Model Router

```dart
class AIModelRouter {
  final LocalLLMProvider _localProvider;
  final Map<CloudProvider, CloudLLMProvider> _cloudProviders;
  final AIPreferences _preferences;
  final ConnectivityService _connectivity;
  
  Future<AIProvider> selectProvider(AITask task) async {
    // 1. Check user preferences
    if (_preferences.forceLocal) {
      return _localProvider;
    }
    
    // 2. Check connectivity
    final isOnline = await _connectivity.isConnected;
    if (!isOnline) {
      return _localProvider;
    }
    
    // 3. Route based on task complexity
    return switch (task) {
      AITask.summarize => _localProvider,  // Simple, local is fine
      AITask.generateCommand => _selectByComplexity(task),
      AITask.healError => _localProvider,  // Privacy: keep errors local
      AITask.explain => _preferences.preferredCloud ?? _localProvider,
    };
  }
  
  AIProvider _selectByComplexity(AITask task) {
    // Use local for simple commands, cloud for complex
    if (task.estimatedComplexity < 0.5) {
      return _localProvider;
    }
    return _cloudProviders[_preferences.preferredCloud] ?? _localProvider;
  }
}
```

### 6.4 Local LLM Integration

````dart
/// Local LLM using GGML format models
class LocalLLMProvider implements AIProvider {
  // Initial placeholder/default path. Product note: evaluate Gemma 4 E2B
  // as the preferred downloaded default model now that it has just been
  // released, subject to mobile performance, size, and quality validation.
  static const _modelPath = 'assets/models/qwen-0.5b-q4.gguf';
  
  late final LlamaModel _model;
  bool _isLoaded = false;
  
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    _model = await LlamaModel.load(
      modelPath: _modelPath,
      contextSize: 2048,
      threads: 4,  // Optimize for mobile
    );
    _isLoaded = true;
  }
  
  @override
  Future<Either<AIFailure, String>> complete(String prompt) async {
    if (!_isLoaded) {
      return const Left(AIFailure.modelNotLoaded());
    }
    
    try {
      final response = await _model.complete(
        prompt,
        maxTokens: 256,
        temperature: 0.7,
        stopSequences: ['\n\n', '```'],
      );
      return Right(response.trim());
    } catch (e) {
      return Left(AIFailure.inferenceError(e.toString()));
    }
  }
}
````

### 6.5 Prompt Templates

```dart
class AIPromptTemplates {
  static String commandGeneration(String naturalLanguage, ShellContext context) => '''
You are a CLI assistant. Convert the user's request to a shell command.

Context:
- Shell: ${context.shell}
- OS: ${context.os}
- Current directory: ${context.cwd}
- Available commands: ${context.availableCommands.take(20).join(', ')}

User request: $naturalLanguage

Respond with ONLY the command, no explanation.
Command:''';

  static String errorHealing(String command, String stderr, int exitCode) => '''
A command failed. Suggest a fix.

Command: $command
Exit code: $exitCode
Error output:
$stderr

Respond with:
1. Brief explanation of the error (one line)
2. Fixed command

Format:
EXPLANATION: <explanation>
FIXED: <command>''';

  static String outputSummary(String output) => '''
Summarize this command output in 1-2 sentences. Focus on the key information.

Output:
$output

Summary:''';
}
```

### 6.6 AI Feature: Ghostwriter

#### Natural Language to Command

```
┌─────────────────────────────────────────────────────────────┐
│ 🤖 AI GHOSTWRITER                                    [✕]    │
├─────────────────────────────────────────────────────────────┤
│ What do you want to do?                                      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ find all log files larger than 100MB modified today     │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ SUGGESTION:                                                  │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ find /var/log -name "*.log" -size +100M -mtime 0        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ 💡 Finds .log files over 100MB modified in last 24 hours   │
│                                                              │
│ [Regenerate]              [Edit] [Copy] [Execute]           │
└─────────────────────────────────────────────────────────────┘
```

#### One-Tap Error Healing

```
┌─────────────────────────────────────────────────────────────┐
│ [✗] $ npm install                                            │
│     ┌─ Status: Failed (1) ─────── 3.2s ─── 14:35:22 ──┐    │
├─────┴──────────────────────────────────────────────────┴────┤
│ npm ERR! EACCES: permission denied, mkdir '/usr/local/lib'  │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🔧 FIX AVAILABLE                                        │ │
│ │                                                          │ │
│ │ Permission denied when installing globally.              │ │
│ │ Suggested fix: Run with sudo                            │ │
│ │                                                          │ │
│ │ sudo npm install                                         │ │
│ │                                                          │ │
│ │ [Apply Fix]                              [Dismiss]       │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### User Stories

##### US-6.1: Natural Language Command

**As a** user who doesn't remember exact syntax\
**I want to** describe what I want in plain English\
**So that** I can get the correct command

**Acceptance Criteria:**

- Given I tap the AI button in the ribbon
- When I type "show disk usage sorted by size"
- Then AI suggests: "du -sh * | sort -h"
- And I can edit, copy, or execute directly
- And the command is explained briefly

##### US-6.2: Error Healing

**As a** user whose command failed\
**I want** automatic fix suggestions\
**So that** I can resolve errors quickly

**Acceptance Criteria:**

- Given a command fails with non-zero exit code
- When Bento analyzes the stderr
- Then a "Fix Available" banner appears
- And the fix is explained before applying
- And I can apply with one tap

##### US-6.3: Output Summarization

**As a** user with verbose command output\
**I want** automatic summaries\
**So that** I can understand results quickly

**Acceptance Criteria:**

- Given output exceeds 20 lines
- When the command completes
- Then a 1-2 sentence summary appears
- And tapping the summary expands full output
- And I can disable auto-summary in settings

##### US-6.4: Privacy Control

**As a** privacy-conscious user\
**I want** control over AI data handling\
**So that** sensitive data stays local

**Acceptance Criteria:**

- Given I open Settings > AI
- When I view privacy options
- Then I can choose: Local only, Cloud with consent, Always cloud
- And "Local only" uses on-device model exclusively
- And "Cloud with consent" asks before each cloud request

---

## 7. Security Model

### 7.1 Credential Storage

```dart
/// Secure credential management using platform keychain
class CredentialVault {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  
  CredentialVault(this._storage, this._localAuth);
  
  /// Store SSH private key with biometric protection
  Future<Either<SecurityFailure, void>> storePrivateKey({
    required String keyId,
    required String privateKey,
    String? passphrase,
  }) async {
    // Encrypt with AES-256 before storage
    final encrypted = await _encrypt(privateKey);
    
    await _storage.write(
      key: 'ssh_key_$keyId',
      value: encrypted,
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.when_unlocked_this_device_only,
      ),
    );
    
    if (passphrase != null) {
      await _storage.write(
        key: 'ssh_passphrase_$keyId',
        value: await _encrypt(passphrase),
      );
    }
    
    return const Right(null);
  }
  
  /// Retrieve key with biometric authentication
  Future<Either<SecurityFailure, String>> getPrivateKey(String keyId) async {
    // Require biometric auth
    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Authenticate to access SSH key',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    
    if (!authenticated) {
      return const Left(SecurityFailure.authenticationFailed());
    }
    
    final encrypted = await _storage.read(key: 'ssh_key_$keyId');
    if (encrypted == null) {
      return const Left(SecurityFailure.keyNotFound());
    }
    
    final decrypted = await _decrypt(encrypted);
    return Right(decrypted);
  }
}
```

### 7.2 SSH Agent Support

```dart
/// SSH Agent implementation for key forwarding
class SSHAgentService {
  final CredentialVault _vault;
  final List<SSHKeyPair> _loadedKeys = [];
  
  /// Add key to agent (requires biometric)
  Future<Either<SecurityFailure, void>> addKey(String keyId) async {
    final keyResult = await _vault.getPrivateKey(keyId);
    
    return keyResult.fold(
      (failure) => Left(failure),
      (privateKey) {
        final keyPair = SSHKeyPair.fromPem(privateKey);
        _loadedKeys.add(keyPair);
        return const Right(null);
      },
    );
  }
  
  /// Sign data with loaded key (for agent forwarding)
  Future<Uint8List> sign(Uint8List data, SSHPublicKey publicKey) async {
    final key = _loadedKeys.firstWhere(
      (k) => k.publicKey == publicKey,
      orElse: () => throw StateError('Key not loaded'),
    );
    
    return key.sign(data);
  }
  
  /// Clear all loaded keys (on app background/lock)
  void clearKeys() {
    _loadedKeys.clear();
  }
}
```

### 7.3 Security Policies

| Policy          | Implementation                             |
| --------------- | ------------------------------------------ |
| Key Storage     | AES-256 encrypted in platform keychain     |
| Key Access      | Biometric authentication required          |
| Session Timeout | Keys cleared after 5 minutes of inactivity |
| Clipboard       | Sensitive data cleared after 60 seconds    |
| Screen Capture  | Disabled for credential screens            |
| Network         | Certificate pinning for cloud AI APIs      |
| Local AI        | Models run in sandboxed process            |

### 7.4 Threat Model

| Threat             | Mitigation                                 |
| ------------------ | ------------------------------------------ |
| Device theft       | Biometric + encryption at rest             |
| Malicious app      | Platform sandboxing, no IPC for keys       |
| Network MITM       | Mosh encryption, SSH host key verification |
| Cloud AI data leak | Local-first, explicit consent for cloud    |
| Memory dump        | Keys cleared on background, secure memory  |

---

## 8. UX/Interaction Design

### 8.1 Design Principles

1. **Touch-First**: Every interaction designed for fingers, not cursors
2. **Glanceable**: Key information visible without interaction
3. **Forgiving**: Easy undo, confirmation for destructive actions
4. **Consistent**: Predictable gestures and patterns throughout
5. **Accessible**: Full support for assistive technologies

### 8.2 Color System

```dart
class BentoColors {
  // Semantic colors
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFF44336);
  static const warning = Color(0xFFFF9800);
  static const info = Color(0xFF2196F3);
  static const running = Color(0xFF03A9F4);
  
  // Terminal colors (Dracula-inspired default)
  static const background = Color(0xFF282A36);
  static const foreground = Color(0xFFF8F8F2);
  static const selection = Color(0xFF44475A);
  static const comment = Color(0xFF6272A4);
  static const cyan = Color(0xFF8BE9FD);
  static const green = Color(0xFF50FA7B);
  static const orange = Color(0xFFFFB86C);
  static const pink = Color(0xFFFF79C6);
  static const purple = Color(0xFFBD93F9);
  static const red = Color(0xFFFF5555);
  static const yellow = Color(0xFFF1FA8C);
  
  // UI chrome
  static const surface = Color(0xFF1E1E2E);
  static const surfaceVariant = Color(0xFF2D2D3D);
  static const outline = Color(0xFF3D3D4D);
}
```

### 8.3 Typography

```dart
class BentoTypography {
  // Terminal font
  static const terminalFont = 'JetBrainsMono';
  static const terminalSize = 14.0;
  static const terminalHeight = 1.4;
  
  // UI fonts
  static const uiFont = 'Inter';
  
  static const headline = TextStyle(
    fontFamily: uiFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  
  static const title = TextStyle(
    fontFamily: uiFont,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  
  static const body = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  static const caption = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: BentoColors.comment,
  );
}
```

### 8.4 Animation Guidelines

| Animation      | Duration | Curve         | Purpose             |
| -------------- | -------- | ------------- | ------------------- |
| Block collapse | 200ms    | easeInOut     | Smooth state change |
| Tab switch     | 300ms    | easeOutCubic  | Page transition     |
| Drawer open    | 250ms    | easeOutQuart  | Reveal content      |
| Button press   | 100ms    | easeIn        | Tactile feedback    |
| Loading pulse  | 1000ms   | linear (loop) | Indicate activity   |

### 8.5 Haptic Feedback Patterns

```dart
class BentoHaptics {
  static void onTap() => HapticFeedback.lightImpact();
  static void onSuccess() => HapticFeedback.mediumImpact();
  static void onError() => HapticFeedback.heavyImpact();
  static void onSelection() => HapticFeedback.selectionClick();
  
  static void onCommandComplete(bool success) {
    if (success) {
      onSuccess();
    } else {
      // Double pulse for error
      onError();
      Future.delayed(const Duration(milliseconds: 100), onError);
    }
  }
}
```

### 8.6 Screen Layouts

#### Main Terminal Screen

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [≡] prod-web-01                    [SFTP] [⚙] [+]      │ │ <- App Bar
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ┌───────┐ ┌───────┐ ┌───────┐ ┌───┐                    │ │ <- Session Tabs
│ │ │●prod  │ │○stage │ │○local │ │ + │                    │ │
│ │ └───────┘ └───────┘ └───────┘ └───┘                    │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                                                          │ │
│ │  [Block 1: ls -la]                                      │ │
│ │  ├─ output...                                           │ │
│ │                                                          │ │
│ │  [Block 2: cat config.yml]                              │ │ <- Block List
│ │  ├─ output...                                           │ │    (Scrollable)
│ │                                                          │ │
│ │  [Block 3: Running...]                                  │ │
│ │  ├─ streaming output...                                 │ │
│ │                                                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ $ kubectl get pods -n █                                 │ │ <- Input Line
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [pods] [services] [deploy] [nodes] [logs] [🤖]         │ │ <- Command Ribbon
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                    KEYBOARD                              │ │ <- System Keyboard
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### Connection Picker

```
┌─────────────────────────────────────────────────────────────┐
│ NEW CONNECTION                                        [✕]   │
├─────────────────────────────────────────────────────────────┤
│ 🔍 Search hosts...                                          │
├─────────────────────────────────────────────────────────────┤
│ RECENT                                                       │
│ ├─ 🖥 prod-web-01      user@192.168.1.10        2h ago     │
│ ├─ 🖥 staging-api      deploy@staging.example   yesterday  │
│ └─ 🖥 homelab-nas      admin@10.0.0.50          3d ago     │
├─────────────────────────────────────────────────────────────┤
│ TAILSCALE (4 nodes online)                            [↻]   │
│ ├─ 🟢 macbook-pro      100.64.0.1                          │
│ ├─ 🟢 home-server      100.64.0.2                          │
│ ├─ 🟢 raspberry-pi     100.64.0.3                          │
│ └─ 🔴 work-laptop      100.64.0.4 (offline)                │
├─────────────────────────────────────────────────────────────┤
│ SAVED HOSTS                                                  │
│ ├─ 📁 Production                                            │
│ │   ├─ web-01, web-02, api-01                              │
│ ├─ 📁 Staging                                               │
│ └─ 📁 Personal                                              │
├─────────────────────────────────────────────────────────────┤
│ [+ Add New Host]                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Data Model

### 9.1 Database Schema (Drift/SQLite)

```dart
// database/tables/sessions.dart
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get hostId => text().references(Hosts, #id)();
  IntColumn get protocol => intEnum<ConnectionProtocol>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get moshState => text().nullable()(); // For session resume
  
  @override
  Set<Column> get primaryKey => {id};
}

// database/tables/hosts.dart
class Hosts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get hostname => text()();
  IntColumn get port => integer().withDefault(const Constant(22))();
  TextColumn get username => text()();
  TextColumn get keyId => text().nullable()(); // Reference to secure storage
  BoolColumn get useMosh => boolean().withDefault(const Constant(true))();
  TextColumn get jumpHost => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// database/tables/blocks.dart
class Blocks extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get command => text()();
  TextColumn get output => text()();
  TextColumn get stderr => text().nullable()();
  IntColumn get exitCode => integer().nullable()();
  IntColumn get status => intEnum<BlockStatus>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get aiSummary => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get tappableElements => text().nullable()(); // JSON
  
  @override
  Set<Column> get primaryKey => {id};
}

// database/tables/snippets.dart
class Snippets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get command => text()();
  TextColumn get description => text().nullable()();
  TextColumn get variables => text().nullable()(); // JSON array
  TextColumn get tags => text().nullable()(); // JSON array
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// database/tables/command_history.dart
class CommandHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get command => text()();
  IntColumn get exitCode => integer().nullable()();
  DateTimeColumn get executedAt => dateTime()();
  
  // For prediction: track command sequences
  TextColumn get previousCommand => text().nullable()();
}
```

### 9.2 Entity Relationships

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    Host     │──1:N──│   Session   │──1:N──│    Block    │
└─────────────┘       └─────────────┘       └─────────────┘
       │                     │
       │                     │
       │              ┌──────┴──────┐
       │              │             │
       ▼              ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  SSH Key    │ │  Command    │ │   Snippet   │
│ (Secure     │ │  History    │ │             │
│  Storage)   │ └─────────────┘ └─────────────┘
└─────────────┘
```

### 9.3 Data Access Objects

```dart
@DriftAccessor(tables: [Blocks, Sessions])
class BlockDao extends DatabaseAccessor<AppDatabase> with _$BlockDaoMixin {
  BlockDao(super.db);
  
  /// Get all blocks for a session, ordered by time
  Future<List<Block>> getBlocksForSession(String sessionId) {
    return (select(blocks)
      ..where((b) => b.sessionId.equals(sessionId))
      ..orderBy([(b) => OrderingTerm.asc(b.startedAt)]))
    .get();
  }
  
  /// Search blocks by content
  Future<List<Block>> searchBlocks(String query) {
    return (select(blocks)
      ..where((b) => 
          b.command.contains(query) | 
          b.output.contains(query)))
    .get();
  }
  
  /// Get recent blocks across all sessions
  Stream<List<Block>> watchRecentBlocks({int limit = 50}) {
    return (select(blocks)
      ..orderBy([(b) => OrderingTerm.desc(b.startedAt)])
      ..limit(limit))
    .watch();
  }
  
  /// Insert or update block
  Future<void> upsertBlock(BlocksCompanion block) {
    return into(blocks).insertOnConflictUpdate(block);
  }
}
```

### 9.4 Caching Strategy

```dart
/// Multi-layer caching for performance
class CacheManager {
  final Hive _hive;
  final AppDatabase _db;
  
  // L1: In-memory cache for active session
  final Map<String, List<Block>> _memoryCache = {};
  
  // L2: Hive for fast key-value lookups
  late final Box<String> _kvCache;
  
  // L3: SQLite for full persistence
  
  Future<void> initialize() async {
    _kvCache = await Hive.openBox('cache');
  }
  
  /// Get blocks with cache hierarchy
  Future<List<Block>> getBlocks(String sessionId) async {
    // L1: Check memory
    if (_memoryCache.containsKey(sessionId)) {
      return _memoryCache[sessionId]!;
    }
    
    // L2: Check Hive (for recently accessed)
    final cached = _kvCache.get('blocks_$sessionId');
    if (cached != null) {
      final blocks = _deserializeBlocks(cached);
      _memoryCache[sessionId] = blocks;
      return blocks;
    }
    
    // L3: Load from SQLite
    final blocks = await _db.blockDao.getBlocksForSession(sessionId);
    _memoryCache[sessionId] = blocks;
    _kvCache.put('blocks_$sessionId', _serializeBlocks(blocks));
    return blocks;
  }
}
```

---

## 10. Success Metrics

### 10.1 Performance Metrics

| Metric                       | Target                 | Measurement Method          |
| ---------------------------- | ---------------------- | --------------------------- |
| Keystroke-to-render latency  | < 50ms on 4G           | Instrumentation + analytics |
| App launch to terminal ready | < 2 seconds            | Cold start timing           |
| Frame rate during scroll     | 60fps sustained        | Flutter DevTools            |
| Memory usage (idle)          | < 150MB                | Platform profiler           |
| Memory usage (10 sessions)   | < 300MB                | Platform profiler           |
| Block search latency         | < 100ms for 10K blocks | SQLite query timing         |
| AI local inference           | < 500ms                | Model timing                |

### 10.2 User Experience Metrics

| Metric                   | Target                  | Measurement Method               |
| ------------------------ | ----------------------- | -------------------------------- |
| Keystroke reduction      | 50% vs raw typing       | Compare input length to executed |
| Session recovery rate    | 99.9% on network change | Track Mosh reconnections         |
| AI suggestion acceptance | > 60%                   | Track accept/reject              |
| Error healing success    | > 70%                   | Track fix applications           |
| Daily active users       | 10K by month 6          | Analytics                        |
| Session duration         | > 5 minutes average     | Analytics                        |

### 10.3 Quality Metrics

| Metric               | Target      | Measurement Method  |
| -------------------- | ----------- | ------------------- |
| Crash-free sessions  | > 99.5%     | Crashlytics/Sentry  |
| App Store rating     | > 4.5 stars | Store reviews       |
| GitHub issues (bugs) | < 50 open   | Issue tracker       |
| Test coverage        | > 80%       | CI coverage reports |

### 10.4 Business Metrics

| Metric            | Target                | Measurement Method |
| ----------------- | --------------------- | ------------------ |
| GitHub stars      | 5K by month 12        | GitHub API         |
| Contributors      | 20+ by month 12       | GitHub insights    |
| Monthly donations | $2K by month 12       | Open Collective    |
| Downloads         | 50K total by month 12 | App Store Connect  |

---

## 11. MVP Scope (Phase 1)

### 11.1 Phase 1 Features (Months 1-4)

#### Must Have (P0)

| Feature            | Description                            | Acceptance Criteria                           |
| ------------------ | -------------------------------------- | --------------------------------------------- |
| Terminal Emulation | xterm-based terminal with ANSI support | Renders 256 colors, handles escape sequences  |
| SSH Connectivity   | Connect via SSH with key auth          | Successful connection to standard SSH servers |
| Semantic Blocks    | Command/output grouping                | Blocks created, collapsible, searchable       |
| Session Tabs       | Multiple concurrent sessions           | Create, switch, close tabs                    |
| Basic Ribbon       | Command completion from history        | Shows recent commands, tappable               |
| Credential Storage | Secure key storage                     | Keys encrypted, biometric access              |
| Block Persistence  | SQLite storage                         | Blocks survive app restart                    |

#### Should Have (P1)

| Feature         | Description                     | Acceptance Criteria          |
| --------------- | ------------------------------- | ---------------------------- |
| Mosh Support    | UDP-based resilient connections | Survives network transitions |
| Modifier Drawer | Special key access              | Ctrl, Alt, arrows accessible |
| Host Management | Save and organize hosts         | CRUD operations, folders     |
| Basic Search    | Search within blocks            | Find text, highlight matches |
| Tappable IPs    | Tap IP addresses for actions    | Context menu appears         |

#### Nice to Have (P2)

| Feature          | Description          | Acceptance Criteria               |
| ---------------- | -------------------- | --------------------------------- |
| Tailscale Query  | Show Tailscale nodes | Nodes appear in connection picker |
| Dark/Light Theme | Theme switching      | Both themes complete              |
| Export Blocks    | Share block content  | Copy, share sheet                 |

### 11.2 Phase 1 Technical Milestones

| Week  | Milestone          | Deliverable                                      |
| ----- | ------------------ | ------------------------------------------------ |
| 1-2   | Project Setup      | Flutter project, CI/CD, architecture scaffolding |
| 3-4   | Terminal Core      | xterm integration, basic rendering               |
| 5-6   | SSH Integration    | dartssh2 connection, key management              |
| 7-8   | Block System       | Block creation, persistence, UI                  |
| 9-10  | Session Management | Tabs, state management, navigation               |
| 11-12 | Input System       | Ribbon, modifier drawer                          |
| 13-14 | Polish & Testing   | Bug fixes, performance optimization              |
| 15-16 | Beta Release       | TestFlight/Play Store internal testing           |

### 11.3 Phase 1 Out of Scope

- AI Ghostwriter (Phase 2)
- Dashboard Overlay (Phase 2)
- SFTP Browser (Phase 2)
- Snippets (Phase 2)
- Voice Input (Phase 2)
- Auto-widgetization (Phase 2)

---

## 12. Future Roadmap

### 12.1 Phase 2: Intelligence (Months 5-7)

| Feature              | Priority | Description                  |
| -------------------- | -------- | ---------------------------- |
| AI Ghostwriter       | P0       | Natural language to command  |
| Error Healing        | P0       | One-tap fix suggestions      |
| Output Summarization | P1       | AI-generated summaries       |
| Local LLM            | P0       | On-device Qwen/Phi model; evaluate Gemma 4 E2B as the downloaded default |
| Cloud AI Fallback    | P1       | OpenAI/Anthropic integration |
| SFTP Browser         | P0       | Basic file transfer          |
| Snippets             | P1       | Command templates            |

### 12.2 Phase 3: Visualization (Months 8-10)

| Feature            | Priority | Description                     |
| ------------------ | -------- | ------------------------------- |
| Dashboard Overlay  | P0       | Native charts for TUI apps      |
| Command Parsers    | P0       | df, ps, netstat parsing         |
| Auto-widgetization | P1       | Detect and transform TUI output |
| Voice Input        | P2       | Speech-to-command               |
| Advanced Search    | P1       | Regex, filters, date ranges     |

### 12.3 Phase 4: Polish (Months 11-12)

| Feature                  | Priority | Description                         |
| ------------------------ | -------- | ----------------------------------- |
| Performance Optimization | P0       | Memory, battery, startup time       |
| Accessibility Audit      | P0       | VoiceOver/TalkBack compliance       |
| Localization             | P1       | i18n for top 5 languages            |
| Documentation            | P0       | User guide, API docs                |
| Community Setup          | P0       | Contributing guide, issue templates |

### 12.4 Version 2.0 Features (Post-Launch)

| Feature                    | Description                      | Rationale for Deferral          |
| -------------------------- | -------------------------------- | ------------------------------- |
| Magic Link Session Handoff | Transfer session between devices | Requires backend infrastructure |
| Team Sharing               | Share snippets, hosts with team  | Requires account system         |
| Plugin System              | Third-party extensions           | Needs stable API first          |
| Desktop App                | macOS/Windows/Linux              | Mobile-first focus              |
| Eternal Terminal           | ET protocol support              | Mosh covers most use cases      |
| Custom Themes              | User-created color schemes       | Nice-to-have                    |
| Keyboard Shortcuts         | External keyboard support        | iPad focus later                |

---

## 13. Open Source Considerations

### 13.1 License

**MIT License** - Chosen for maximum adoption and contribution potential.

```
MIT License

Copyright (c) 2026 Bento Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 13.2 Repository Structure

```
bento/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── question.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── codeql.yml
│   └── CODEOWNERS
├── docs/
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   ├── SECURITY.md
│   └── api/
├── lib/                    # Main application code
├── test/                   # Unit and widget tests
├── integration_test/       # Integration tests
├── ios/
├── android/
├── assets/
├── scripts/               # Build and utility scripts
├── LICENSE
├── README.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
└── pubspec.yaml
```

### 13.3 Contribution Guidelines

```markdown
# Contributing to Bento

## Getting Started

1. Fork the repository
2. Clone your fork
3. Run `flutter pub get`
4. Run `dart run build_runner build`
5. Run tests: `flutter test`

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Write/update tests
4. Run `flutter analyze` and fix issues
5. Submit a pull request

## Code Style

- Follow Effective Dart guidelines
- Use `flutter_lints` rules
- Maximum line length: 80 characters
- Use trailing commas for better diffs

## Commit Messages

Follow Conventional Commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

## Pull Request Process

1. Update CHANGELOG.md
2. Ensure CI passes
3. Request review from maintainers
4. Squash and merge after approval
```

### 13.4 Sustainability Model

| Revenue Stream     | Target          | Timeline |
| ------------------ | --------------- | -------- |
| GitHub Sponsors    | $500/month      | Month 6  |
| Open Collective    | $1000/month     | Month 9  |
| Corporate Sponsors | $500/month      | Month 12 |
| **Total**          | **$2000/month** | Month 12 |

### 13.5 Governance

- **Maintainers**: Core team with merge rights
- **Contributors**: Community members with accepted PRs
- **RFC Process**: Major features require RFC discussion
- **Release Cadence**: Monthly releases, semantic versioning

---

## 14. Appendix

### 14.1 Package Version Reference

| Package                | Version | Purpose            | License    |
| ---------------------- | ------- | ------------------ | ---------- |
| xterm                  | ^4.0.0  | Terminal emulation | MIT        |
| dartssh2               | ^2.13.0 | SSH/SFTP client    | MIT        |
| flutter_riverpod       | ^3.2.1  | State management   | MIT        |
| go_router              | ^17.1.0 | Navigation         | BSD-3      |
| drift                  | ^2.18.0 | SQLite ORM         | MIT        |
| flutter_secure_storage | ^10.0.0 | Credential storage | BSD-3      |
| local_auth             | ^3.0.0  | Biometrics         | BSD-3      |
| fl_chart               | ^1.1.1  | Charts             | MIT        |
| speech_to_text         | ^7.3.0  | Voice input        | MIT        |
| fpdart                 | ^1.2.0  | Functional utils   | MIT        |
| hive_flutter           | ^1.1.0  | Fast KV storage    | Apache-2.0 |
| cryptography           | ^2.7.0  | Encryption         | Apache-2.0 |

### 14.2 Competitive Analysis

| App         | Platform    | Blocks  | Mosh    | AI      | Price    |
| ----------- | ----------- | ------- | ------- | ------- | -------- |
| Termius     | iOS/Android | No      | Yes     | No      | Freemium |
| Prompt 3    | iOS         | No      | Yes     | No      | $19.99   |
| Blink Shell | iOS         | No      | Yes     | No      | $19.99   |
| a]Shell     | iOS         | No      | No      | No      | Free     |
| JuiceSSH    | Android     | No      | No      | No      | Freemium |
| **Bento**   | iOS/Android | **Yes** | **Yes** | **Yes** | **Free** |

### 14.3 Technical References

1. **Mosh Protocol**: [MIT Paper](https://mosh.org/mosh-paper.pdf)
2. **SSH RFC**: [RFC 4251](https://tools.ietf.org/html/rfc4251)
3. **ANSI Escape Codes**:
   [Wikipedia](https://en.wikipedia.org/wiki/ANSI_escape_code)
4. **Flutter Impeller**: [Flutter Docs](https://docs.flutter.dev/perf/impeller)
5. **Riverpod**: [Official Docs](https://riverpod.dev/)
6. **Drift**: [Official Docs](https://drift.simonbinder.eu/)

### 14.4 Glossary

| Term           | Definition                                                  |
| -------------- | ----------------------------------------------------------- |
| Block          | A discrete unit containing a command and its output         |
| Ghostwriter    | AI feature that converts natural language to commands       |
| Mosh           | Mobile Shell - UDP-based protocol for resilient connections |
| Ribbon         | Horizontal suggestion strip above keyboard                  |
| Semantic Block | Block with parsed, interactive elements                     |
| TUI            | Text User Interface (e.g., htop, vim)                       |
| Widgetization  | Converting TUI output to native Flutter widgets             |

### 14.5 Open Questions

| Question                                         | Status   | Decision                                                     |
| ------------------------------------------------ | -------- | ------------------------------------------------------------ |
| Should we support Eternal Terminal in v1?        | Deferred | Evaluate post-launch based on demand                         |
| Local LLM model size vs quality tradeoff?        | Open     | Test Qwen-0.5B, Phi-2, and newly released Gemma 4 E2B; if Gemma 4 E2B performs well on-device, prefer it as the downloaded default model |
| Should blocks have a maximum stored output size? | Open     | Propose 1MB limit with truncation indicator                  |
| How to handle very long-running commands?        | Open     | Consider streaming to disk after threshold                   |

---

## Document History

| Version | Date       | Author       | Changes                             |
| ------- | ---------- | ------------ | ----------------------------------- |
| 0.1     | 2026-02-03 | Product Team | Initial draft                       |
| 1.0     | 2026-02-04 | Product Team | Comprehensive PRD with all sections |

---

_This document is the source of truth for Bento development. All feature
decisions should reference this PRD. Updates require review from the product
team._
