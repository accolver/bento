# AI Agent Instructions

<!-- This file provides essential context and guardrails for AI coding assistants -->
<!-- working on the Bento codebase. Read this ENTIRE file before making changes. -->

---

# PROJECT OVERVIEW

## What is Bento?

**Bento** is a next-generation **mobile terminal application** built with
**Flutter** (Dart). It transforms the traditional terminal experience into an
organized, intelligent, and resilient interface for developers on mobile
devices.

The name references the Japanese bento box -- a meal organized into discrete,
digestible compartments -- reflecting the core UI paradigm of **Semantic
Blocks** (every command and its output is a discrete, collapsible, searchable
unit).

## Key Facts

- **Platform**: iOS and Android (mobile-only for v1.0, no desktop)
- **Framework**: Flutter >= 3.19.0, Dart SDK >= 3.3.0
- **License**: MIT (open source, no premium tier)
- **Architecture**: Clean Architecture with feature-based modules
- **State Management**: Riverpod (async-first with code generation)
- **Navigation**: go_router with deep linking
- **Database**: Drift (type-safe SQLite) for persistence
- **Connectivity**: dartssh2 (SSH), Mosh via FFI (planned)
- **AI**: Hybrid local/cloud with privacy-first design
- **Source of Truth**: `PRD.md` is the canonical product requirements document

## Core Differentiators

1. **Semantic Block Interface** -- command/output as discrete, navigable units
2. **Context-Aware Input** -- predictive ribbons, gesture modifiers, AI
   suggestions
3. **Resilient Connectivity** -- Mosh-first architecture surviving network
   transitions
4. **AI Ghostwriter** -- local-first intelligence for command generation, error
   healing, and output summarization

---

# SECURITY & PRIVACY PRINCIPLES

**These are non-negotiable requirements. Every AI agent MUST follow these rules
when writing code for Bento.**

Bento handles SSH private keys, server credentials, and terminal sessions to
remote infrastructure. Users trust Bento with access to their production
servers, homelabs, and cloud environments. Security failures here have
real-world consequences.

## Hard Rules

### 1. Credential Material NEVER Goes in the Database

- SSH private keys, passphrases, and passwords are stored ONLY in
  `flutter_secure_storage` (iOS Keychain / Android Keystore)
- The Drift/SQLite database stores ONLY non-sensitive **metadata** (name, type,
  fingerprint, timestamps)
- See: `lib/features/credentials/data/services/credential_vault.dart`
- See: `lib/database/tables/credential_metadata.dart`

### 2. Biometric Authentication Protects Key Access

- Retrieving SSH keys MUST require biometric authentication (Face ID, Touch ID,
  fingerprint) or device PIN fallback
- Per-credential biometric toggle exists -- respect user preferences
- Handle lockout states (`LockedOut`, `PermanentlyLockedOut`) gracefully
- See: `lib/features/credentials/data/services/biometric_service.dart`

### 3. Credentials Are Cleared on Background

- The credential cache has a TTL (5 minutes default) and clears automatically
  when the app goes to background via `WidgetsBindingObserver`
- NEVER persist decrypted credential material to disk, logs, or state that
  survives app lifecycle changes
- See: `lib/features/credentials/data/services/credential_cache.dart`

### 4. AI Privacy is a First-Class Concern

- Three privacy modes exist: `local` (on-device), `cloud` (external servers),
  `remote` (user-controlled server like Ollama)
- `local` and `remote` are considered **private** modes
- NEVER send terminal output, commands, or error messages to cloud AI providers
  without explicit user consent
- Error healing defaults to local processing (privacy: keep errors local)
- Cloud AI API keys are stored in secure storage, NOT in the database
- See: `lib/features/ai/domain/entities/ai_privacy_mode.dart`
- See: `lib/features/ai/domain/entities/ai_config.dart`

### 5. No Secrets in Code or Version Control

- `.gitignore` excludes: `*.env`, `*.env.*`, `credentials.json`, `secrets.yaml`
- NEVER hardcode API keys, tokens, passwords, or private keys in source code
- NEVER commit files containing secrets
- NEVER log credential material (private keys, passphrases, passwords)

### 6. SSH Security Standards

- Support RSA, Ed25519, and ECDSA key types
- Detect and handle encrypted private keys (passphrase-protected)
- Compute SHA-256 fingerprints for key identification
- SSH host key verification MUST be enforced (no blind trust)
- See: `lib/features/credentials/data/utils/ssh_key_utils.dart`

