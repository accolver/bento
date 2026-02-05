# Contributing to Bento

Thank you for your interest in contributing to Bento! This document outlines our
development standards and processes.

## Coding Standards

### Dart Style

We follow the
[Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with
these additions:

- **Line length**: 80 characters max
- **Imports**: Use relative imports within `lib/`, absolute for packages
- **Documentation**: All public APIs must have dartdoc comments

### Architecture Rules

1. **Feature Isolation**: Features should not import from other features
   directly
   - Use shared services or domain events for cross-feature communication

2. **Layer Dependencies**:
   - `presentation` can depend on `domain`
   - `data` can depend on `domain`
   - `domain` should not depend on `data` or `presentation`

3. **Provider Guidelines**:
   - Use `@riverpod` annotation for all providers
   - Prefer `AsyncNotifier` for stateful async operations
   - Use `keepAlive: true` sparingly (only for app-lifetime providers)

### Naming Conventions

| Type              | Convention           | Example                  |
| ----------------- | -------------------- | ------------------------ |
| Files             | snake_case           | `terminal_config.dart`   |
| Classes           | PascalCase           | `TerminalConfig`         |
| Functions/Methods | camelCase            | `validateToken()`        |
| Constants         | lowerCamelCase       | `defaultTimeout`         |
| Private members   | _camelCase           | `_internalState`         |
| Providers         | camelCase + Provider | `terminalConfigProvider` |

### File Organization

```dart
// 1. Dart imports
import 'dart:async';

// 2. Package imports
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 3. Relative imports
import '../domain/entities/terminal_config.dart';

// 4. Part directives (for generated files)
part 'terminal_provider.g.dart';
```

## Pull Request Process

### Before Submitting

1. **Run all checks locally**:
   ```bash
   flutter analyze
   flutter test
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Ensure code generation is up to date**:
   - Commit all `*.g.dart` and `*.freezed.dart` files
   - Don't commit `*.drift.dart` files (they're in `.gitignore`)

3. **Write meaningful commit messages**:
   ```
   feat(terminal): add cursor blink rate configuration

   - Add cursorBlinkRate field to TerminalConfig
   - Update TerminalView to use configurable blink rate
   - Add tests for blink rate validation
   ```

### PR Requirements

- [ ] All CI checks pass
- [ ] Code follows style guidelines
- [ ] New code has appropriate tests
- [ ] Documentation updated if needed
- [ ] No unrelated changes included

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code change that neither fixes nor adds
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Scopes:** `terminal`, `ssh`, `blocks`, `ai`, `auth`, `db`, `ci`, etc.

### Review Process

1. Create PR with clear description
2. Request review from at least one maintainer
3. Address feedback promptly
4. Squash commits before merge (if needed)

## Testing Requirements

### Test Coverage

- **Unit tests**: Required for all domain entities and use cases
- **Widget tests**: Required for custom widgets with business logic
- **Integration tests**: Required for critical user flows

### Test File Location

```
test/
├── unit/                    # Pure logic tests
├── widget/                  # Widget tests
├── features/
│   └── <feature>/
│       ├── domain/
│       │   ├── entities/    # Entity tests
│       │   └── usecases/    # Use case tests
│       ├── data/            # Repository tests
│       └── presentation/    # Provider/widget tests
└── integration_test/        # E2E tests
```

### Test Structure

Follow the Given-When-Then pattern:

```dart
void main() {
  group('TerminalConfig', () {
    test('should have sensible default values', () {
      // Given
      final config = TerminalConfig();
      
      // Then
      expect(config.fontSize, equals(14.0));
      expect(config.cursorBlink, isTrue);
    });
    
    test('should validate font size range', () {
      // When/Then
      expect(
        () => TerminalConfig(fontSize: 0),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### Mocking

Use `mocktail` for mocking dependencies:

```dart
import 'package:mocktail/mocktail.dart';

class MockTerminalRepository extends Mock implements TerminalRepository {}

void main() {
  late MockTerminalRepository mockRepo;
  
  setUp(() {
    mockRepo = MockTerminalRepository();
  });
  
  test('should return config from repository', () async {
    // Given
    when(() => mockRepo.getConfig())
        .thenAnswer((_) async => Right(TerminalConfig()));
    
    // When
    final result = await useCase.execute();
    
    // Then
    expect(result.isRight(), isTrue);
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/features/terminal/domain/entities/terminal_config_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests (requires emulator/device)
flutter test integration_test/
```

## Questions?

If you have questions about contributing, please open an issue or reach out to
the maintainers.
