# Spec: flutter-project

## ADDED Requirements

### Requirement: Valid Flutter project structure

The project SHALL be a valid Flutter project with pubspec.yaml containing all
required dependencies as specified in the PRD.

#### Scenario: Project builds successfully

- **WHEN** running `flutter pub get`
- **THEN** all dependencies resolve without errors

#### Scenario: All PRD dependencies present

- **WHEN** examining pubspec.yaml
- **THEN** all packages from PRD Section 4.2 are present with correct versions

### Requirement: Dart SDK and Flutter version constraints

The project SHALL specify SDK constraints of `>=3.3.0 <4.0.0` and Flutter
`>=3.19.0`.

#### Scenario: SDK constraints configured

- **WHEN** examining pubspec.yaml environment section
- **THEN** sdk constraint is ">=3.3.0 <4.0.0"
- **AND** flutter constraint is ">=3.19.0"

### Requirement: Asset directories configured

The project SHALL configure asset directories for icons, fonts, and AI models.

#### Scenario: Assets declared in pubspec

- **WHEN** examining pubspec.yaml flutter section
- **THEN** assets include `assets/icons/`, `assets/fonts/`, `assets/models/`

#### Scenario: Asset directories exist

- **WHEN** examining project structure
- **THEN** directories `assets/icons/`, `assets/fonts/`, `assets/models/` exist

### Requirement: JetBrains Mono font configured

The project SHALL include JetBrains Mono font for terminal display.

#### Scenario: Font family declared

- **WHEN** examining pubspec.yaml fonts section
- **THEN** JetBrainsMono family is declared with regular and bold weights