### 7. Planned Security Policies (Not Yet Implemented)

The following are defined in the PRD and the `security-policies` OpenSpec change
but are NOT yet implemented. When implementing these, follow the PRD spec:

| Policy              | Requirement                                        |
| ------------------- | -------------------------------------------------- |
| Session Timeout     | Clear keys after 5 minutes of inactivity           |
| Clipboard Security  | Auto-clear sensitive data from clipboard after 60s |
| Screen Capture      | `FLAG_SECURE` on credential/key screens            |
| Certificate Pinning | Pin certificates for cloud AI API endpoints        |
| Device Integrity    | Root/jailbreak detection (warn, don't block)       |
| Secure Memory       | Zero out key material in memory after use          |
| Local AI Sandboxing | Run local LLM models in sandboxed process          |

## Security Review Checklist

Before committing ANY code that touches credentials, keys, auth, or AI data:

- [ ] Credential material stays in `flutter_secure_storage` only?
- [ ] No secrets logged (check `logger` calls, `print` statements)?
- [ ] Biometric auth required before key access?
- [ ] AI privacy mode respected before sending data externally?
- [ ] No hardcoded keys, tokens, or passwords?
- [ ] Cache/memory cleared on background lifecycle?
- [ ] Error messages don't leak key material or server details?

---

# ARCHITECTURE CONTEXT

## Clean Architecture Layers

```
lib/
  main.dart                           # App entry point
  app/                                # App config, routing, theme
  core/                               # Shared: constants, errors, extensions, DI, utils
  database/                           # Drift SQLite: tables, DAOs, migrations
  features/                           # Feature modules (Clean Architecture)
    ai/                               # AI Ghostwriter (gateway, services, privacy)
    connections/                      # Saved connection management
    credentials/                      # Credential vault, biometric, key utils
    home/                             # Home screen
    session/                          # Multi-session tab management
    terminal/                         # Core terminal (SSH, blocks, ribbons, TUI)
  shared/                             # Shared widgets and services
```

Each feature follows Clean Architecture:

```
features/<name>/
  data/           # Repositories, datasources, services, models
  domain/         # Entities, use cases, repository interfaces
  presentation/   # Providers, screens, widgets
```

## Key Patterns

- **Error handling**: `fpdart` `Either<Failure, T>` throughout -- no thrown
  exceptions in business logic
- **State**: Riverpod with `@riverpod` code generation, `AsyncNotifier` for
  async
- **Immutable data**: `freezed` for entities and models
- **Database**: Drift with type-safe tables, DAOs, and schema migrations
- **Navigation**: go_router with declarative routes

## Database Schema (3 tables currently)

| Table                 | Purpose                           | Security Notes                     |
| --------------------- | --------------------------------- | ---------------------------------- |
| `blocks`              | Semantic blocks (commands/output) | Contains terminal output -- review |
| `credential_metadata` | Key metadata (no key material!)   | Fingerprints, names, timestamps    |
| `saved_connections`   | Host configs                      | No passwords; keyId refs vault     |

## Implemented Features (Completed OpenSpec Changes)

| Feature                    | OpenSpec Change             |
| -------------------------- | --------------------------- |
| Flutter project scaffold   | `scaffold-flutter-project`  |
| Terminal emulation (xterm) | `terminal-emulation`        |
| SSH connectivity           | `ssh-connectivity`          |
| Credential vault + bioauth | `credential-storage`        |
| Semantic blocks            | `semantic-blocks`           |
| AI gateway architecture    | `ai-gateway`                |
| AI FAB panel               | `ai-fab-panel`              |
| AI setup wizard            | `ai-setup-flow`             |
| Fullscreen TUI mode        | `fullscreen-tui-mode`       |
| Layout preference persist  | `persist-layout-preference` |

---

# TELOS FRAMEWORK - REQUIRED READING

This project uses the **Telos Framework** with **Spec-Driven Development
(SDD)**.

**CRITICAL**: All code must trace back to specifications. Every function needs a
`@telos` annotation linking it to a spec.

## IMPORTANT: Read telos/TELOS.md First

Before making any changes, **always read `telos/TELOS.md`** for:

- Project purpose and success metrics
- User experiences (L3 journeys)
- Feature request workflow (MUST follow for new features)
- Current spec counts and health

## Spec-Driven Development (SDD)

This project enforces a 4-level spec hierarchy:

| Level  | Name       | Description                               |
| ------ | ---------- | ----------------------------------------- |
| **L4** | Purpose    | Why the project exists + success metrics  |
| **L3** | Experience | User journeys, UX requirements, analytics |
| **L2** | Contract   | API contracts, component interfaces       |
| **L1** | Function   | Individual functions with TDD scenarios   |

### Spec Location

All specs live in `telos/specs/`:

```
telos/specs/
  L4-purpose/      # Project purpose (one file)
  L3-experience/   # User journeys
  L2-contract/     # API/component contracts
  L1-function/     # Function-level specs with scenarios
```

### Code Annotation Requirements

**EVERY function MUST have a `@telos` annotation** linking it to a spec:

```dart
// @telos L1:function:lib/features/credentials/data/services:credential_vault
class CredentialVault {
  // implementation
}
```

**EVERY test MUST have `@telos-test` and `@telos-scenario` annotations**:

```dart
// @telos-test L1:function:lib/features/credentials/data/services:credential_vault
void main() {
  group('CredentialVault', () {
    // @telos-scenario L1:...:credential_vault:store-key-encrypted
    test('stores private key with encryption', () {
      // test implementation
    });
  });
}
```

## BEFORE Writing Any Code

1. **Check if a spec exists** for the code you're about to write
2. **If no spec exists**, create one first
3. **If spec exists**, read it to understand requirements and scenarios
4. **Generate tests** from the spec before implementing
5. **Add @telos annotation** to your code linking to the spec

## Automatic Workflows

### When Creating New Features

1. Read `telos/specs/L4-purpose/purpose.md` to understand project purpose
2. Create spec at appropriate level:
   - User-facing feature -> L3:experience spec
   - API/component -> L2:contract spec
   - Function -> L1:function spec
3. Write tests from spec scenarios (TDD)
4. Implement with @telos annotations
5. Run `/telos:validate` before commit

### When Modifying Existing Code

1. Find the spec for the code: check for `@telos` annotation
2. Read the spec to understand requirements
3. Update spec if requirements change
4. Update tests if scenarios change
5. Modify code
6. Run `/telos:validate`

### When Reviewing Code

Ensure:

- All specs have valid structure
- All `@telos` annotations point to valid specs
- All L1 specs have tests with `@telos-test` annotations
- No orphaned code (functions without @telos annotations)

## TDD Workflow (REQUIRED)

1. **Spec First**: Create or update spec with scenarios
2. **Generate Tests**: Write tests from GIVEN/WHEN/THEN scenarios
3. **Red**: Run tests - they should fail
4. **Implement**: Write code with @telos annotation
5. **Green**: Run tests - they should pass
6. **Validate**: Run `/telos:validate`

## Slash Commands

Use these commands for Telos operations:

| Command (Claude)            | Command (Claude Code)       | Purpose                       |
| --------------------------- | --------------------------- | ----------------------------- |
| `/telos:init`               | `/telos-init`               | Initialize Telos setup        |
| `/telos:validate`           | `/telos-validate`           | Validate specs, links, tests  |
| `/telos:status`             | `/telos-status`             | Show current configuration    |
| `/telos:sdd-discover`       | `/telos-sdd-discover`       | Generate specs from code      |
| `/telos:sdd-context`        | `/telos-sdd-context`        | Load spec context             |
| `/telos:sdd-generate-tests` | `/telos-sdd-generate-tests` | Generate tests from scenarios |

## Hard Requirements

### BEFORE Committing

You MUST ensure:

1. All new code has `@telos` annotations
2. All tests have `@telos-test` annotations
3. `/telos:validate` passes
4. No orphaned functions exist

### BEFORE Creating a PR

Run `/telos:validate` to check:

- Spec structure integrity
- Code-spec link validity
- Test coverage
- Orphaned code detection

**If validation fails, fix issues before proceeding.**

## Spec ID Format

Full path format: `L{level}:{type}:{path}:{name}`

Examples:

- `L4:purpose` - Project purpose
- `L3:experience:auth-journey` - Auth user journey
- `L2:contract:src/api/auth` - Auth API contract
- `L1:function:src/auth/validation:validateToken` - Specific function

## Context Loading

When you need to understand code, use `/telos:sdd-context` with the spec ID.

This loads:

- TELOS.md (project entry point)
- Full lineage from L4 purpose down to target
- Adjacent sibling specs
- Implementation file paths

Use this context to ensure changes align with purpose.

---

**Remember**: Code without specs is orphaned code. Specs without tests are
incomplete. Every line should trace back to purpose.

## Automatic Behavior

As an AI assistant, you should **automatically**:

1. **Check for specs** before modifying any code
2. **Read spec context** when unsure of purpose
3. **Create specs first** when implementing new features
4. **Generate tests** before implementation (TDD)
5. **Add @telos annotations** to all new functions
6. **Validate** before suggesting commits

### When User Asks to Create a Feature

1. Ask: "Should I create a spec for this feature first?"
2. If yes, create L3 (experience) or L2 (contract) spec
3. Generate tests from scenarios
4. Implement with annotations
5. Run `/telos:validate`

### When User Asks to Fix a Bug

1. Find the spec: look for `@telos` annotation in affected code
2. Read the spec to understand requirements
3. Check if spec scenarios cover this case
4. Add scenario if missing
5. Update test
6. Fix code
7. Run `/telos:validate`

### When User Asks to Refactor

1. Find all affected specs via `@telos` annotations
2. Read each spec to understand contracts
3. Ensure refactor doesn't break spec contracts
4. Update annotations if paths change
5. Run `/telos:validate`

## Philosophy

The Telos framework ensures that every line of code serves a clear purpose,
traceable back to the ultimate goal. SDD ensures this traceability is enforced:

- **Clarity**: Every function links to a requirement
- **Alignment**: Code changes flow from spec changes
- **Traceability**: Purpose -> Experience -> Contract -> Function
- **Quality**: TDD enforced through spec scenarios

For more information, see
[Telos Framework documentation](https://github.com/telos-framework/init).

---

# OPENSPEC WORKFLOW

This project uses **OpenSpec** for managing feature changes through a structured
artifact workflow.

## OpenSpec Commands

| Command          | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `/opsx-new`      | Start a new change with proposal           |
| `/opsx-continue` | Create next artifact for a change          |
| `/opsx-ff`       | Fast-forward: create all artifacts at once |
| `/opsx-apply`    | Implement tasks from a change              |
| `/opsx-verify`   | Verify implementation matches specs        |
| `/opsx-archive`  | Archive completed change                   |

## Change Priority

When using `/opsx-apply` without specifying a change name:

1. **Auto-select highest priority change** based on:
   - Dependencies satisfied (prerequisite changes completed)
   - PRD phase order (Phase 1 MVP before Phase 2)
   - P0 (Must Have) before P1 (Should Have) before P2 (Nice to Have)

2. **Completed changes** (archived):
   - `scaffold-flutter-project` (foundation) -- DONE
   - `terminal-emulation` (core terminal) -- DONE
   - `ssh-connectivity` (connect to servers) -- DONE
   - `credential-storage` (vault + biometric) -- DONE
   - `semantic-blocks` (command/output blocks) -- DONE
   - `ai-gateway` (AI service architecture) -- DONE
   - `ai-fab-panel` (AI floating button) -- DONE
   - `ai-setup-flow` (AI configuration wizard) -- DONE
   - `fullscreen-tui-mode` (TUI detection) -- DONE
   - `persist-layout-preference` (layout prefs) -- DONE

3. **Next priority changes** (pending, with full artifacts ready):
   - `cloud-ai-providers` (cloud AI integration)
   - `local-llm` (on-device AI model)
   - `error-healing` (AI error fix suggestions)
   - `remote-ai-ollama` (self-hosted AI)
   - `caching-layer` (performance caching)

4. **Remaining Phase 1 MVP** (proposal-only, need specs):
   - `host-management` (manage saved connections)
   - `session-tabs` (multiple terminal sessions)
   - `command-ribbon-basic` (command completion)
   - `modifier-drawer` (special key access)
   - `security-policies` (session timeout, clipboard, screen capture)

5. **If ambiguous**, prompt user to select from available changes

---

# TEST-DRIVEN DEVELOPMENT (TDD) - ENFORCED

**TDD is MANDATORY for all code changes in this project.**

## TDD Workflow

```
1. SPEC    -> Write/update spec with scenarios (GIVEN/WHEN/THEN)
2. TEST    -> Write failing tests from scenarios
3. RED     -> Run tests, verify they fail
4. CODE    -> Write minimal code to pass tests
5. GREEN   -> Run tests, verify they pass
6. REFACTOR-> Clean up while keeping tests green
```

## TDD Rules

### BEFORE Writing Any Implementation Code

1. **Spec scenarios MUST exist** for the functionality
2. **Tests MUST be written** from those scenarios
3. **Tests MUST fail** before implementation (proves test is valid)

### DURING Implementation

1. Write **minimal code** to make tests pass
2. Do NOT write code without a corresponding test
3. Run tests frequently (`flutter test`)

### AFTER Implementation

1. All tests MUST pass
2. Run `flutter analyze` - no errors allowed
3. Coverage should include all spec scenarios

## Test File Organization

```
test/
  unit/                    # Pure logic tests
  widget/                  # Widget tests
  features/
    <feature>/
      domain/
        entities/          # Entity tests
        usecases/          # Use case tests
      data/                # Repository/service tests
      presentation/        # Provider/widget tests
integration_test/          # E2E tests
```

## Test Annotations

Every test file MUST have `@telos-test` linking to the spec:

```dart
// @telos-test L1:function:lib/features/terminal/domain/entities:terminal_config
void main() {
  group('TerminalConfig', () {
    // @telos-scenario L1:...:terminal_config:default-values
    test('has sensible default values', () {
      // test implementation
    });
  });
}
```

## When Working on OpenSpec Changes

When `/opsx-apply` is invoked:

1. Read the change's `specs/**/*.md` files
2. For each requirement with scenarios:
   - Check if test exists
   - If not, **write the test first**
   - Then implement the code
3. Mark task complete only after tests pass

## Flutter-Specific Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/terminal/domain/entities/terminal_config_test.dart

# Run with coverage
flutter test --coverage

# Run only unit tests
flutter test test/unit/
```

## Mocking Guidelines

- Use `mocktail` for mocking (already in dev dependencies)
- Mock external dependencies (network, database, platform)
- Don't mock the code under test

---

# AI DATA HANDLING RULES

When implementing or modifying AI features, these rules apply:

## Data Flow Principles

1. **Local-first**: Default to on-device processing. Only use cloud when the
   user has explicitly opted in and the task exceeds local model capability.

2. **Consent before transmission**: If AI privacy mode is `cloud`, prompt the
   user before each cloud request (or respect their "always allow" preference).
   `local` and `remote` modes NEVER send data to third-party cloud providers.

3. **Minimize context sent**: When sending data to any AI provider, include only
   the minimum context needed. Strip unnecessary terminal output, user paths,
   hostnames, and IP addresses where possible.

4. **Error healing stays local**: Failed commands and their stderr often contain
   sensitive information (paths, usernames, hostnames, configuration details).
   Error healing routes to the local model by default.

5. **API keys in secure storage**: Cloud AI provider API keys (OpenAI,
   Anthropic, Google) are stored in `flutter_secure_storage`, NOT in the
   database or app preferences.

## Model Router Logic

The AI model router (`lib/features/ai/`) selects providers based on:

| Task             | Default Provider | Reason                          |
| ---------------- | ---------------- | ------------------------------- |
| Summarize output | Local            | Simple task, privacy-preserving |
| Generate command | Complexity-based | Simple local, complex cloud     |
| Heal error       | Local            | Error output is sensitive       |
| Explain command  | User preference  | Non-sensitive, user can choose  |

---

# QUICK REFERENCE

## Before ANY Code Change

- [ ] Spec exists with scenarios?
- [ ] Tests written from scenarios?
- [ ] Tests fail before implementation?
- [ ] Security checklist reviewed (if touching credentials/AI/auth)?

## After ANY Code Change

- [ ] All tests pass (`flutter test`)?
- [ ] `flutter analyze` clean?
- [ ] `@telos` annotations present?
- [ ] No secrets in code or logs?

## Starting Work Session

```bash
# Check what needs to be done
openspec list --json

# Continue highest priority change
/opsx-apply

# Run tests
flutter test

# Check for analysis issues
flutter analyze
```

## Key Reference Files

| File                    | Purpose                                     |
| ----------------------- | ------------------------------------------- |
| `PRD.md`                | Full product requirements (source of truth) |
| `telos/TELOS.md`        | Project purpose, spec index, health         |
| `SOUL.md`               | Project philosophy and identity             |
| `IDENTITY.md`           | Project identity and branding               |
| `pubspec.yaml`          | Dependencies and versions                   |
| `analysis_options.yaml` | Strict lint rules                           |
