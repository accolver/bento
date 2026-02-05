# Tasks: Terminal Emulation

Implementation tasks for terminal emulation feature.

## 1. Domain Layer Setup

- [x] 1.1 Create terminal feature directory structure
- [x] 1.2 Create TerminalConfig entity with font, colors, dimensions
- [x] 1.3 Create TerminalRepository interface

## 2. Terminal Colors

- [x] 2.1 Create terminal_colors.dart with ANSI 256-color palette
- [x] 2.2 Define light theme color mappings
- [x] 2.3 Define dark theme color mappings

## 3. Font Assets

- [x] 3.1 Download JetBrains Mono font files (Regular, Bold)
- [x] 3.2 Add font files to assets/fonts/
- [x] 3.3 Register fonts in pubspec.yaml

## 4. Terminal Provider

- [x] 4.1 Create terminal_provider.dart with Terminal instance management
- [x] 4.2 Create terminal_config_provider.dart for configuration state
- [x] 4.3 Implement terminal lifecycle (create, dispose)

## 5. Terminal View Widget

- [x] 5.1 Create terminal_view.dart widget wrapping xterm TerminalView
- [x] 5.2 Configure font and colors from provider
- [x] 5.3 Implement text selection support
- [x] 5.4 Implement clipboard copy functionality

## 6. Terminal Sizing

- [x] 6.1 Implement dimension calculation from widget size
- [x] 6.2 Handle orientation change resize
- [x] 6.3 Handle keyboard show/hide resize
- [x] 6.4 Add onResize callback for PTY notification
- [x] 6.5 Enforce minimum dimensions (20 cols, 5 rows)

## 7. Terminal Input

- [x] 7.1 Configure keyboard input handling
- [x] 7.2 Implement IME support for composition
- [x] 7.3 Add virtual modifier keys (Ctrl, Alt, Esc)
- [x] 7.4 Implement paste from clipboard

## 8. Terminal Screen

- [x] 8.1 Create terminal_screen.dart with full-screen terminal
- [x] 8.2 Add route for terminal screen in router.dart
- [x] 8.3 Integrate modifier key bar UI

## 9. Testing

- [x] 9.1 Write unit tests for TerminalConfig entity
- [x] 9.2 Write unit tests for dimension calculations
- [x] 9.3 Write widget tests for TerminalView
