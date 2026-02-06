# Proposal: AI Error Healing UI

## Why

When commands fail, users often need to search for solutions manually.
Contextual error healing automatically detects failed commands and offers
one-tap fixes directly within the terminal block interface. This reduces
friction and speeds recovery by surfacing AI-powered fix suggestions exactly
when and where they're needed.

## What Changes

- Add error detection to BlockWidget for non-zero exit codes
- Create ErrorHealingBanner widget that appears below failed command blocks
- Display AI-generated fix explanation and suggested command
- Implement "Apply Fix" button that executes the fix command
- Add "Dismiss" button to hide the banner
- Include privacy indicator showing local vs cloud processing
- Add AI summary badges to successful command outputs (for verbose output)
- Animate banner appearance/dismissal for smooth UX

## Capabilities

### New Capabilities

- `error-healing-banner`: UI banner component displaying fix suggestions for
  failed commands
- `ai-output-summary`: Compact summary badge displayed below verbose command
  output
- `error-pattern-detection`: Client-side detection of common error patterns
  (permission denied, not found, syntax errors)

### Modified Capabilities

- `block-widget`: Integrate error healing banner display for failed blocks
- `block-list-view`: Support for inline healing banners between blocks

## Impact

- **UI**: New banner component inserted into block list, requires careful
  spacing
- **Dependencies**: Will integrate with future AI Gateway for fix generation;
  initially uses pattern-based suggestions
- **State Management**: New providers for healing suggestions per block
- **Accessibility**: Banner must announce fix availability to screen readers
- **Performance**: Error pattern detection must not delay block rendering
