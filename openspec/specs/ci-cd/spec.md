# Spec: ci-cd

## ADDED Requirements

### Requirement: GitHub Actions CI workflow

The project SHALL have a GitHub Actions workflow for continuous integration that
runs on pull requests and pushes to main.

#### Scenario: CI workflow file exists

- **WHEN** examining .github/workflows/
- **THEN** ci.yml file exists

#### Scenario: CI runs Flutter analyze

- **WHEN** CI workflow executes
- **THEN** `flutter analyze` is run

#### Scenario: CI runs Flutter test

- **WHEN** CI workflow executes
- **THEN** `flutter test` is run

#### Scenario: CI verifies code generation

- **WHEN** CI workflow executes
- **THEN** `dart run build_runner build --delete-conflicting-outputs` is run
- **AND** git diff verifies no uncommitted changes

### Requirement: Analysis options configured

The project SHALL have analysis_options.yaml with flutter_lints rules.

#### Scenario: Analysis options exist

- **WHEN** examining analysis_options.yaml
- **THEN** file includes flutter_lints package
- **AND** strict analysis rules are enabled
