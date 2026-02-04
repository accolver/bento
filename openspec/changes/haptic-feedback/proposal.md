# Proposal: Haptic Feedback

## Why

Mobile terminals lose the tactile feedback of physical keyboards. Haptic
feedback restores confirmation cues - light taps for selections, medium impacts
for successful commands, double pulses for errors. This improves user
confidence, especially in critical operations.

## What Changes

- Define BentoHaptics utility class
- Implement feedback patterns: tap, success, error, selection
- Add double-pulse pattern for command failures
- Integrate haptics with command execution lifecycle
- Add haptics to modifier drawer interactions
- Integrate with ribbon tap events
- Support user preference to disable haptics
- Use flutter_haptic_feedback package

## Capabilities

### New Capabilities

- `haptic-tap`: Light impact for button taps
- `haptic-success`: Medium impact for completions
- `haptic-error`: Heavy double-pulse for failures
- `haptic-selection`: Selection click for ribbon
- `haptic-settings`: User preference toggle

## Impact

- `lib/core/haptics/bento_haptics.dart`: Haptic feedback utility
- `lib/features/settings/presentation/screens/settings_screen.dart`: Add toggle
- Integrate haptics throughout UI components

## Dependencies

- `terminal-emulation`: Haptics on command completion
- `modifier-drawer`: Haptics on modifier activation

## Phase

**Phase 1 - MVP** (Weeks 11-12 - Input System)

## Priority

**P2 - Nice to Have**

Improves touch experience but not required for core functionality.
