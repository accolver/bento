# Spec: database

## ADDED Requirements

### Requirement: Drift database configured

The project SHALL configure Drift for type-safe SQLite database access with
migration support.

#### Scenario: Database class exists

- **WHEN** examining lib/database/database.dart
- **THEN** an AppDatabase class extending GeneratedDatabase exists
- **AND** schemaVersion is defined

#### Scenario: Database initialization code generated

- **WHEN** running `dart run build_runner build`
- **THEN** database.g.dart is generated without errors

### Requirement: Database directory structure

The project SHALL organize database code into tables/ and daos/ subdirectories.

#### Scenario: Database subdirectories exist

- **WHEN** examining lib/database/
- **THEN** directories exist: `tables/`, `daos/`

### Requirement: Database provided via Riverpod

The database instance SHALL be accessible via a Riverpod provider.

#### Scenario: Database provider exists

- **WHEN** examining lib/core/di/providers.dart
- **THEN** a provider for AppDatabase is defined
