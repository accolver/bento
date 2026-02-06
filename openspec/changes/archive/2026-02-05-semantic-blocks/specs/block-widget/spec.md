# Capability: block-widget

Collapsible block UI component displaying command and output.

## ADDED Requirements

### Requirement: Block widget structure

The system SHALL render each Block as a Card widget containing:

- Header section with command text, status indicator, and timestamp
- Content section with terminal output (when expanded)
- Action bar with block operations
- Visual border indicating status

#### Scenario: Render expanded block

- **WHEN** a Block is displayed with isCollapsed=false
- **THEN** the header, full output content, and action bar are visible
- **AND** the block shows its full height

#### Scenario: Render collapsed block

- **WHEN** a Block is displayed with isCollapsed=true
- **THEN** only the header is visible
- **AND** the output content is hidden
- **AND** the block height is reduced to header only

### Requirement: Block header display

The system SHALL display in the block header:

- Command text (truncated with ellipsis if too long)
- Status icon matching BlockStatus
- Timestamp showing when command was entered
- Duration (for completed blocks)
- Collapse/expand chevron icon

#### Scenario: Header with running command

- **WHEN** a Block has status=running
- **THEN** the header shows a pulsing/animated indicator
- **AND** no duration is displayed

#### Scenario: Header with completed command

- **WHEN** a Block has status=success, failed, or cancelled
- **THEN** the header shows execution duration
- **AND** the status icon reflects the final status

### Requirement: Block content rendering

The system SHALL render block output using xterm Terminal widget to preserve
ANSI escape sequences, colors, and formatting.

#### Scenario: Render ANSI output

- **WHEN** block output contains ANSI color codes
- **THEN** the output displays with correct colors and styling

#### Scenario: Render plain text output

- **WHEN** block output contains no escape sequences
- **THEN** the output displays as plain monospace text

### Requirement: Collapse/expand animation

The system SHALL animate block height changes with a smooth transition when
toggling collapsed state.

#### Scenario: Collapse animation

- **WHEN** user taps collapse button on an expanded block
- **THEN** the block height animates from full to header-only
- **AND** the animation duration is approximately 200ms
- **AND** the animation uses ease-in-out curve

#### Scenario: Expand animation

- **WHEN** user taps expand button on a collapsed block
- **THEN** the block height animates from header-only to full
- **AND** the animation duration is approximately 200ms

### Requirement: Block tap interactions

The system SHALL support tapping on blocks for navigation and interaction.

#### Scenario: Tap collapsed block to expand

- **WHEN** user taps on a collapsed block's header
- **THEN** the block expands to show content

#### Scenario: Tap header chevron

- **WHEN** user taps the chevron icon in block header
- **THEN** the block toggles between collapsed and expanded states

### Requirement: Block list display

The system SHALL display blocks in a scrollable list with newest blocks at the
bottom (matching terminal scroll direction).

#### Scenario: Multiple blocks displayed

- **WHEN** session has multiple blocks
- **THEN** all blocks are shown in chronological order
- **AND** the list is scrollable

#### Scenario: Auto-scroll to active block

- **WHEN** a new block is created
- **THEN** the list scrolls to show the new block at bottom
- **AND** scrolling is animated smoothly
