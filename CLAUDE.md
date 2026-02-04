# Project Context for Claude

<!-- Telos Framework with Spec-Driven Development -->

This project uses the **Telos Framework** with **Spec-Driven Development
(SDD)**.

**CRITICAL**: Read `AGENTS.md` for complete instructions. Every function must
link to a spec via `@telos` annotation.

## Quick Reference

### Before Writing Code

1. Check if spec exists for your changes
2. If not, create spec first
3. Generate tests from spec scenarios
4. Implement with `@telos` annotation
5. Run `/telos:validate` before commit

### Annotation Format

```typescript
// @telos L1:function:src/module:functionName
export function functionName() {}

// @telos-test L1:function:src/module:functionName
describe("functionName", () => {
  // @telos-scenario L1:function:src/module:functionName:success
  it("should succeed", () => {});
});
```

## Slash Commands

| Command                     | Purpose                           |
| --------------------------- | --------------------------------- |
| `/telos:init`               | Initialize Telos with AI guidance |
| `/telos:quick`              | Fast init (auto-accept proposals) |
| `/telos:validate`           | Validate specs, links, tests      |
| `/telos:status`             | Show current configuration        |
| `/telos:sdd-discover`       | Generate specs from existing code |
| `/telos:sdd-context`        | Load spec context before changes  |
| `/telos:sdd-generate-tests` | Generate tests from scenarios     |

## Spec Hierarchy

| Level | Name       | Purpose                    |
| ----- | ---------- | -------------------------- |
| L4    | Purpose    | Why we exist + metrics     |
| L3    | Experience | User journeys + UX         |
| L2    | Contract   | APIs + component contracts |
| L1    | Function   | Functions + TDD scenarios  |

---

**See `AGENTS.md` for complete Telos + SDD requirements.**
