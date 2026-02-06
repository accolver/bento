# Terminal Screen Modification Specification

## MODIFIED Requirements

### Requirement: Terminal screen supports AI overlay

The terminal screen SHALL support displaying the AI FAB and Ghostwriter panel as
overlays without disrupting the existing terminal functionality.

#### Scenario: FAB displays in split view mode

- **WHEN** terminal is in split view mode (blocks + terminal input)
- **THEN** the AI FAB is displayed in the bottom-right corner
- **AND** it is positioned above the modifier keys bar
- **AND** it does not overlap with blocks or terminal content

#### Scenario: FAB hidden in TUI mode

- **WHEN** terminal switches to TUI mode (fullscreen terminal)
- **THEN** the AI FAB is automatically hidden
- **AND** when exiting TUI mode, the FAB reappears

#### Scenario: FAB hidden in full terminal mode

- **WHEN** user selects full terminal view mode
- **THEN** the AI FAB is hidden
- **AND** the FAB reappears when switching back to split or blocks view

#### Scenario: Panel overlays terminal content

- **WHEN** the AI Ghostwriter panel is open
- **THEN** the terminal content is visible but dimmed behind the panel
- **AND** terminal interaction is blocked until panel is dismissed
- **AND** keyboard focus moves to the panel input field
