# Proposal: AI FAB Panel

## Why

Mobile users need quick access to AI assistance for generating CLI commands from
natural language, but the AI interface must not obstruct the terminal workflow.
A floating action button (FAB) with a slide-up bottom sheet provides a
discoverable, always-accessible entry point while maintaining a clean terminal
interface when AI is not in use.

## What Changes

- Add a floating action button (FAB) positioned above the keyboard area on
  terminal screens
- Create a bottom sheet panel (AIGhostwriterPanel) that slides up when FAB is
  tapped
- Implement natural language input field with placeholder text guidance
- Display AI-generated command suggestions with confidence indicators
- Show brief explanations of suggested commands
- Add action buttons: Regenerate, Edit, Copy, Execute
- Include privacy indicator showing local vs cloud processing
- Add pulsing animation on FAB to indicate AI availability
- Integrate with existing terminal input flow for command execution

## Capabilities

### New Capabilities

- `ai-fab`: Floating action button widget with pulse animation and tap handling
- `ai-ghostwriter-panel`: Bottom sheet UI for natural language input and command
  suggestions
- `ai-command-suggestion`: Display component for showing generated commands with
  confidence scores and explanations

### Modified Capabilities

- `terminal-screen`: Add FAB overlay and panel integration to terminal screen
  layout

## Impact

- **UI**: New overlay elements on TerminalScreen, requires z-index management
- **Dependencies**: Will integrate with future AI Gateway (ai-gateway change)
  for actual command generation
- **State Management**: New Riverpod providers for panel visibility and
  suggestion state
- **Accessibility**: FAB and panel must support VoiceOver/TalkBack
- **Performance**: Bottom sheet animation must maintain 60fps
