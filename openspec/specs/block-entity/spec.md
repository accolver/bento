# Capability: block-entity

Immutable block data model representing a command/output pair.

## ADDED Requirements

### Requirement: Block data structure

The system SHALL define a Block entity using freezed for immutability with the
following properties:

- `id`: Unique identifier (String, UUID)
- `sessionId`: Reference to parent session (String)
- `command`: The command text entered by user (String)
- `output`: The command output including ANSI sequences (String)
- `status`: Current block status (BlockStatus enum)
- `exitCode`: Process exit code when completed (int, nullable)
- `startedAt`: Timestamp when command was entered (DateTime)
- `completedAt`: Timestamp when command finished (DateTime, nullable)
- `isCollapsed`: Whether block is collapsed in UI (bool, default false)

#### Scenario: Create new block

- **WHEN** a new command is detected in the terminal
- **THEN** a Block instance is created with:
  - Generated UUID for id
  - Current session's sessionId
  - The detected command text
  - Empty output string
  - Status set to `running`
  - exitCode as null
  - startedAt as current timestamp
  - completedAt as null
  - isCollapsed as false

#### Scenario: Block immutability

- **WHEN** any property of a Block needs to be updated
- **THEN** a new Block instance is created via copyWith
- **AND** the original Block remains unchanged

### Requirement: BlockStatus enumeration

The system SHALL define a BlockStatus enum with values:

- `running`: Command is currently executing
- `success`: Command completed with exit code 0
- `failed`: Command completed with non-zero exit code
- `cancelled`: Command was interrupted (e.g., Ctrl+C)

#### Scenario: Status values

- **WHEN** BlockStatus enum is accessed
- **THEN** all four values (running, success, failed, cancelled) are available

### Requirement: Block JSON serialization

The system SHALL support JSON serialization for Block entities to enable
database storage and debugging.

#### Scenario: Serialize block to JSON

- **WHEN** toJson() is called on a Block
- **THEN** a valid JSON map is returned with all properties

#### Scenario: Deserialize block from JSON

- **WHEN** Block.fromJson() is called with a valid JSON map
- **THEN** a Block instance is created with matching properties

### Requirement: Block equality

The system SHALL implement value equality for Block entities based on all
properties.

#### Scenario: Equal blocks

- **WHEN** two Block instances have identical property values
- **THEN** they are considered equal (== returns true)

#### Scenario: Unequal blocks

- **WHEN** two Block instances differ in any property
- **THEN** they are considered unequal (== returns false)
