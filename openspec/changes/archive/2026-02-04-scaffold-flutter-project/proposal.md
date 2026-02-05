# Proposal: Scaffold Flutter Project

## Why

Bento requires a properly structured Flutter project foundation before any
feature development can begin. This includes the Clean Architecture folder
structure, state management setup, navigation, database configuration, and CI/CD
pipelines. Without this scaffolding, all subsequent features cannot be
implemented.

This is the **critical path** - every other change depends on this being
complete.

## What Changes

- Initialize Flutter project with complete `pubspec.yaml` including all
  dependencies
- Set up Clean Architecture folder structure (`lib/core/`, `lib/features/`,
  `lib/shared/`, `lib/database/`)
- Configure Riverpod 3.x for async-first state management
- Configure go_router for declarative navigation with deep linking
- Configure Drift for type-safe SQLite with migrations
- Set up build_runner and code generation pipeline
- Configure linting with flutter_lints
- Set up GitHub Actions CI/CD workflows
- Add asset directories for icons, fonts, and AI models
- Create app entry point and MaterialApp configuration

## Capabilities

### New Capabilities

- `flutter-project`: Complete Flutter 3.19+ project structure
- `clean-architecture`: Feature-based modular architecture
- `state-management`: Riverpod providers and code generation
- `navigation`: go_router with deep link support
- `database`: Drift SQLite with type-safe queries
- `ci-cd`: GitHub Actions for build, test, and release

## Impact

- `pubspec.yaml`: New file with all dependencies
- `lib/main.dart`: App entry point
- `lib/app/`: App configuration, router, theme
- `lib/core/`: Shared utilities, errors, extensions
- `lib/features/`: Feature module structure (empty initially)
- `lib/shared/`: Shared widgets and services
- `lib/database/`: Drift database configuration
- `.github/workflows/`: CI/CD pipeline configuration
- `analysis_options.yaml`: Linting configuration

## Dependencies

None - this is the foundation.

## Phase

**Phase 1 - MVP** (Weeks 1-2)

## Priority

**P0 - Must Have**
