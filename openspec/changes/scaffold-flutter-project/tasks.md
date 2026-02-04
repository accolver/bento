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

- [ ] Create `pubspec.yaml` with project metadata
- [ ] Add Flutter SDK constraints (>=3.19.0)
- [ ] Add Dart SDK constraints (>=3.3.0 <4.0.0)
- [ ] Add all runtime dependencies from PRD section 2.2
- [ ] Add all dev dependencies for code generation
- [ ] Configure asset directories
- [ ] Configure font directories

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
dartssh2: ^4.0.0
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
mockito: ^5.4.0
build_runner: ^2.4.0
```

#### T1.2: Create analysis_options.yaml

- [ ] Extend flutter_lints/flutter.yaml
- [ ] Configure strict mode settings
- [ ] Add project-specific lint rules
- [ ] Configure exclude paths for generated files

#### T1.3: Create build.yaml (optional)

- [ ] Configure build_runner options if needed
- [ ] Set up combined builder for efficiency

---

### TG2: Directory Structure

#### T2.1: Create lib/ structure

- [ ] Create `lib/app/` directory
- [ ] Create `lib/core/constants/` directory
- [ ] Create `lib/core/errors/` directory
- [ ] Create `lib/core/extensions/` directory
- [ ] Create `lib/core/utils/` directory
- [ ] Create `lib/core/di/` directory
- [ ] Create `lib/features/` directory (empty placeholder)
- [ ] Create `lib/shared/widgets/` directory
- [ ] Create `lib/shared/services/` directory
- [ ] Create `lib/database/tables/` directory
- [ ] Create `lib/database/daos/` directory

#### T2.2: Create test/ structure

- [ ] Create `test/unit/` directory
- [ ] Create `test/widget/` directory
- [ ] Create `integration_test/` directory

#### T2.3: Create assets/ structure

- [ ] Create `assets/icons/` directory
- [ ] Create `assets/fonts/` directory
- [ ] Create `assets/models/` directory
- [ ] Add `.gitkeep` to empty directories

---

### TG3: Core Application Files

#### T3.1: Create main.dart

- [ ] Implement `main()` function
- [ ] Initialize Flutter bindings
- [ ] Initialize database
- [ ] Set up ProviderScope
- [ ] Run BentoApp widget

#### T3.2: Create app/app.dart

- [ ] Create BentoApp ConsumerWidget
- [ ] Configure MaterialApp.router
- [ ] Set up theme
- [ ] Configure router

#### T3.3: Create app/router.dart

- [ ] Define GoRouter configuration
- [ ] Set up initial route (placeholder home)
- [ ] Configure error handling
- [ ] Export router provider

#### T3.4: Create app/theme.dart

- [ ] Define light theme
- [ ] Define dark theme
- [ ] Configure typography
- [ ] Configure color scheme (terminal-friendly)

---

### TG4: Core Infrastructure

#### T4.1: Create core/errors/failures.dart

- [ ] Define abstract Failure class
- [ ] Implement ServerFailure
- [ ] Implement NetworkFailure
- [ ] Implement CacheFailure
- [ ] Implement ValidationFailure
- [ ] Implement UnknownFailure

#### T4.2: Create core/errors/exceptions.dart

- [ ] Define ServerException
- [ ] Define NetworkException
- [ ] Define CacheException
- [ ] Define ValidationException

#### T4.3: Create core/di/providers.dart

- [ ] Create database provider
- [ ] Create dio client provider
- [ ] Create connectivity provider
- [ ] Export all global providers

#### T4.4: Create core/constants/app_constants.dart

- [ ] Define app name
- [ ] Define version
- [ ] Define default timeout values
- [ ] Define cache duration constants

#### T4.5: Create core/extensions/context_extensions.dart

- [ ] Add theme extension on BuildContext
- [ ] Add navigator extension on BuildContext
- [ ] Add media query extensions

---

### TG5: Database Setup

#### T5.1: Create database/database.dart

- [ ] Define BentoDatabase class extending GeneratedDatabase
- [ ] Configure database path
- [ ] Set schema version to 1
- [ ] Add migration strategy placeholder
- [ ] Export database instance

#### T5.2: Create database tables placeholder

- [ ] Create `database/tables/.gitkeep`
- [ ] Add comment documenting where feature tables go

#### T5.3: Create database DAOs placeholder

- [ ] Create `database/daos/.gitkeep`
- [ ] Add comment documenting where feature DAOs go

---

### TG6: Shared Components

#### T6.1: Create shared/widgets/.gitkeep

- [ ] Add placeholder for shared widgets

#### T6.2: Create shared/services/.gitkeep

- [ ] Add placeholder for shared services

---

### TG7: CI/CD Configuration

#### T7.1: Create .github/workflows/ci.yml

- [ ] Configure trigger on push/PR to main
- [ ] Set up Flutter environment
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Cache pub dependencies

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

- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` runs (even if no tests yet)
- [ ] `dart run build_runner build` succeeds
- [ ] Project structure matches design.md
- [ ] All imports resolve correctly

---

## Notes

- Generated files (`*.g.dart`, `*.freezed.dart`) should be gitignored initially
- Database tables will be added by feature changes
- Feature directories will be populated by subsequent changes
- CI workflow should pass on initial commit
