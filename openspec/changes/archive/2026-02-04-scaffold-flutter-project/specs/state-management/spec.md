# Spec: state-management

## ADDED Requirements

### Requirement: Riverpod configured with code generation

The project SHALL use flutter_riverpod with riverpod_annotation and
riverpod_generator for provider code generation.

#### Scenario: ProviderScope wraps app

- **WHEN** examining main.dart
- **THEN** MaterialApp is wrapped in ProviderScope

#### Scenario: build_runner generates provider code

- **WHEN** running `dart run build_runner build`
- **THEN** .g.dart files are generated for providers without errors

### Requirement: Global providers in core/di

The project SHALL define global providers in lib/core/di/providers.dart for
app-wide dependencies.

#### Scenario: providers.dart exists

- **WHEN** examining lib/core/di/
- **THEN** providers.dart file exists with Riverpod provider definitions
