# Capability: TUI Session Blocks

Special block type for representing completed TUI sessions in the block history.

## ADDED Requirements

### Requirement: Create TUI session block on TUI mode entry

The system SHALL create a TUI session block when TUI mode is activated.

#### Scenario: Block created on TUI activation

- **WHEN** TUI mode is activated
- **THEN** a new TUI session block is created with status "running"

#### Scenario: Block captures triggering command

- **WHEN** TUI session block is created
- **AND** the command that triggered TUI mode is known
- **THEN** the block command field contains that command

#### Scenario: Block captures start time

- **WHEN** TUI session block is created
- **THEN** the block startedAt timestamp is recorded

### Requirement: TUI session block has distinct visual appearance

TUI session blocks SHALL be visually distinct from regular command blocks.

#### Scenario: Block displays TUI indicator

- **WHEN** TUI session block is rendered
- **THEN** a "TUI Session" label or icon is displayed

#### Scenario: Block does not show output content

- **WHEN** TUI session block is rendered
- **THEN** no output text is displayed (TUI content is not captured)

#### Scenario: Block header shows command

- **WHEN** TUI session block is rendered
- **THEN** the triggering command is displayed in the header

### Requirement: Complete TUI session block on TUI exit

The system SHALL complete the TUI session block when TUI mode is deactivated.

#### Scenario: Block status updated on normal exit

- **WHEN** TUI mode is deactivated via rmcup
- **THEN** TUI session block status changes to "success"

#### Scenario: Block captures duration

- **WHEN** TUI session block is completed
- **THEN** executionTime is calculated from startedAt to completion time

#### Scenario: Block captures exit code if available

- **WHEN** TUI mode is deactivated
- **AND** the exit code of the TUI application is available
- **THEN** block exitCode is set to that value

### Requirement: Handle interrupted TUI sessions

The system SHALL handle TUI sessions that are interrupted without normal exit.

#### Scenario: Block marked interrupted on disconnect

- **WHEN** SSH session disconnects while TUI mode is active
- **THEN** TUI session block status is set to "cancelled"

#### Scenario: Block marked interrupted on app termination

- **WHEN** app terminates while TUI mode is active
- **THEN** TUI session block status is set to "cancelled" (on next launch if
  recoverable)

### Requirement: TUI session blocks are collapsible

TUI session blocks SHALL support collapse/expand like regular blocks.

#### Scenario: Block can be collapsed

- **WHEN** user taps collapse on TUI session block
- **THEN** block collapses to header only

#### Scenario: Collapsed block shows summary

- **WHEN** TUI session block is collapsed
- **THEN** command and duration are visible

### Requirement: TUI session blocks are searchable

TUI session blocks SHALL be included in block search results.

#### Scenario: Search matches command text

- **WHEN** user searches for text matching TUI session command
- **THEN** TUI session block appears in search results

#### Scenario: Search does not match TUI content

- **WHEN** user searches for text that was displayed in TUI
- **THEN** TUI session block does NOT match (content not captured)

### Requirement: TUI session blocks are persisted

TUI session blocks SHALL be persisted to the database.

#### Scenario: Block saved to database

- **WHEN** TUI session block is created
- **THEN** block is persisted to SQLite database

#### Scenario: Block restored on app restart

- **WHEN** app restarts
- **THEN** TUI session blocks are loaded from database

#### Scenario: Block type distinguishable in database

- **WHEN** TUI session block is stored
- **THEN** it can be distinguished from regular blocks (via isTuiSession flag or
  type field)

### Requirement: TUI session blocks show helpful information

TUI session blocks SHALL display information helpful for understanding what
happened.

#### Scenario: Running block shows elapsed time

- **WHEN** TUI session block has status "running"
- **THEN** elapsed time since start is displayed (updating)

#### Scenario: Completed block shows total duration

- **WHEN** TUI session block has status "success" or "cancelled"
- **THEN** total duration is displayed

#### Scenario: Cancelled block indicates interruption

- **WHEN** TUI session block has status "cancelled"
- **THEN** block indicates the session was interrupted

### Requirement: TUI session blocks integrate with block list

TUI session blocks SHALL appear in the block list in chronological order with
other blocks.

#### Scenario: Block appears in order

- **WHEN** TUI session completes
- **THEN** block is positioned in block list by startedAt time

#### Scenario: Block scrollable with other blocks

- **WHEN** user scrolls through block history
- **THEN** TUI session blocks scroll with other blocks
