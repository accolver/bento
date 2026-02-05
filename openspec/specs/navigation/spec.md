# Spec: navigation

## ADDED Requirements

### Requirement: go_router configured for declarative navigation

The project SHALL use go_router for declarative routing with support for deep
linking.

#### Scenario: Router configuration exists

- **WHEN** examining lib/app/router.dart
- **THEN** a GoRouter instance is configured
- **AND** at least a root route "/" is defined

#### Scenario: Router provided via Riverpod

- **WHEN** examining router configuration
- **THEN** router is accessible via a Riverpod provider

### Requirement: MaterialApp uses GoRouter

The app widget SHALL use MaterialApp.router with the configured GoRouter.

#### Scenario: App uses router configuration

- **WHEN** examining lib/app/app.dart
- **THEN** MaterialApp.router is used
- **AND** routerConfig points to the GoRouter instance
