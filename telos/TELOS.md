# TELOS: Bento

> Purpose-driven development with spec-code traceability

## Purpose

Transform the mobile terminal experience from chaotic scrolling text into
organized, navigable "Semantic Blocks" - enabling developers to be genuinely
productive on mobile devices through resilient Mosh connectivity, context-aware
input predictions, and AI-powered command assistance.

See: [Full Purpose Spec](specs/L4-purpose/purpose.md)

## User Experiences (L3)

| Journey               | Description                                                           | Spec                                                 |
| --------------------- | --------------------------------------------------------------------- | ---------------------------------------------------- |
| Incident Response     | On-call engineer diagnoses and resolves production issues from mobile | [View](specs/L3-experience/incident-response.md)     |
| AI Command Assistance | Natural language to CLI command via Ghostwriter                       | [View](specs/L3-experience/ai-command-assistance.md) |
| Error Recovery        | One-tap AI-powered error healing for failed commands                  | [View](specs/L3-experience/error-recovery.md)        |
| Session Management    | Multiple concurrent terminal sessions in tabs                         | [View](specs/L3-experience/session-management.md)    |
| Mobile Vibe Coding    | Remote development on the go with AI assistance                       | [View](specs/L3-experience/mobile-vibe-coding.md)    |

## Spec Hierarchy

| Level | Name       | Description                       | Count |
| ----- | ---------- | --------------------------------- | ----- |
| L4    | Purpose    | Project purpose + success metrics | 1     |
| L3    | Experience | User journeys + UX                | 5     |
| L2    | Contract   | APIs + component interfaces       | 12    |
| L1    | Function   | Functions with TDD scenarios      | 5     |

**Total Specs: 23**

## Contracts (L2)

### Services

| Service            | Description                                    | Spec                                            |
| ------------------ | ---------------------------------------------- | ----------------------------------------------- |
| Session Service    | Connection lifecycle, multi-session management | [View](specs/L2-contract/service-session.md)    |
| AI Gateway Service | Unified AI interface for Ghostwriter/healing   | [View](specs/L2-contract/service-ai-gateway.md) |
| Block Service      | Semantic block creation, persistence, search   | [View](specs/L2-contract/service-block.md)      |
| Host Service       | Saved hosts, folders, Tailscale integration    | [View](specs/L2-contract/service-host.md)       |
| Snippet Service    | Command templates with variable substitution   | [View](specs/L2-contract/service-snippet.md)    |

### Components

| Component         | Description                             | Spec                                                     |
| ----------------- | --------------------------------------- | -------------------------------------------------------- |
| Block Widget      | Collapsible command/output display unit | [View](specs/L2-contract/component-block-widget.md)      |
| Command Ribbon    | Predictive suggestions above keyboard   | [View](specs/L2-contract/component-command-ribbon.md)    |
| Modifier Drawer   | Special keys (Ctrl, Alt, arrows)        | [View](specs/L2-contract/component-modifier-drawer.md)   |
| Tab Bar           | Session tabs with status indicators     | [View](specs/L2-contract/component-tab-bar.md)           |
| Connection Picker | Host selection modal                    | [View](specs/L2-contract/component-connection-picker.md) |
| Ghostwriter Modal | Natural language to command AI          | [View](specs/L2-contract/component-ghostwriter-modal.md) |
| Heal Banner       | One-tap error fix suggestion            | [View](specs/L2-contract/component-heal-banner.md)       |

## Functions (L1)

| Function              | Description                              | Spec                                                       |
| --------------------- | ---------------------------------------- | ---------------------------------------------------------- |
| connectSession        | Establish SSH/Mosh connection            | [View](specs/L1-function/session-connect-session.md)       |
| generateCommand       | AI natural language to CLI               | [View](specs/L1-function/ai-generate-command.md)           |
| healError             | AI error analysis and fix                | [View](specs/L1-function/ai-heal-error.md)                 |
| parseTappableElements | Extract interactive elements from output | [View](specs/L1-function/block-parse-tappable-elements.md) |
| renderSnippet         | Variable substitution in templates       | [View](specs/L1-function/snippet-render-snippet.md)        |

---

## IMPORTANT: Feature Request Workflow

**When the user requests a new feature, you MUST follow this workflow:**

### Step 1: Check Impact on Experiences (L3)

Ask: "Does this feature affect any existing user journeys, or create a new one?"

- If **new journey**: Create a new L3 spec in `telos/specs/L3-experience/`
- If **modifies journey**: Update the relevant L3 spec first
- If **no journey impact**: Proceed to Step 2

### Step 2: Define or Update Contracts (L2)

Before writing ANY code, create/update L2 contract specs:

- **New API endpoint?** → Create `telos/specs/L2-contract/api-[name].md`
- **New component?** → Create `telos/specs/L2-contract/component-[name].md`
- **New service?** → Create `telos/specs/L2-contract/service-[name].md`
- **Modifying existing?** → Update the relevant L2 spec

L2 specs must include:

- Interface/API signature
- Input/output contracts
- Error handling
- Parent L3 experience reference

### Step 3: Define Functions (L1)

For each function needed to implement the L2 contracts:

1. Create L1 spec in `telos/specs/L1-function/`
2. Include TDD scenarios (GIVEN/WHEN/THEN)
3. Reference parent L2 contract

### Step 4: Generate Tests

Write tests from the GIVEN/WHEN/THEN scenarios in the L1 spec:

```dart
// @telos-test L1:function:lib/features/ai/domain/usecases:generateCommand
void main() {
  group('generateCommand', () {
    // @telos-scenario L1:function:lib/features/ai/domain/usecases:generateCommand:simple-command
    test('should generate simple command from natural language', () {
      // Given the local AI model is loaded
      // When generateCommand is called with "list all files"
      // Then suggestion.command equals "ls -la"
    });
  });
}
```

### Step 5: Implement with Annotations

```dart
// @telos L1:function:lib/features/ai/domain/usecases:generateCommand
Future<Either<AIFailure, CommandSuggestion>> generateCommand({
  required String naturalLanguage,
  required ShellContext context,
}) async {
  // implementation
}
```

### Step 6: Validate Before Commit

Run `/telos:validate` to check:

- All specs have valid structure
- All `@telos` annotations point to valid specs
- All L1 specs have corresponding tests
- No orphaned code

---

## Quick Reference

**Commands:**

- `/telos:validate` - Validate specs, code links, and tests
- `/telos:status` - Show current spec counts and health
- `/telos:sdd-discover` - Generate specs from existing code
- `/telos:sdd-context <spec-id>` - Load context for a spec
- `/telos:sdd-generate-tests <spec-id>` - Generate tests from scenarios

**Annotation Format:**

```dart
// @telos L1:function:lib/module:functionName
// @telos-test L1:function:lib/module:functionName
// @telos-scenario L1:function:lib/module:functionName:scenario-name
```

**Spec ID Format:** `L[level]:[type]:[path]:[name]`

Examples:

- `L4:purpose`
- `L3:experience:incident-response`
- `L2:contract:service-session`
- `L1:function:lib/features/ai/domain/usecases:generateCommand`

---

## Links

- [Telos Documentation](https://github.com/telos-framework/init)
- [Spec-Driven Development Guide](https://telos-framework.dev/sdd)
