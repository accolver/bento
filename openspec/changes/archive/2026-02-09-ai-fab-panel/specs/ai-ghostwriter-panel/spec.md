# AI Ghostwriter Panel Specification

## ADDED Requirements

### Requirement: Panel displays as bottom sheet

The AI Ghostwriter panel SHALL display as a modal bottom sheet that slides up
from the bottom of the screen, partially covering the terminal content.

#### Scenario: Panel slides up on open

- **WHEN** user taps the AI FAB
- **THEN** the panel slides up from the bottom with a smooth animation (250ms,
  ease-out)
- **AND** a semi-transparent backdrop appears behind the panel

#### Scenario: Panel height is appropriate

- **WHEN** the panel is displayed
- **THEN** it occupies approximately 60-70% of screen height
- **AND** the terminal content is visible but dimmed behind it

### Requirement: Panel has header with title and privacy indicator

The panel header SHALL display "AI Ghostwriter" title with an AI icon and a
privacy indicator showing whether processing is local or cloud-based.

#### Scenario: Header displays correctly

- **WHEN** the panel is open
- **THEN** the header shows "AI Ghostwriter" with an AI chat icon
- **AND** a privacy indicator badge shows "Local" (green) or "Cloud" (blue)
- **AND** a close button is available in the header

### Requirement: Panel has natural language input field

The panel SHALL contain a text input area where users can describe what they
want to do in natural language.

#### Scenario: Input field is focused on open

- **WHEN** the panel opens
- **THEN** the text input field is automatically focused
- **AND** the keyboard appears

#### Scenario: Input field has placeholder text

- **WHEN** the input field is empty
- **THEN** placeholder text reads "Describe what you want to do..."

#### Scenario: Input supports multi-line text

- **WHEN** user enters long text
- **THEN** the input field expands to accommodate multiple lines
- **AND** maximum height is constrained to prevent excessive growth

### Requirement: Panel displays AI suggestions

When the user has entered text and AI generates a suggestion, the panel SHALL
display the suggested command with explanation.

#### Scenario: Suggestion appears after input

- **WHEN** user enters natural language text
- **AND** pauses typing for 500ms (debounce)
- **THEN** a loading indicator appears briefly
- **AND** the AI suggestion is displayed below the input

#### Scenario: Suggestion shows command and explanation

- **WHEN** an AI suggestion is displayed
- **THEN** the suggested command is shown in monospace font with a distinct
  background
- **AND** a brief explanation of what the command does is shown below it

### Requirement: Panel has action buttons

The panel SHALL provide action buttons for interacting with the suggestion:
Regenerate, Edit, Copy, and Execute.

#### Scenario: Regenerate creates new suggestion

- **WHEN** user taps "Regenerate" button
- **THEN** a new suggestion is generated for the same input
- **AND** the previous suggestion is replaced

#### Scenario: Edit allows modification

- **WHEN** user taps "Edit" button
- **THEN** the suggested command becomes editable in the input field
- **AND** user can modify it before executing

#### Scenario: Copy copies to clipboard

- **WHEN** user taps "Copy" button
- **THEN** the suggested command is copied to clipboard
- **AND** a brief confirmation toast appears

#### Scenario: Execute runs the command

- **WHEN** user taps "Execute" button
- **THEN** the panel dismisses
- **AND** the command is sent to the terminal for execution
- **AND** a new block is created for the command

### Requirement: Panel dismisses on execution or cancel

The panel SHALL dismiss when the user executes a command, taps outside, or
swipes down.

#### Scenario: Dismiss on backdrop tap

- **WHEN** user taps the dimmed backdrop
- **THEN** the panel slides down and dismisses

#### Scenario: Dismiss on swipe down

- **WHEN** user swipes down on the panel header
- **THEN** the panel slides down and dismisses

#### Scenario: Dismiss on execute

- **WHEN** user taps Execute
- **THEN** the panel dismisses before the command runs
