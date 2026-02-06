# AI FAB Panel - Technical Design

## Context

Bento's terminal interface currently provides semantic blocks for command
organization but lacks AI assistance for command generation. Users must type
commands manually, which is error-prone on mobile devices. The AI Ghostwriter
feature will allow users to describe what they want in natural language and
receive correct CLI commands.

This design covers the UI layer for AI interaction. The actual AI processing
(local LLM or cloud API) will be implemented in a separate `ai-gateway` change.
For this initial implementation, we'll use a mock service that returns
placeholder suggestions, allowing the UI to be built and tested independently.

**Current state:**

- TerminalScreen displays blocks, terminal input, and modifier keys bar
- ViewMode controls display: split, fullTerminal, fullBlocks
- TerminalMode tracks TUI detection
- No AI-related UI exists

**Constraints:**

- Must not interfere with TUI mode (vim, htop)
- Must maintain 60fps animations on mid-range devices
- Must work in embedded mode (multi-session)
- Must integrate with existing Riverpod state management

## Goals / Non-Goals

**Goals:**

- Implement FAB widget with pulse animation and tap handling
- Implement bottom sheet panel with natural language input
- Implement suggestion display with confidence and explanation
- Connect Execute action to terminal input for command execution
- Provide mock AI service for UI development/testing

**Non-Goals:**

- Actual AI/LLM integration (separate change: ai-gateway)
- Cloud API configuration UI (separate change: cloud-ai-providers)
- Command history learning (separate change: command-history)
- Voice input (separate change: voice-input)

## Decisions

### D1: Use Stack overlay for FAB placement

**Decision:** Place FAB using Stack widget as an overlay on TerminalScreen
rather than modifying the Column layout.

**Rationale:**

- Avoids disturbing existing layout calculations
- Allows FAB to float over content without affecting block list scroll
- Simpler z-index management with Stack
- Can easily show/hide based on view mode

**Alternatives considered:**

- Modify Column to include FAB row: Would affect layout calculations and require
  more changes
- Use Overlay widget: More complex lifecycle management

### D2: Use showModalBottomSheet for panel

**Decision:** Use Flutter's built-in `showModalBottomSheet` with custom builder
for the Ghostwriter panel.

**Rationale:**

- Handles backdrop, dismissal gestures, and animations automatically
- Proven accessibility support (focus management, screen readers)
- Works well with keyboard appearance
- Can customize appearance while getting behavior for free

**Alternatives considered:**

- Custom draggable sheet: More control but more implementation effort
- Full-screen modal: Doesn't match the "partial overlay" design

### D3: Create dedicated AI feature module

**Decision:** Create new feature module at `lib/features/ai/` to house
AI-related widgets and providers.

**Rationale:**

- Clean separation from terminal feature
- Allows AI feature to evolve independently
- Clear ownership of AI-related code
- Follows existing feature-based architecture

**Structure:**

```
lib/features/ai/
├── domain/
│   └── entities/
│       ├── ai_suggestion.dart
│       └── ai_privacy_mode.dart
├── data/
│   └── services/
│       └── mock_ai_service.dart
└── presentation/
    ├── providers/
    │   ├── ai_panel_provider.dart
    │   └── ai_suggestion_provider.dart
    └── widgets/
        ├── ai_fab.dart
        ├── ai_ghostwriter_panel.dart
        └── ai_command_suggestion.dart
```

### D4: Riverpod providers for state management

**Decision:** Use Riverpod providers for panel visibility, input state, and
suggestion state.

**Providers:**

- `aiPanelVisibleProvider`: StateProvider<bool> for panel open/close
- `aiInputProvider`: StateProvider<String> for natural language input
- `aiSuggestionProvider`: FutureProvider that watches input and returns
  suggestion
- `aiPrivacyModeProvider`: StateProvider<AiPrivacyMode> for local/cloud
  indicator

**Rationale:**

- Consistent with existing Bento architecture
- FutureProvider handles async suggestion generation naturally
- Easy to test with provider overrides

### D5: Mock AI service for initial implementation

**Decision:** Create MockAiService that returns hardcoded suggestions based on
keyword matching.

**Rationale:**

- Allows UI development without AI backend
- Easy to test various states (loading, success, error)
- Can be swapped for real AI gateway later via dependency injection

**Mock behavior:**

- Delay 500-1500ms to simulate processing
- Match keywords like "list", "find", "show", "delete" to common commands
- Return confidence scores based on keyword match strength

### D6: AI colors as theme extension

**Decision:** Add AI-specific colors to theme system rather than hardcoding.

**Colors:**

- `aiPrimary`: Purple (#BD93F9) for main AI accent
- `aiSecondary`: Muted purple for secondary elements
- `aiGlow`: Semi-transparent purple for glow effects

**Rationale:**

- Consistent with existing theme system
- Allows future theming of AI elements
- Single source of truth for AI colors

## Risks / Trade-offs

### R1: FAB may obscure important content

**Risk:** FAB positioned over block list may hide important information.
**Mitigation:**

- Position FAB in corner with adequate padding
- Add option in settings to hide FAB (future enhancement)
- FAB is small (56x56) and semi-transparent when inactive

### R2: Bottom sheet keyboard interaction

**Risk:** Keyboard appearing may cause layout jumps or obscure input.
**Mitigation:**

- Use `isScrollControlled: true` in showModalBottomSheet
- Let Flutter handle keyboard insets automatically
- Test on both iOS and Android for keyboard behavior

### R3: Mock service doesn't represent real AI latency

**Risk:** UI may feel different when connected to real AI. **Mitigation:**

- Add configurable delay to mock service
- Include loading states that work for variable latency
- Design for worst-case latency (3-5 seconds)

### R4: Accessibility for animated FAB

**Risk:** Pulse animation may be distracting for users with vestibular
disorders. **Mitigation:**

- Respect `MediaQuery.disableAnimations`
- Keep animation subtle (opacity only, no movement)
- Provide clear semantic label for screen readers

## Open Questions

1. **Should FAB position be configurable?** (left vs right) - Defer to future
   enhancement
2. **Should we show recent AI suggestions?** - Out of scope for this change
3. **Haptic feedback pattern for different actions?** - Use standard medium
   impact for now
