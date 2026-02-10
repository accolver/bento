# Capability: TUI View Switching

Dynamic switching between semantic blocks view and full-screen terminal view
based on TUI mode state.

## ADDED Requirements

### Requirement: Terminal screen supports multiple display modes

The terminal screen SHALL support three display modes: blocks mode (semantic
blocks with small terminal input), TUI mode (full-screen terminal), and classic
mode (full-screen terminal without blocks).

#### Scenario: Default mode is blocks mode

- **WHEN** terminal session starts with semantic blocks enabled
- **THEN** display mode is blocks mode

#### Scenario: Default mode is classic when blocks disabled

- **WHEN** terminal session starts with semantic blocks disabled
- **THEN** display mode is classic mode

### Requirement: Automatic switch to TUI mode on detection

The terminal screen SHALL automatically switch to TUI display mode when TUI mode
is detected.

#### Scenario: Switch to TUI mode on smcup

- **WHEN** TUI mode detector signals activation
- **THEN** display mode transitions to TUI mode

#### Scenario: View updates immediately

- **WHEN** display mode transitions to TUI mode
- **THEN** full-screen xterm view is displayed within 16ms (single frame)

### Requirement: Automatic switch from TUI mode on exit

The terminal screen SHALL automatically switch back to the previous display mode
when TUI mode is deactivated.

#### Scenario: Return to blocks mode from TUI

- **WHEN** TUI mode detector signals deactivation
- **AND** previous mode was blocks mode
- **THEN** display mode transitions back to blocks mode

#### Scenario: Return to classic mode from TUI

- **WHEN** TUI mode detector signals deactivation
- **AND** previous mode was classic mode
- **THEN** display mode transitions back to classic mode

### Requirement: TUI mode provides full-screen terminal

In TUI mode, the terminal view SHALL occupy the full available screen space,
excluding only system UI (status bar, navigation bar).

#### Scenario: Terminal fills available height

- **WHEN** display mode is TUI mode
- **THEN** terminal view height equals screen height minus system UI

#### Scenario: Terminal fills available width

- **WHEN** display mode is TUI mode
- **THEN** terminal view width equals full screen width

#### Scenario: Command ribbon is hidden

- **WHEN** display mode is TUI mode
- **THEN** command ribbon is not visible

#### Scenario: Block list is hidden

- **WHEN** display mode is TUI mode
- **THEN** block list view is not visible

### Requirement: Modifier drawer remains accessible in TUI mode

The modifier drawer SHALL remain accessible via gesture in TUI mode for sending
Ctrl, Alt, Esc, and other special keys.

#### Scenario: Swipe up reveals modifier drawer

- **WHEN** display mode is TUI mode
- **AND** user swipes up from bottom of screen
- **THEN** modifier drawer appears as overlay

#### Scenario: Modifier drawer does not affect terminal size

- **WHEN** modifier drawer is shown in TUI mode
- **THEN** terminal dimensions remain unchanged (drawer is overlay)

### Requirement: Keyboard handling in TUI mode

In TUI mode, all keyboard input SHALL go directly to the terminal without ribbon
interception.

#### Scenario: Characters sent directly to terminal

- **WHEN** display mode is TUI mode
- **AND** user types on soft keyboard
- **THEN** characters are sent directly to terminal backend

#### Scenario: No command completion suggestions

- **WHEN** display mode is TUI mode
- **THEN** command ribbon suggestions are not shown

### Requirement: Resize handling in TUI mode

In TUI mode, terminal resize events SHALL be properly propagated to both xterm
and the SSH PTY.

#### Scenario: Orientation change during TUI mode

- **WHEN** display mode is TUI mode
- **AND** device orientation changes
- **THEN** terminal dimensions are recalculated
- **AND** PTY window size is updated on remote host

#### Scenario: Keyboard show during TUI mode

- **WHEN** display mode is TUI mode
- **AND** soft keyboard appears
- **THEN** terminal dimensions are recalculated for reduced height
- **AND** PTY window size is updated on remote host

### Requirement: Session tabs visible during TUI mode

Session tab bar SHALL remain visible during TUI mode to allow switching
sessions.

#### Scenario: Tab bar visible

- **WHEN** display mode is TUI mode
- **THEN** session tab bar is visible at top of screen

#### Scenario: Tab switch from TUI mode

- **WHEN** display mode is TUI mode
- **AND** user taps different session tab
- **THEN** session switches
- **AND** new session maintains its own display mode

### Requirement: Visual continuity on mode switch

Switching between TUI mode and blocks mode SHALL maintain visual continuity of
terminal content.

#### Scenario: Terminal content preserved on TUI exit

- **WHEN** TUI mode transitions to blocks mode
- **THEN** terminal content from TUI session is not lost

#### Scenario: xterm scrollback preserved

- **WHEN** TUI mode transitions to blocks mode
- **THEN** xterm scrollback buffer contents are preserved

### Requirement: Mode state exposed to UI

The current display mode SHALL be exposed as a Riverpod provider for UI
components to observe.

#### Scenario: Provider emits current mode

- **WHEN** UI component watches display mode provider
- **THEN** current display mode is provided

#### Scenario: Provider updates on mode change

- **WHEN** display mode changes
- **THEN** all watching UI components are notified

### Requirement: Pause block detection during TUI mode

Block detection and output routing SHALL be paused during TUI mode.

#### Scenario: Output router paused

- **WHEN** display mode transitions to TUI mode
- **THEN** OutputRouter stops parsing output for blocks

#### Scenario: Output still flows to terminal

- **WHEN** OutputRouter is paused
- **THEN** SSH output still flows directly to xterm terminal

#### Scenario: Output router resumes on TUI exit

- **WHEN** display mode transitions from TUI mode
- **THEN** OutputRouter resumes parsing output for blocks
