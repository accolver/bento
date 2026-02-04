# Spec: terminal-input

Keyboard input handling with IME support for terminal.

## ADDED Requirements

### Requirement: Terminal accepts keyboard input

The TerminalView SHALL capture keyboard input and forward it to the terminal
backend for processing.

#### Scenario: Character input is captured

- **WHEN** user types a character on soft keyboard
- **THEN** character is sent to terminal backend

#### Scenario: Special keys are captured

- **WHEN** user presses special keys (Enter, Tab, Backspace, arrows)
- **THEN** appropriate escape sequence is sent to terminal backend

### Requirement: Terminal supports IME input

The TerminalView SHALL support Input Method Editor (IME) for languages that
require composition (CJK, etc.).

#### Scenario: IME composition is shown

- **WHEN** user enters IME composition mode
- **THEN** composition preview is displayed

#### Scenario: IME commit sends text

- **WHEN** user commits IME composition
- **THEN** committed text is sent to terminal backend

### Requirement: Terminal supports control sequences

The TerminalView SHALL send appropriate control sequences for modifier key
combinations (Ctrl+C, Ctrl+Z, etc.).

#### Scenario: Ctrl+C sends interrupt

- **WHEN** user presses Ctrl+C (via modifier key)
- **THEN** terminal sends ETX (0x03) character

#### Scenario: Ctrl+D sends EOF

- **WHEN** user presses Ctrl+D (via modifier key)
- **THEN** terminal sends EOT (0x04) character

#### Scenario: Ctrl+Z sends suspend

- **WHEN** user presses Ctrl+Z (via modifier key)
- **THEN** terminal sends SUB (0x1A) character

### Requirement: Terminal provides modifier key access

The TerminalView SHALL provide access to modifier keys (Ctrl, Alt, Esc) that are
not typically available on mobile soft keyboards.

#### Scenario: Virtual modifier keys available

- **WHEN** TerminalView is active
- **THEN** Ctrl, Alt, Esc modifier buttons are accessible

#### Scenario: Modifier state is toggleable

- **WHEN** user taps Ctrl modifier
- **THEN** next keypress includes Ctrl modifier

### Requirement: Terminal handles paste input

The TerminalView SHALL support pasting text from the system clipboard into the
terminal.

#### Scenario: Paste from clipboard

- **WHEN** user triggers paste action
- **THEN** clipboard text is sent to terminal as if typed

#### Scenario: Bracketed paste mode supported

- **WHEN** terminal has bracketed paste mode enabled
- **THEN** pasted text is wrapped in bracketed paste escape sequences
