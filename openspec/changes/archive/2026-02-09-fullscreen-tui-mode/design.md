## Context

Bento's current architecture splits the terminal experience into two layers:

1. **xterm layer**: The underlying terminal emulator (via xterm package) that
   handles escape sequences, cursor positioning, and renders the terminal UI
2. **Semantic blocks layer**: Intercepts output from SSH, detects shell prompts,
   and organizes command/output pairs into discrete collapsible blocks

The semantic blocks layer works by:

- Routing all SSH output through `OutputRouter`
- Using `PromptDetector` to identify when a command completes (by detecting the
  next shell prompt)
- Creating `TerminalBlock` entities for each command/output pair
- Displaying blocks in a `BlockListView` with a small xterm input area at the
  bottom

This architecture fundamentally breaks when running TUI applications because:

1. TUIs use alternate screen buffer mode (`\x1b[?1049h`) which is a full-screen
   canvas
2. TUIs rely on precise cursor positioning that block parsing destroys
3. TUIs don't emit shell prompts between updates (continuous real-time
   rendering)
4. The small input area prevents TUIs from using the full terminal viewport

### Current Data Flow

```
SSH stdout → OutputRouter → PromptDetector → BlockListController → BlockListView
                                    ↓
                            [small xterm area for input]
```

### Target Data Flow (TUI Mode)

```
SSH stdout → TuiModeDetector → [TUI detected?]
                                    │
                    ┌───────────────┴───────────────┐
                    ↓ No                             ↓ Yes
            OutputRouter →                    Full-screen xterm
            BlockListView                     (bypass blocks)
```

## Goals / Non-Goals

**Goals:**

1. Seamlessly support full-screen TUI applications (vim, htop, Claude Code,
   OpenCode, etc.)
2. Automatically detect TUI mode via escape sequences - no user action required
3. Preserve semantic blocks experience for normal command-line workflows
4. Create TUI session blocks after TUI exits for history purposes
5. Handle resize events properly during TUI mode
6. Maintain 60fps rendering during TUI mode

**Non-Goals:**

1. Parsing or interpreting TUI application content (no widgetization of TUI
   content)
2. Supporting multiple concurrent TUI sessions in split view
3. Adding TUI-specific gestures or overlays during TUI mode
4. Persisting TUI screen state across app backgrounding (xterm handles this)
5. Detecting specific TUI applications by name

## Decisions

### Decision 1: Escape Sequence Monitoring Location

**Options Considered:**

- **A) Intercept before xterm** - Monitor raw SSH output before passing to xterm
- **B) Query xterm state** - Check if xterm has alternate screen active
- **C) Hybrid approach** - Monitor output AND query xterm for confirmation

**Decision: Option A - Intercept before xterm**

**Rationale:**

- The xterm package doesn't expose alternate screen buffer state
- We already intercept output in `OutputRouter` for block parsing
- Adding detection there is consistent with existing architecture
- Lower latency than polling xterm state

### Decision 2: State Management Pattern

**Options Considered:**

- **A) Boolean flag in TerminalController** - Simple `isTuiMode` property
- **B) Dedicated TuiModeProvider** - Separate Riverpod provider for TUI state
- **C) Enum-based terminal mode** -
  `TerminalMode.blocks | TerminalMode.tui | TerminalMode.classic`

**Decision: Option C - Enum-based terminal mode**

**Rationale:**

- More extensible than boolean (future modes possible)
- Aligns with existing `enableSemanticBlocks` toggle - this becomes a third mode
- Single source of truth for terminal display mode
- Clear state machine semantics

### Decision 3: View Switching Animation

**Options Considered:**

- **A) Instant switch** - Immediately swap views
- **B) Fade transition** - Cross-fade between views
- **C) Slide/expand transition** - Input area expands to full screen

**Decision: Option A - Instant switch**

**Rationale:**

- TUI applications expect immediate full-screen control
- Animation delay could cause visual artifacts during TUI initialization
- TUI apps often clear screen immediately anyway
- Can revisit with optional animation in future

### Decision 4: Block Creation for TUI Sessions

**Options Considered:**

- **A) No block created** - TUI sessions don't appear in block history
- **B) Placeholder block** - Create empty block with just the command
- **C) TUI session block** - Special block type with command, duration, exit
  status

**Decision: Option C - TUI session block**

**Rationale:**

