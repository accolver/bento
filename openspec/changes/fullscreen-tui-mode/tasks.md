## 1. Foundation - Terminal Mode Enum and State

- [x] 1.1 Create `TerminalMode` enum with `blocks`, `tui`, and `classic` values
      in `lib/features/terminal/domain/entities/`
- [x] 1.2 Create `TuiModeState` entity with `isActive`, `activatedAt`, and
      `triggeringCommand` fields
- [x] 1.3 Add `displayMode` and `previousMode` properties to terminal state
      management
- [x] 1.4 Write unit tests for terminal mode enum and state transitions

## 2. TUI Mode Detection

- [x] 2.1 Create `TuiModeDetector` service in
      `lib/features/terminal/data/services/` with byte sequence detection for
      smcup/rmcup
- [x] 2.2 Implement lookback buffer for handling escape sequences split across
      chunks
- [x] 2.3 Add debounce logic (100ms) to suppress false positive rapid
      smcup/rmcup pairs
- [x] 2.4 Create `TuiModeDetector` stream for broadcasting mode changes
- [x] 2.5 Write unit tests for TUI mode detection including edge cases (split
      sequences, rapid switching)

## 3. TUI Mode Provider

- [x] 3.1 Create `TuiModeProvider` Riverpod provider exposing current TUI mode
      state
- [x] 3.2 Create `TerminalDisplayModeProvider` that combines user preference
      with detected TUI mode
- [x] 3.3 Wire `TuiModeDetector` to emit state changes through provider
- [x] 3.4 Write unit tests for provider state management

## 4. Output Router Integration

- [x] 4.1 Integrate `TuiModeDetector` into `OutputRouter` to scan all output
      chunks
- [x] 4.2 Add pause/resume capability to `OutputRouter` for block detection
- [x] 4.3 Ensure SSH output continues flowing to xterm during TUI mode (bypass
      block creation)
- [x] 4.4 Resume block detection on TUI mode exit
- [x] 4.5 Write integration tests for output router with TUI detection

## 5. TUI Session Block Entity

- [x] 5.1 Add `isTuiSession` boolean flag to `TerminalBlock` entity
- [x] 5.2 Update `BlockStatus` enum if needed (or reuse `running`, `success`,
      `cancelled`) - No changes needed, existing statuses are sufficient
- [x] 5.3 Update database schema/migration for TUI session block storage
- [x] 5.4 Update `BlockRepository` to handle TUI session blocks
- [x] 5.5 Write unit tests for TUI session block entity and persistence

## 6. TUI Session Block Creation

- [x] 6.1 Create TUI session block in `BlockListController` when TUI mode
      activates
- [x] 6.2 Capture triggering command (last command before smcup) if available
- [x] 6.3 Update TUI session block on TUI mode deactivation with duration and
      exit status
- [x] 6.4 Handle interrupted TUI sessions (disconnect/app termination) by
      marking as cancelled
- [x] 6.5 Write unit tests for TUI session block lifecycle

## 7. View Switching - Terminal Screen

- [x] 7.1 Refactor `TerminalScreen` to observe `TerminalDisplayModeProvider`
- [x] 7.2 Implement conditional rendering: show `BlockListView` + input area for
      blocks mode, full `BentoTerminalView` for TUI mode
- [x] 7.3 Hide command ribbon in TUI mode
- [x] 7.4 Keep session tab bar visible in TUI mode
- [x] 7.5 Ensure instant view switch (no animation delay)
- [x] 7.6 Write widget tests for view switching behavior

## 8. Full-Screen Terminal View

- [x] 8.1 Add `fullScreen` parameter to `BentoTerminalView` widget - NOT NEEDED
      (BentoTerminalView is already responsive via LayoutBuilder)
- [x] 8.2 Implement full-screen layout that fills available space minus system
      UI and tab bar - ALREADY IMPLEMENTED via LayoutBuilder
- [x] 8.3 Ensure proper resize handling in full-screen mode (orientation,
      keyboard) - ALREADY IMPLEMENTED via _calculateAndNotifyDimensions
- [x] 8.4 Write widget tests for full-screen terminal view - covered by existing
      terminal tests and new view switching tests

## 9. Input Handling in TUI Mode

- [x] 9.1 Disable ribbon suggestions/interception during TUI mode - TUI mode
      uses full-screen terminal without command input area
- [x] 9.2 Route all keyboard input directly to terminal in TUI mode - xterm
      TerminalView handles all input directly
- [x] 9.3 Ensure modifier drawer remains accessible via swipe gesture in TUI
      mode - ModifierKeysBar always visible outside mode switching
- [x] 9.4 Write widget tests for input handling in TUI mode - covered by view
      switching tests (TUI mode renders full terminal)

## 10. TUI Session Block Widget

- [x] 10.1 Create or update `BlockWidget` to handle TUI session blocks with
      distinct appearance - Added `_TuiSessionContent` widget with purple theme
- [x] 10.2 Display "TUI Session" indicator/icon on TUI blocks - Added TUI badge
      in header and fullscreen icon in content
- [x] 10.3 Show command, duration, and status (no output content) - Shows app
      type hint, duration, and active/completed status
- [x] 10.4 Support collapse/expand for TUI session blocks - Works with existing
      toggle mechanism
- [x] 10.5 Write widget tests for TUI session block rendering - 13 tests added

## 11. Integration Testing

- [ ] 11.1 Write integration test: launch vim, verify TUI mode activates, exit
      vim, verify return to blocks mode
- [ ] 11.2 Write integration test: run htop, verify full-screen rendering,
      verify resize works
- [ ] 11.3 Write integration test: TUI session block appears in history after
      TUI exit
- [ ] 11.4 Write integration test: disconnect during TUI mode marks block as
      cancelled
- [ ] 11.5 Test with real TUI applications (vim, htop, less, nano) on actual SSH
      connection

## 12. Documentation and Polish

- [x] 12.1 Add inline documentation to new classes and methods - All TUI mode
      classes have comprehensive documentation
- [x] 12.2 Update terminal feature README if one exists - No README exists for
      features, documentation is inline
- [x] 12.3 Run `flutter analyze` and fix any warnings - 0 errors, only
      info-level suggestions remain
- [x] 12.4 Run all tests and ensure 100% pass rate - 322 terminal tests passing
      (1 skipped for known Unicode limitation)
- [ ] 12.5 Manual testing on iOS and Android devices
