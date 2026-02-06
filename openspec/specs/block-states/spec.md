# Capability: block-states

Visual status indicators for block states.

## ADDED Requirements

### Requirement: Running state indicator

The system SHALL indicate running blocks with:

- Blue left border (primary color)
- Pulsing/animated status icon
- No exit code displayed

#### Scenario: Display running block

- **WHEN** a Block has status=running
- **THEN** the block shows a blue left border
- **AND** the status icon animates (pulse or spinner)

### Requirement: Success state indicator

The system SHALL indicate successful blocks with:

- Green left border
- Checkmark status icon
- Exit code 0 (optionally displayed)

#### Scenario: Display successful block

- **WHEN** a Block has status=success
- **THEN** the block shows a green left border
- **AND** a checkmark icon is displayed

### Requirement: Failed state indicator

The system SHALL indicate failed blocks with:

- Red left border
- X or error status icon
- Exit code displayed (non-zero)

#### Scenario: Display failed block

- **WHEN** a Block has status=failed
- **THEN** the block shows a red left border
- **AND** an error icon is displayed
- **AND** the exit code is visible in the header

### Requirement: Cancelled state indicator

The system SHALL indicate cancelled blocks with:

- Yellow/amber left border
- Interrupted/cancelled status icon
- No exit code (or special indicator)

#### Scenario: Display cancelled block

- **WHEN** a Block has status=cancelled
- **THEN** the block shows a yellow left border
- **AND** a cancel/interrupted icon is displayed

### Requirement: Status colors configuration

The system SHALL use theme-aware colors for status indicators that work in both
light and dark modes.

#### Scenario: Light mode colors

- **WHEN** app is in light mode
- **THEN** status colors have sufficient contrast against light background

#### Scenario: Dark mode colors

- **WHEN** app is in dark mode
- **THEN** status colors have sufficient contrast against dark background

### Requirement: Collapsed state indicator

The system SHALL indicate collapsed blocks with:

- Chevron pointing right
- Output line count shown in header
- Muted/subtle appearance

#### Scenario: Collapsed block appearance

- **WHEN** a Block is collapsed
- **THEN** the chevron points right (indicating expandable)
- **AND** header shows output line count (e.g., "42 lines")

#### Scenario: Expanded block appearance

- **WHEN** a Block is expanded
- **THEN** the chevron points down
- **AND** full output is visible
