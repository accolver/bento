# AI FAB Specification

## ADDED Requirements

### Requirement: FAB displays on terminal screen

The AI floating action button SHALL be displayed on the terminal screen when
semantic blocks view is active, positioned in the bottom-right corner above the
keyboard/modifier bar area.

#### Scenario: FAB visible in blocks view

- **WHEN** user is on terminal screen with semantic blocks enabled
- **THEN** the AI FAB is visible in the bottom-right corner
- **AND** the FAB does not obscure terminal content

#### Scenario: FAB hidden in TUI mode

- **WHEN** user enters TUI mode (vim, htop, etc.)
- **THEN** the AI FAB is hidden to avoid obstructing full-screen applications

#### Scenario: FAB hidden in full terminal view

- **WHEN** user switches to full terminal view mode (no blocks)
- **THEN** the AI FAB is hidden

### Requirement: FAB has distinctive AI styling

The FAB SHALL have a gradient background (purple/magenta) with a chat/AI icon to
clearly indicate its AI-related function.

#### Scenario: FAB visual appearance

- **WHEN** the FAB is displayed
- **THEN** it has a purple-to-magenta gradient background
- **AND** displays an AI/chat icon in white
- **AND** has a subtle glow/shadow effect

### Requirement: FAB has pulse animation

The FAB SHALL have a subtle pulsing animation to draw attention without being
distracting.

#### Scenario: Pulse animation runs continuously

- **WHEN** the FAB is visible and idle
- **THEN** a subtle pulse animation plays on a 2-second loop
- **AND** the animation does not cause jank or performance issues

### Requirement: FAB opens ghostwriter panel on tap

The FAB SHALL open the AI Ghostwriter panel when tapped.

#### Scenario: Tap opens panel

- **WHEN** user taps the FAB
- **THEN** the AI Ghostwriter bottom sheet panel slides up
- **AND** haptic feedback is triggered

#### Scenario: Panel can be dismissed

- **WHEN** the AI panel is open
- **AND** user taps outside the panel or swipes down
- **THEN** the panel dismisses with a slide-down animation
