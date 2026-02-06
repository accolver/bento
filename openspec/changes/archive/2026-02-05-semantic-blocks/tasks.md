# Tasks: Semantic Blocks

## 1. Block Entity & Data Model

- [x] 1.1 Create BlockStatus enum in
      `lib/features/terminal/domain/entities/block_status.dart`
- [x] 1.2 Create Block freezed entity in
      `lib/features/terminal/domain/entities/block.dart`
- [x] 1.3 Add blocks table to database schema in
      `lib/database/tables/blocks.dart`
- [x] 1.4 Create database migration (v3) for blocks table
- [x] 1.5 Create BlockRepository for CRUD operations in
      `lib/features/terminal/data/repositories/block_repository.dart`
- [x] 1.6 Write unit tests for Block entity

## 2. Block State Management

- [x] 2.1 Create BlockListController StateNotifier in
      `lib/features/terminal/presentation/providers/block_provider.dart`
- [x] 2.2 Implement block creation method in controller
- [x] 2.3 Implement output append method in controller
- [x] 2.4 Implement block completion method (with status update)
- [x] 2.5 Implement collapse/expand toggle method
- [x] 2.6 Wire BlockListController to database for persistence
- [x] 2.7 Run code generation for providers
      (`flutter pub run build_runner build`)

## 3. Prompt Detection

- [x] 3.1 Create PromptDetector service in
      `lib/features/terminal/data/services/prompt_detector.dart`
- [x] 3.2 Implement regex patterns for bash/zsh/fish prompts
- [x] 3.3 Implement command extraction from prompt line
- [x] 3.4 Add configurable prompt patterns to terminal config
- [x] 3.5 Write unit tests for prompt detection with various prompt formats

## 4. Output Streaming Integration

- [x] 4.1 Create OutputRouter service to route output through
      BlockListController
- [x] 4.2 Implement output buffering for batch updates (16ms frame batching)
- [x] 4.3 Implement block boundary detection using PromptDetector
- [x] 4.4 Implement exit code detection from shell output
- [x] 4.5 Implement Ctrl+C cancellation detection
- [x] 4.6 Write unit tests for OutputRouter

## 5. Block Widget UI

- [x] 5.1 Create BlockWidget in
      `lib/features/terminal/presentation/widgets/block_widget.dart`
- [x] 5.2 Implement block header with command, status icon, timestamp
- [x] 5.3 Implement block content area (SelectableText for now, xterm later)
- [x] 5.4 Implement collapse/expand animation using AnimatedSize
- [x] 5.5 Add status-based left border colors (green/red/blue/yellow)
- [x] 5.6 Implement chevron icon toggle for expand/collapse state
- [x] 5.7 Write widget tests for BlockWidget states

## 6. Block Status Indicators

- [x] 6.1 Create status color constants in
      `lib/core/constants/block_colors.dart`
- [x] 6.2 Implement running state with pulsing animation
- [x] 6.3 Implement success state with green border and checkmark
- [x] 6.4 Implement failed state with red border and X icon
- [x] 6.5 Implement cancelled state with yellow border and cancel icon
- [x] 6.6 Ensure colors work in both light and dark themes

## 7. Block Actions

- [x] 7.1 Copy Command integrated into BlockWidget (long-press header)
- [x] 7.2 Implement "Copy Output" action (strip ANSI codes)
- [x] 7.3 Implement "Copy All" action (command + output)
- [x] 7.4 Implement "Re-run" action to re-execute command
- [x] 7.5 Implement long-press context menu with full actions
- [x] 7.6 Add "Collapse All" and "Expand All" to session menu

## 8. Block List View

- [x] 8.1 Create BlockListView widget in
      `lib/features/terminal/presentation/widgets/block_list_view.dart`
- [x] 8.2 Implement virtualized list for performance (ListView.builder)
- [x] 8.3 Implement auto-scroll to new blocks at bottom
- [x] 8.4 Handle empty state (no blocks yet)
- [x] 8.5 Integrate BlockListView into TerminalScreen

## 9. Terminal Screen Integration

- [x] 9.1 Update TerminalScreen with dual-mode view (classic + blocks)
- [x] 9.2 Create OutputRouterProvider for SSH output routing
- [x] 9.3 Route keyboard input through OutputRouter for Ctrl+C detection
- [x] 9.4 Add feature flag toggle (enableSemanticBlocks in TerminalConfig)
- [x] 9.5 Wire OutputRouter to SSH connection in TerminalController
- [x] 9.6 Add app bar actions (collapse all, expand all, clear blocks)

## 10. Persistence & History

- [x] 10.1 Implement block save to database on completion
- [x] 10.2 Implement block load from database on session resume
- [x] 10.3 Implement output compression for database storage
- [x] 10.4 Implement output truncation for large outputs (100KB limit in memory)
- [x] 10.5 Implement "Load Full Output" for truncated blocks
- [x] 10.6 Add session_id column default for pre-session-tabs usage
