# Spec: terminal-resize

Dynamic terminal sizing and resize handling.

## ADDED Requirements

### Requirement: Terminal calculates dimensions from available space

The terminal SHALL calculate the number of columns and rows based on the
available widget space, font size, and line height.

#### Scenario: Initial dimensions calculated

- **WHEN** TerminalView is first rendered
- **THEN** terminal dimensions (cols/rows) are calculated from widget size

#### Scenario: Dimensions use font metrics

- **WHEN** calculating terminal dimensions
- **THEN** character width and height from font metrics are used

### Requirement: Terminal resizes on orientation change

The terminal SHALL recalculate dimensions when device orientation changes
between portrait and landscape.

#### Scenario: Portrait to landscape resize

- **WHEN** device rotates from portrait to landscape
- **THEN** terminal recalculates with new dimensions (more cols, fewer rows)

#### Scenario: Landscape to portrait resize

- **WHEN** device rotates from landscape to portrait
- **THEN** terminal recalculates with new dimensions (fewer cols, more rows)

### Requirement: Terminal resizes on keyboard show/hide

The terminal SHALL recalculate dimensions when the soft keyboard appears or
disappears, as this changes available vertical space.

#### Scenario: Keyboard shown reduces rows

- **WHEN** soft keyboard appears
- **THEN** terminal recalculates with reduced row count

#### Scenario: Keyboard hidden increases rows

- **WHEN** soft keyboard is dismissed
- **THEN** terminal recalculates with increased row count

### Requirement: Terminal notifies backend of size changes

The terminal SHALL notify the connected backend (e.g., SSH session) when
terminal dimensions change so it can send SIGWINCH.

#### Scenario: Resize notification sent

- **WHEN** terminal dimensions change
- **THEN** onResize callback is invoked with new cols/rows

#### Scenario: PTY dimensions updated

- **WHEN** resize notification is received by SSH session
- **THEN** PTY window size is updated on remote host

### Requirement: Terminal enforces minimum dimensions

The terminal SHALL enforce minimum dimensions to ensure usability even on very
small screens or with large fonts.

#### Scenario: Minimum columns enforced

- **WHEN** calculated columns would be less than 20
- **THEN** terminal uses 20 columns minimum

#### Scenario: Minimum rows enforced

- **WHEN** calculated rows would be less than 5
- **THEN** terminal uses 5 rows minimum

### Requirement: Terminal preserves content on resize

The terminal SHALL preserve visible content and scrollback buffer when resizing,
reflowing text appropriately.

#### Scenario: Content preserved on resize

- **WHEN** terminal dimensions change
- **THEN** existing content remains visible (may reflow)

#### Scenario: Cursor position maintained

- **WHEN** terminal dimensions change
- **THEN** cursor remains at logical position (may adjust for new dimensions)
