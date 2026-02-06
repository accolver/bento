# AI Command Suggestion Specification

## ADDED Requirements

### Requirement: Suggestion displays generated command

The AI command suggestion component SHALL display the AI-generated CLI command
in a visually distinct container.

#### Scenario: Command displayed in monospace

- **WHEN** an AI suggestion is available
- **THEN** the command is displayed in JetBrains Mono font
- **AND** it has a dark background to distinguish it from regular text
- **AND** the command is selectable for manual copying

### Requirement: Suggestion shows confidence indicator

The suggestion SHALL display a confidence score indicating how certain the AI is
about the suggestion.

#### Scenario: High confidence displayed

- **WHEN** confidence is >= 90%
- **THEN** a green confidence badge shows the percentage

#### Scenario: Medium confidence displayed

- **WHEN** confidence is between 70% and 89%
- **THEN** a yellow confidence badge shows the percentage

#### Scenario: Low confidence displayed

- **WHEN** confidence is below 70%
- **THEN** an orange confidence badge shows the percentage
- **AND** a subtle warning indicator suggests reviewing the command

### Requirement: Suggestion shows explanation

The suggestion SHALL display a brief explanation of what the command does.

#### Scenario: Explanation displayed below command

- **WHEN** an AI suggestion is displayed
- **THEN** a 1-2 sentence explanation appears below the command
- **AND** the explanation uses the AI accent color (purple) for the left border

### Requirement: Suggestion supports loading state

The suggestion area SHALL show a loading indicator while the AI generates a
response.

#### Scenario: Loading indicator during generation

- **WHEN** user has entered text and AI is processing
- **THEN** a shimmer/skeleton loading animation is shown
- **AND** the loading state is clearly distinct from empty state

#### Scenario: Loading replaced by suggestion

- **WHEN** AI generation completes
- **THEN** the loading indicator is replaced by the suggestion
- **AND** the transition is smooth (fade)

### Requirement: Suggestion supports empty state

The suggestion area SHALL show appropriate messaging when no suggestion is
available.

#### Scenario: Empty state before input

- **WHEN** the input field is empty
- **THEN** no suggestion area is shown (only input visible)

#### Scenario: Error state on failure

- **WHEN** AI generation fails
- **THEN** an error message is displayed
- **AND** a "Try Again" button is available
