# Capability: block-streaming

Real-time output streaming and block detection.

## ADDED Requirements

### Requirement: Output streaming to block

The system SHALL stream SSH/terminal output into the currently active block in
real-time as data arrives.

#### Scenario: Stream output during command execution

- **WHEN** output data arrives from the SSH session
- **THEN** the data is appended to the active block's output
- **AND** the UI updates to show new content

#### Scenario: Batch output updates

- **WHEN** output arrives rapidly (faster than frame rate)
- **THEN** output is buffered and applied in batches
- **AND** UI updates at most once per frame (~16ms)

### Requirement: Prompt detection for block boundaries

The system SHALL detect shell prompts to identify when a new command is being
entered, creating a new block.

#### Scenario: Detect bash prompt

- **WHEN** output contains a pattern matching `user@host:path$`
- **THEN** current block is marked complete
- **AND** new block creation is prepared for next command

#### Scenario: Detect zsh prompt

- **WHEN** output contains a pattern matching `%` prompt indicator
- **THEN** current block is marked complete

#### Scenario: Handle custom prompts

- **WHEN** prompt pattern is configured in settings
- **THEN** that pattern is used for detection

### Requirement: Command extraction

The system SHALL extract the command text from the detected prompt line to store
in the new block.

#### Scenario: Extract command after prompt

- **WHEN** user types a command after a detected prompt
- **THEN** the command text (excluding prompt) is captured
- **AND** stored as the new block's command property

#### Scenario: Handle multi-line commands

- **WHEN** command spans multiple lines (continuation with \)
- **THEN** the full command including continuations is captured

### Requirement: Exit code detection

The system SHALL detect command exit codes to set block status correctly.

#### Scenario: Detect successful exit

- **WHEN** command completes and prompt returns
- **AND** exit code is 0 (detected via $? or prompt indication)
- **THEN** block status is set to success

#### Scenario: Detect failed exit

- **WHEN** command completes and prompt returns
- **AND** exit code is non-zero
- **THEN** block status is set to failed
- **AND** exit code is stored in block

### Requirement: Ctrl+C cancellation detection

The system SHALL detect when a command is interrupted by Ctrl+C.

#### Scenario: Command cancelled

- **WHEN** user sends Ctrl+C during command execution
- **AND** output shows ^C or interrupt indication
- **THEN** block status is set to cancelled

### Requirement: Block persistence

The system SHALL persist blocks to SQLite database for history.

#### Scenario: Save block to database

- **WHEN** a block is completed (status changes from running)
- **THEN** block is saved to the blocks database table

#### Scenario: Load blocks from database

- **WHEN** session is resumed or app restarts
- **THEN** blocks are loaded from database
- **AND** displayed in the session view

### Requirement: Output size management

The system SHALL manage memory usage by limiting in-memory output size.

#### Scenario: Large output truncation

- **WHEN** block output exceeds 100KB in memory
- **THEN** older output is truncated from in-memory representation
- **AND** full output remains in database
- **AND** UI shows indicator that output is truncated

#### Scenario: Retrieve full output on demand

- **WHEN** user requests full output for truncated block
- **THEN** full output is loaded from database
