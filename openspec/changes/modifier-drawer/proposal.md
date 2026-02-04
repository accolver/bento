# Proposal: Modifier Drawer

## Why

Touch keyboards lack modifier keys (Ctrl, Alt) that are essential for terminal
use. The Modifier Drawer provides gesture-activated access to special keys and
common combinations like Ctrl+C, eliminating awkward key combinations on virtual
keyboards.

## What Changes

- Create ModifierDrawer widget with swipe-up activation
- Implement modifier keys (Ctrl, Alt, Esc, Tab, Shift)
- Add arrow keys for cursor navigation
- Add quick combos (Ctrl+C, Ctrl+D, Ctrl+Z, Ctrl+L, Ctrl+R)
- Implement modifier state management (sticky modifiers)
- Add haptic feedback on key press
- Support gesture customization in settings
- Auto-release modifiers after keypress

## Capabilities

### New Capabilities

- `modifier-drawer`: Slide-up modifier panel
- `modifier-keys`: Ctrl, Alt, Esc, Tab, arrows
- `quick-combos`: One-tap common combinations
- `haptic-feedback`: Tactile response

## Impact

- `lib/features/terminal/presentation/widgets/modifier_drawer.dart`: Drawer
  widget
- `lib/features/terminal/presentation/providers/modifier_provider.dart`:
  Modifier state
- `lib/features/settings/domain/entities/gesture_config.dart`: Gesture settings

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `terminal-emulation`: Sends keys to terminal

## Phase

**Phase 1 - MVP** (Weeks 11-12)

## Priority

**P1 - Should Have**
