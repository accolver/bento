# Spec: terminal-view

GPU-accelerated terminal widget using xterm package.

## ADDED Requirements

### Requirement: Terminal widget renders terminal output

The TerminalView widget SHALL render terminal output using the xterm package's
Terminal widget with GPU acceleration at 60fps.

#### Scenario: Widget displays terminal content

- **WHEN** TerminalView is mounted with a Terminal instance
- **THEN** terminal output is rendered in the widget area

#### Scenario: Widget updates on new output

- **WHEN** new text is written to the terminal
- **THEN** the display updates within 16ms (60fps target)

### Requirement: Terminal uses configured font

The TerminalView widget SHALL use JetBrains Mono font at the configured size for
all terminal text rendering.

#### Scenario: Font is applied correctly

- **WHEN** TerminalView renders text
- **THEN** text uses JetBrains Mono font family

#### Scenario: Font size is configurable

- **WHEN** TerminalView is created with fontSize parameter
- **THEN** terminal text renders at that font size

### Requirement: Terminal supports scrollback buffer

The TerminalView widget SHALL maintain a scrollback buffer allowing users to
scroll through previous terminal output.

#### Scenario: User scrolls up to see history

- **WHEN** user swipes up on terminal
- **THEN** previous terminal output becomes visible

#### Scenario: Scrollback has configurable limit

- **WHEN** scrollback buffer exceeds configured limit
- **THEN** oldest lines are removed to maintain limit

### Requirement: Terminal supports text selection

The TerminalView widget SHALL allow users to select text by long-pressing and
dragging.

#### Scenario: User selects text

- **WHEN** user long-presses and drags across terminal text
- **THEN** selected text is highlighted

#### Scenario: Selected text can be copied

- **WHEN** user selects text and triggers copy action
- **THEN** selected text is copied to system clipboard

### Requirement: Terminal adapts to container size

The TerminalView widget SHALL fill its container and calculate appropriate
terminal dimensions (columns and rows) based on available space.

#### Scenario: Widget fills available space

- **WHEN** TerminalView is placed in a container
- **THEN** widget expands to fill the container

#### Scenario: Dimensions calculated from size

- **WHEN** container size is 400x600 pixels with 14pt font
- **THEN** terminal calculates appropriate cols/rows for that space
