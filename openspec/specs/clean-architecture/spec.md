# Spec: clean-architecture

## ADDED Requirements

### Requirement: Feature-based directory structure

The project SHALL use feature-based Clean Architecture with lib/core/,
lib/features/, lib/shared/, and lib/database/ directories.

#### Scenario: Core directory structure exists

- **WHEN** examining lib/ directory
- **THEN** directories exist: `core/`, `features/`, `shared/`, `database/`

#### Scenario: Core subdirectories configured

- **WHEN** examining lib/core/ directory
- **THEN** subdirectories exist: `constants/`, `errors/`, `extensions/`,
  `utils/`, `di/`

### Requirement: Error handling types defined

The project SHALL define Failure base class and common failure types using
fpdart's Either pattern.

#### Scenario: Failure types exist

- **WHEN** examining lib/core/errors/failures.dart
- **THEN** a sealed Failure class is defined
- **AND** common failure types (ServerFailure, CacheFailure, etc.) are defined

### Requirement: App configuration in lib/app

The project SHALL have app configuration files in lib/app/ including app.dart,
router.dart, and theme.dart.

#### Scenario: App directory contains configuration

- **WHEN** examining lib/app/ directory
- **THEN** files exist: `app.dart`, `router.dart`, `theme.dart`