- Users want to see TUI sessions in their history
- Exit code is valuable information (did vim exit cleanly?)
- Duration helps track time spent in TUI apps
- Block can show "TUI Session" indicator instead of output
- Consistent with semantic blocks philosophy of discrete units

### Decision 5: Escape Sequence Detection Method

**Options Considered:**

- **A) String search** - Check output string for `\x1b[?1049h`
- **B) State machine parser** - Parse all escape sequences properly
- **C) Regex pattern** - Use regex to match alternate screen sequences

**Decision: Option A - String search with validation**

**Rationale:**

- Simple and fast - single-pass string search
- Alternate screen sequences are unambiguous
- Full escape sequence parsing is overkill for this use case
- Validation ensures we don't false-positive on output that happens to contain
  the bytes

**Implementation detail:** Search for the byte sequence, not string (handles
encoding):

```dart
final smcup = [0x1B, 0x5B, 0x3F, 0x31, 0x30, 0x34, 0x39, 0x68]; // \x1b[?1049h
final rmcup = [0x1B, 0x5B, 0x3F, 0x31, 0x30, 0x34, 0x39, 0x6C]; // \x1b[?1049l
```

### Decision 6: Input Handling During TUI Mode

**Options Considered:**

- **A) Keep ribbon visible** - Show command ribbon during TUI mode
- **B) Hide ribbon** - Full terminal takeover, ribbon hidden
- **C) Swipe to reveal** - Hidden by default, swipe gesture reveals ribbon

**Decision: Option B - Hide ribbon**

**Rationale:**

- TUI apps need full screen including the ribbon area
- Keeping ribbon would confuse TUI apps that track screen dimensions
- Users in TUI mode are interacting with the TUI, not shell
- Modifier drawer should still be accessible via gesture

## Risks / Trade-offs

### Risk 1: False Positive TUI Detection

Some programs output escape sequences without truly being TUIs.

**Mitigation:** Require both smcup AND actual alternate buffer usage. If rmcup
follows within 100ms without any other output, treat as false positive and don't
switch modes.

### Risk 2: Missed TUI Exit Detection

If rmcup sequence is in a large output chunk, we might miss it.

**Mitigation:** Scan all output chunks for rmcup, not just the beginning. Use a
small state buffer to handle sequences split across chunks.

### Risk 3: Resize During TUI Mode

Keyboard show/hide during TUI mode could cause issues.

**Mitigation:** Ensure resize events are propagated to xterm AND the SSH PTY
during TUI mode. This is already handled by `terminal-resize` spec but needs
testing.

### Risk 4: Block State Inconsistency

If app crashes during TUI mode, we might have an incomplete TUI session block.

**Mitigation:** Create the TUI block immediately when entering TUI mode with
status "running". Update with exit info on TUI exit or mark as "interrupted" on
disconnect.

### Risk 5: Performance Overhead

Scanning every output chunk for escape sequences adds overhead.

**Mitigation:** Use optimized byte search (Boyer-Moore or similar). In practice,
the 8-byte search is negligible compared to xterm rendering. Only scan when NOT
in TUI mode (no need to look for smcup when already in TUI mode).

## Migration Plan

No migration needed. This is a new feature that enhances existing functionality:

1. Add `TuiModeDetector` service
2. Add `TerminalMode` enum with `blocks`, `tui`, `classic` values
3. Modify `OutputRouter` to use detector and pause routing during TUI
4. Modify `TerminalScreen` to switch views based on mode
5. Add `TuiSessionBlock` variant or flag to `TerminalBlock`
6. Update providers to expose and react to terminal mode

**Rollback:** If issues arise, `TuiModeDetector` can be disabled by simply not
calling it from `OutputRouter`. The detector is stateless and has no
persistence.

## Open Questions

1. **Q: Should we show a brief indicator when entering/exiting TUI mode?**
   Options: Toast notification, subtle animation, nothing Recommendation: Start
   with nothing, add toast if user feedback indicates confusion

2. **Q: How should the modifier drawer behave during TUI mode?** The drawer
   should remain accessible. TUI apps often need Ctrl+C, Esc, etc. Confirm this
   works with xterm in full-screen mode.

3. **Q: What about nested TUI invocations (e.g., running vim inside tmux)?**
   This should work naturally since we track alternate screen buffer state, not
   specific commands. Verify with integration testing.
