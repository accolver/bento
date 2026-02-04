---
description: Show current Telos configuration and spec status
---

# Telos Status

Display the current Telos spec-driven development status for this project.

## Check Installation

First, check if Telos is initialized:

- Look for `telos/specs/` directory
- Look for `telos/.telosrc.json`

If not found, display:

```
❌ Telos not initialized

Run `/telos:init` to set up spec-driven development.
```

## Display Configuration

If Telos is initialized, read and display:

### 1. Project Purpose (L4)

From `telos/specs/L4-purpose/purpose.md`, extract and display:

```
🎯 **Project Purpose (L4)**
[Purpose statement from spec]

**Beneficiaries**: [Who benefits]
**Success Metrics**: [Metrics listed]
```

### 2. Spec Hierarchy Status

Count specs at each level:

| Level | Name       | Count | Description                       |
| ----- | ---------- | ----- | --------------------------------- |
| L4    | Purpose    | 1     | Why the project exists            |
| L3    | Experience | [N]   | User journeys and UX requirements |
| L2    | Contract   | [N]   | API and component contracts       |
| L1    | Function   | [N]   | Function specs with TDD scenarios |

**Total Specs**: [Total count]

### 3. Code Coverage

Scan for @telos annotations:

```
**Code-to-Spec Links**
- Functions with @telos: [N]
- Tests with @telos-test: [N]
- Orphaned functions: [N]
```

### 4. Technology Stack

From `telos/specs/L4-purpose/purpose.md`:

```
**Technology Stack**
- **Languages**: [Languages]
- **Frameworks**: [Frameworks]
- **Testing**: [Test frameworks]
- **Linting**: [Linters]
```

### 5. Configuration

From `telos/.telosrc.json`:

```
**Enforcement Settings**
- Specs: [hard/soft]
- Links: [hard/soft]
- Tests: [hard/soft]
- Orphans: [hard/soft]
```

### 6. Platform Integration

Check for platform-specific files:

```
**Platform Integration**
- AGENTS.md: [✅ exists / ❌ missing]
- CLAUDE.md: [✅ exists / ❌ missing]
- Slash commands: [✅ installed / ❌ missing]
```

## Health Check

Perform a quick health check:

- **✅ Healthy**: All required files present, L4 purpose defined
- **⚠️ Incomplete**: Missing specs or configuration
- **❌ Not Initialized**: Core files missing

If incomplete:

```
⚠️ **Warning**: Telos setup is incomplete.

**Issues**:
- [List issues]

**Suggestion**: Run `/telos:init` to complete setup.
```

## Quick Actions

Display available commands:

```
**Available Commands**
- `/telos:validate`           - Validate specs, links, tests
- `/telos:init`               - Reconfigure interactively
- `/telos:sdd-discover`       - Generate specs from existing code
- `/telos:sdd-context`        - Load spec context
- `/telos:sdd-generate-tests` - Generate tests from scenarios
```

## Example Output

```
═══════════════════════════════════════════════════════════════════════════
                           TELOS STATUS
═══════════════════════════════════════════════════════════════════════════

🎯 **Project Purpose (L4)**
Enable developers to build software with clear spec-driven development

**Beneficiaries**: Software development teams using AI assistants
**Success Metrics**: Reduced bugs, faster onboarding, traceable requirements

**Spec Hierarchy**

| Level | Name       | Count | Status |
| ----- | ---------- | ----- | ------ |
| L4    | Purpose    | 1     | ✅     |
| L3    | Experience | 3     | ✅     |
| L2    | Contract   | 5     | ✅     |
| L1    | Function   | 12    | ✅     |

**Total Specs**: 21

**Code-to-Spec Links**
- Functions with @telos: 45
- Tests with @telos-test: 38
- Orphaned functions: 3

**Technology Stack**
- **Languages**: TypeScript, JavaScript
- **Frameworks**: React, Express
- **Testing**: Vitest, Playwright
- **Linting**: ESLint, Prettier

**Enforcement Settings**
- Specs: hard
- Links: hard
- Tests: hard
- Orphans: soft

**Platform Integration**
- AGENTS.md: ✅
- CLAUDE.md: ✅
- Slash commands: ✅ (7 commands)

**Health**: ✅ Fully operational

**Available Commands**
- `/telos:validate`           - Validate specs, links, tests
- `/telos:init`               - Reconfigure interactively
- `/telos:sdd-discover`       - Generate specs from existing code
- `/telos:sdd-context`        - Load spec context
- `/telos:sdd-generate-tests` - Generate tests from scenarios
```
