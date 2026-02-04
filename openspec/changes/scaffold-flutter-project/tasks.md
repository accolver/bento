# Tasks: Scaffold Flutter Project

## Overview

Implementation tasks for creating the complete Flutter project scaffold. All
tasks must be completed before any feature changes can be implemented.

## Prerequisites

- Flutter 3.19+ installed
- Dart 3.3+ installed
- Git repository initialized

---

## Task Groups

### TG1: Project Configuration

#### T1.1: Create pubspec.yaml

- [x] Create `pubspec.yaml` with project metadata
- [x] Add Flutter SDK constraints (>=3.19.0)
- [x] Add Dart SDK constraints (>=3.3.0 <4.0.0)
- [x] Add all runtime dependencies from PRD section 2.2
- [x] Add all dev dependencies for code generation
- [x] Configure asset directories
- [x] Configure font directories

**Dependencies from PRD:**

```yaml
# Core Flutter
flutter_hooks: ^0.20.0
# State Management
flutter_riverpod: ^2.4.0
riverpod_annotation: ^2.3.0
# Navigation
go_router: ^13.0.0
# Database
drift: ^2.14.0
sqlite3_flutter_libs: ^0.5.0
# Networking
dio: ^5.4.0
connectivity_plus: ^5.0.0
# SSH
dartssh2: ^2.13.0
# Functional
fpdart: ^1.1.0
# Serialization
freezed_annotation: ^2.4.0
json_annotation: ^4.8.0
# UI
flutter_animate: ^4.3.0
```

**Dev dependencies:**

```yaml
build_runner: ^2.4.0
freezed: ^2.4.0
json_serializable: ^6.7.0
riverpod_generator: ^2.3.0
drift_dev: ^2.14.0
flutter_lints: ^3.0.0
mocktail: ^1.0.0
```

#### T1.2: Create analysis_options.yaml

- [x] Extend flutter_lints/flutter.yaml
- [x] Configure strict mode settings
- [x] Add project-specific lint rules
- [x] Configure exclude paths for generated files

#### T1.3: Create build.yaml (optional)

- [ ] Configure build_runner options if needed
- [ ] Set up combined builder for efficiency

---

### TG2: Directory Structure

#### T2.1: Create lib/ structure

- [x] Create `lib/app/` directory
- [x] Create `lib/core/constants/` directory
- [x] Create `lib/core/errors/` directory
- [x] Create `lib/core/extensions/` directory
- [x] Create `lib/core/utils/` directory
- [x] Create `lib/core/di/` directory
- [x] Create `lib/features/` directory (empty placeholder)
- [x] Create `lib/shared/widgets/` directory
- [x] Create `lib/shared/services/` directory
- [x] Create `lib/database/tables/` directory
- [x] Create `lib/database/daos/` directory

#### T2.2: Create test/ structure

- [x] Create `test/unit/` directory
- [x] Create `test/widget/` directory
- [x] Create `integration_test/` directory

#### T2.3: Create assets/ structure

- [x] Create `assets/icons/` directory
- [x] Create `assets/fonts/` directory
- [x] Create `assets/models/` directory
- [x] Add `.gitkeep` to empty directories

---

### TG3: Core Application Files

#### T3.1: Create main.dart

- [x] Implement `main()` function
- [x] Initialize Flutter bindings
- [x] Initialize database
- [x] Set up ProviderScope
- [x] Run BentoApp widget

#### T3.2: Create app/app.dart

- [x] Create BentoApp ConsumerWidget
- [x] Configure MaterialApp.router
- [x] Set up theme
- [x] Configure router

#### T3.3: Create app/router.dart

- [x] Define GoRouter configuration
- [x] Set up initial route (placeholder home)
- [x] Configure error handling
- [x] Export router provider

#### T3.4: Create app/theme.dart

- [x] Define light theme
- [x] Define dark theme
- [x] Configure typography
- [x] Configure color scheme (terminal-friendly)

---

### TG4: Core Infrastructure

#### T4.1: Create core/errors/failures.dart

- [x] Define abstract Failure class
- [x] Implement ServerFailure
- [x] Implement NetworkFailure
- [x] Implement CacheFailure
- [x] Implement ValidationFailure
- [x] Implement UnknownFailure

#### T4.2: Create core/errors/exceptions.dart

- [x] Define ServerException
- [x] Define NetworkException
- [x] Define CacheException
- [x] Define ValidationException

#### T4.3: Create core/di/providers.dart

- [x] Create database provider
- [x] Create dio client provider
- [x] Create connectivity provider
- [x] Export all global providers

#### T4.4: Create core/constants/app_constants.dart

- [x] Define app name
- [x] Define version
- [x] Define default timeout values
- [x] Define cache duration constants

#### T4.5: Create core/extensions/context_extensions.dart

- [x] Add theme extension on BuildContext
- [x] Add navigator extension on BuildContext
- [x] Add media query extensions

---

### TG5: Database Setup

#### T5.1: Create database/database.dart

- [x] Define BentoDatabase class extending GeneratedDatabase
- [x] Configure database path
- [x] Set schema version to 1
- [x] Add migration strategy placeholder
- [x] Export database instance

#### T5.2: Create database tables placeholder

- [x] Create `database/tables/.gitkeep`
- [x] Add comment documenting where feature tables go

#### T5.3: Create database DAOs placeholder

- [x] Create `database/daos/.gitkeep`
- [x] Add comment documenting where feature DAOs go

---

### TG6: Shared Components

#### T6.1: Create shared/widgets/.gitkeep

- [x] Add placeholder for shared widgets

#### T6.2: Create shared/services/.gitkeep

- [x] Add placeholder for shared services

---

### TG7: CI/CD Configuration

#### T7.1: Create .github/workflows/ci.yml

- [x] Configure trigger on push/PR to main
- [x] Set up Flutter environment
- [x] Run `flutter pub get`
- [x] Run `flutter analyze`
- [x] Run `flutter test`
- [x] Cache pub dependencies

#### T7.2: Create .github/dependabot.yml (optional)

- [ ] Configure pub dependency updates
- [ ] Configure GitHub Actions updates

---

### TG8: Documentation

#### T8.1: Update README.md

- [ ] Add project description
- [ ] Add setup instructions
- [ ] Add build commands
- [ ] Add architecture overview
- [ ] Add code generation instructions

#### T8.2: Create CONTRIBUTING.md (optional)

- [ ] Document coding standards
- [ ] Document PR process
- [ ] Document testing requirements

---

## Verification Checklist

After all tasks complete:

- [x] `flutter pub get` succeeds
- [x] `flutter analyze` passes with no errors
- [x] `flutter test` runs (even if no tests yet)
- [x] `dart run build_runner build` succeeds
- [x] Project structure matches design.md
- [x] All imports resolve correctly

---

## Notes

- Generated files (`*.g.dart`, `*.freezed.dart`) should be gitignored initially
- Database tables will be added by feature changes
- Feature directories will be populated by subsequent changes
- CI workflow should pass on initial commit
