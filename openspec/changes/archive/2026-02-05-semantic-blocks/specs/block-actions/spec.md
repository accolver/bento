# Capability: block-actions

Block action buttons for copy, and other operations.

## ADDED Requirements

### Requirement: Copy command action

The system SHALL provide a "Copy Command" action that copies the block's command
text to the system clipboard.

#### Scenario: Copy command to clipboard

- **WHEN** user taps "Copy Command" action
- **THEN** the command text is copied to clipboard
- **AND** a snackbar confirms "Command copied"

### Requirement: Copy output action

The system SHALL provide a "Copy Output" action that copies the block's output
text to the system clipboard (without ANSI codes).

#### Scenario: Copy output to clipboard

- **WHEN** user taps "Copy Output" action
- **THEN** the output text is copied to clipboard with ANSI codes stripped
- **AND** a snackbar confirms "Output copied"

### Requirement: Copy all action

The system SHALL provide a "Copy All" action that copies both command and output
in a formatted manner.

#### Scenario: Copy command and output

- **WHEN** user taps "Copy All" action
- **THEN** clipboard contains command followed by output
- **AND** format is: "$ {command}\n{output}"
- **AND** a snackbar confirms "Copied to clipboard"

### Requirement: Re-run command action

The system SHALL provide a "Re-run" action that executes the block's command
again in the current session.

#### Scenario: Re-run command

- **WHEN** user taps "Re-run" action on a completed block
- **THEN** the command text is sent to the terminal
- **AND** a new block is created for the re-run

### Requirement: Action bar visibility

The system SHALL display action buttons in a compact bar below the output when
block is expanded.

#### Scenario: Action bar on expanded block

- **WHEN** a block is expanded
- **THEN** action buttons are visible below the output

#### Scenario: Action bar on collapsed block

- **WHEN** a block is collapsed
- **THEN** action buttons are hidden

### Requirement: Context menu actions

The system SHALL provide actions via long-press context menu as an alternative
to the action bar.

#### Scenario: Long press shows context menu

- **WHEN** user long-presses on a block
- **THEN** a context menu appears with all available actions

### Requirement: Collapse all action

The system SHALL provide a global action to collapse all blocks in the session.

#### Scenario: Collapse all blocks

- **WHEN** user triggers "Collapse All" from session menu
- **THEN** all blocks in the session are collapsed

### Requirement: Expand all action

The system SHALL provide a global action to expand all blocks in the session.

#### Scenario: Expand all blocks

- **WHEN** user triggers "Expand All" from session menu
- **THEN** all blocks in the session are expanded
