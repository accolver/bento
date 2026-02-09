## ADDED Requirements

### Requirement: View mode preference storage

The system SHALL store the user's preferred view mode (split, fullTerminal,
fullBlocks) as part of the saved connection record in the database.

#### Scenario: Default value for new connections

- **WHEN** a new connection is created without specifying a view mode preference
- **THEN** the connection SHALL have a default view mode of 'split'

#### Scenario: View mode persisted on change

- **WHEN** the user changes the view mode while connected to a saved connection
- **THEN** the system SHALL immediately save the new view mode to that
  connection's record

#### Scenario: Invalid view mode value in database

- **WHEN** the database contains an unrecognized view mode string
- **THEN** the system SHALL fall back to 'split' as the default

### Requirement: View mode restoration on connect

The system SHALL restore the user's saved view mode preference when they connect
to a saved connection.

#### Scenario: Reconnecting to saved connection

- **WHEN** the user connects to a saved connection that has a stored view mode
  preference
- **THEN** the system SHALL automatically set the view mode to the saved
  preference

#### Scenario: Connecting to saved connection with no preference

- **WHEN** the user connects to a saved connection that has no view mode
  preference stored
- **THEN** the system SHALL use the default view mode of 'split'

#### Scenario: Quick connect without saved connection

- **WHEN** the user performs a quick connect (not using a saved connection)
- **THEN** the system SHALL use the current in-memory view mode (no preference
  loaded from storage)

### Requirement: Database schema for view mode

The system SHALL store view mode preferences in the `saved_connections` table
using a text column.

#### Scenario: Schema migration from version 4

- **WHEN** the app upgrades from database schema version 4 to version 5
- **THEN** the system SHALL add a `preferred_view_mode` column with default
  value 'split'

#### Scenario: Column allows null for legacy detection

- **WHEN** querying a connection's view mode preference
- **THEN** the column MAY be null to indicate the user has never explicitly set
  a preference

### Requirement: View mode values match enum

The system SHALL store view mode as the string representation of the ViewMode
enum.

#### Scenario: Valid view mode values

- **WHEN** storing a view mode preference
- **THEN** the value SHALL be one of: 'split', 'fullTerminal', 'fullBlocks'

#### Scenario: Enum-to-string conversion

- **WHEN** the user selects a view mode in the UI
- **THEN** the system SHALL convert the ViewMode enum to its string name for
  storage
