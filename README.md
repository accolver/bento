# Bento

A modern mobile terminal emulator for iOS and Android with AI-powered features,
built with Flutter.

## Features

- Full terminal emulation with xterm.js-compatible rendering
- SSH connectivity with key-based authentication
- Semantic block-based output organization
- AI-powered command suggestions and error healing
- Multiple session tabs
- Secure credential storage

## Requirements

- Flutter 3.19.0 or higher
- Dart SDK 3.3.0 or higher
- iOS 14+ / Android API 24+

## Getting Started

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/bento.git
   cd bento
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (required after changes to models/providers):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Build Commands

| Command                       | Description                              |
| ----------------------------- | ---------------------------------------- |
| `flutter pub get`             | Install dependencies                     |
| `flutter analyze`             | Run static analysis                      |
| `flutter test`                | Run unit and widget tests                |
| `flutter test --coverage`     | Run tests with coverage                  |
| `dart run build_runner build` | Generate code (freezed, riverpod, drift) |
| `dart run build_runner watch` | Watch mode for code generation           |
| `flutter build ios`           | Build iOS release                        |
| `flutter build apk`           | Build Android APK                        |

## Architecture

Bento uses **Clean Architecture** with feature-based modules:

```
lib/
├── main.dart                 # App entry point
├── app/                      # App-level configuration
│   ├── app.dart              # MaterialApp widget
│   ├── router.dart           # Navigation (go_router)
│   └── theme.dart            # Theme definitions
├── core/                     # Shared infrastructure
│   ├── constants/            # App-wide constants
│   ├── errors/               # Failure and exception types
│   ├── extensions/           # Dart extensions
│   ├── utils/                # Utility functions
│   └── di/                   # Global dependency injection
├── features/                 # Feature modules
│   └── <feature>/
│       ├── data/             # Repositories, data sources, models
│       ├── domain/           # Entities, interfaces, use cases
│       └── presentation/     # Providers, screens, widgets
├── shared/                   # Shared components
│   ├── widgets/              # Reusable widgets
│   └── services/             # Shared services
└── database/                 # Drift database
    ├── database.dart         # Database class
    ├── tables/               # Table definitions
    └── daos/                 # Data access objects
```

### Key Patterns

- **State Management**: Riverpod 3.x with code generation (`@riverpod`)
- **Navigation**: go_router with declarative routes
- **Database**: Drift with type-safe queries and migrations
- **Error Handling**: `Either<Failure, T>` pattern using fpdart
- **Immutable Models**: Freezed with JSON serialization

## Code Generation

This project uses several code generators:

| Generator            | Purpose                | Annotation            |
| -------------------- | ---------------------- | --------------------- |
| `freezed`            | Immutable data classes | `@freezed`            |
| `json_serializable`  | JSON serialization     | `@JsonSerializable()` |
| `riverpod_generator` | Type-safe providers    | `@riverpod`           |
| `drift_dev`          | Database code          | `@DriftDatabase`      |

### Running Code Generation

After modifying files with these annotations, regenerate:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (recommended during development)
dart run build_runner watch --delete-conflicting-outputs
```

Generated files:

- `*.g.dart` - JSON serialization, Riverpod providers
- `*.freezed.dart` - Freezed data classes
- `*.drift.dart` - Drift database code

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/terminal/domain/entities/terminal_config_test.dart

# Run integration tests
flutter test integration_test/
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Coding standards
- Pull request process
- Testing requirements

## License

Proprietary - All rights reserved
