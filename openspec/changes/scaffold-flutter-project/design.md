# Design: Scaffold Flutter Project

## Context

Bento is a greenfield Flutter mobile application targeting iOS and Android. The
project needs a solid architectural foundation that supports:

- Feature-based modular development
- Async-first state management with code generation
- Type-safe database operations with migrations
- Declarative navigation with deep linking
- Continuous integration and automated testing

The PRD specifies Flutter 3.19+, Dart 3.3+, and a specific set of packages
including Riverpod 3.x, go_router, Drift, and dartssh2.

**Constraints:**

- Must support iOS 14+ and Android API 24+
- Must use Impeller rendering engine for performance
- Dependencies locked to versions specified in PRD
- Project structure must support feature isolation

## Goals / Non-Goals

**Goals:**

- Create a complete, buildable Flutter project structure
- Establish Clean Architecture with clear separation of concerns
- Set up all code generation pipelines (freezed, riverpod, drift, json)
- Configure CI/CD for automated testing and builds
- Provide a foundation that all feature changes can build upon

**Non-Goals:**

- Implementing any features (terminal, blocks, connections)
- Creating actual screens or UI components
- Database table definitions (done in feature changes)
- Platform-specific native code (Mosh FFI, Tailscale queries)

## Decisions

### D1: Clean Architecture with Feature Modules

**Decision:** Use feature-based Clean Architecture with three layers per
feature.

```
lib/features/<feature>/
├── data/          # Repositories, data sources, models
├── domain/        # Entities, repository interfaces, use cases
└── presentation/  # Providers, screens, widgets
```

**Rationale:** Feature isolation allows parallel development and clear
boundaries. Each feature is self-contained with its own layers, reducing
coupling.

**Alternatives considered:**

- Single-layer architecture: Rejected - too coupled for a complex app
- Domain-Driven Design: Overkill for mobile app scope

### D2: Riverpod 3.x with Code Generation

**Decision:** Use `riverpod_annotation` and `riverpod_generator` for all
providers.

**Rationale:** Code generation provides compile-time safety, auto-dispose, and
cleaner syntax. Riverpod 3.x's `@riverpod` annotation eliminates boilerplate.

**Alternatives considered:**

- Provider package: Less capable for async operations
- Bloc: More boilerplate, less flexible

### D3: Drift for Database

**Decision:** Use Drift with DAOs per feature domain.

**Rationale:** Type-safe SQL queries, compile-time verification, and migration
support. DAOs provide clean boundaries between features and database.

**Alternatives considered:**

- sqflite: Raw SQL, no type safety
- Hive: Good for KV, but we need relational queries

### D4: go_router for Navigation

**Decision:** Use go_router with declarative routes and deep linking support.

**Rationale:** First-party Flutter package, supports deep links, and integrates
well with Riverpod for auth guards.

**Alternatives considered:**

- Navigator 2.0 directly: Too complex
- auto_route: Code generation adds complexity

### D5: Error Handling with fpdart

**Decision:** Use `Either<Failure, T>` pattern for operations that can fail.

**Rationale:** Explicit error handling, no exceptions for expected failures,
composable operations.

**Alternatives considered:**

- Exceptions: Hidden control flow, easy to forget handling
- Result package: fpdart is more feature-complete

## Risks / Trade-offs

**[Risk] Code generation complexity** Many packages require build_runner.
Initial setup is complex, but once configured, development is faster.

→ Mitigation: Document build commands, configure watch mode in development.

**[Risk] Large pubspec.yaml** Many dependencies from day one increases bundle
size and potential conflicts.

→ Mitigation: All versions locked to compatible set from PRD. Tree-shaking
removes unused code.

**[Risk] Learning curve** Clean Architecture and Riverpod 3.x patterns may be
unfamiliar to contributors.

→ Mitigation: Include example feature structure, document patterns in README.

## File Structure

```
bento/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app/
│   │   ├── app.dart              # MaterialApp widget
│   │   ├── router.dart           # go_router configuration
│   │   └── theme.dart            # Theme definitions
│   ├── core/
│   │   ├── constants/            # App-wide constants
│   │   ├── errors/               # Failure types
│   │   │   ├── failures.dart
│   │   │   └── exceptions.dart
│   │   ├── extensions/           # Dart extensions
│   │   ├── utils/                # Utility functions
│   │   └── di/                   # Global providers
│   │       └── providers.dart
│   ├── features/                 # Feature modules (empty initially)
│   ├── shared/
│   │   ├── widgets/              # Reusable widgets
│   │   └── services/             # Shared services
│   └── database/
│       ├── database.dart         # Drift database class
│       ├── tables/               # Table definitions
│       └── daos/                 # Data access objects
├── test/                         # Unit and widget tests
├── integration_test/             # Integration tests
├── assets/
│   ├── icons/
│   ├── fonts/
│   └── models/                   # AI model files (later)
├── .github/
│   └── workflows/
│       └── ci.yml                # CI workflow
├── pubspec.yaml
└── analysis_options.yaml
```
