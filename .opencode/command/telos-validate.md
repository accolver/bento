---
description: Validate specs, code links, and tests
---

# Telos Validation

This command validates your spec-driven development setup:

- Spec structure integrity
- Code-to-spec links (@telos annotations)
- Test coverage for specs
- Orphaned code detection

## Prerequisites

Check if Telos is initialized:

- `telos/specs/` directory must exist
- `telos/.telosrc.json` must exist

If not found, display: "❌ Telos not initialized. Run `/telos:init` first."

## Validation Process

### Step 1: Load Configuration

Read `telos/.telosrc.json` for enforcement settings:

```json
{
  "enforcement": {
    "specs": "hard",
    "links": "hard",
    "tests": "hard",
    "orphans": "soft"
  }
}
```

### Step 2: Validate Specs

Check all spec files in `telos/specs/`:

- ✅ Valid metadata (id, level, title)
- ✅ Parent-child relationships valid
- ✅ No orphaned specs (parents exist)
- ❌ Invalid metadata format
- ❌ Broken parent references

### Step 3: Validate Links

Scan source code for `@telos` annotations:

```typescript
// @telos L1:function:src/auth/validation:validateToken
```

Check that each annotation:

- ✅ Points to an existing spec
- ✅ Uses correct ID format
- ❌ Points to non-existent spec
- ❌ Uses invalid ID format

### Step 4: Validate Tests

Check that L1 specs have corresponding tests:

```typescript
// @telos-test L1:function:src/auth/validation:validateToken
describe("validateToken", () => {
  // @telos-scenario L1:function:src/auth/validation:validateToken:valid-token
  it("should validate", () => {});
});
```

- ✅ L1 spec has @telos-test annotation in test file
- ⚠️ L1 spec missing test coverage
- ❌ @telos-test points to non-existent spec

### Step 5: Find Orphans

Scan for functions without `@telos` annotations:

- ⚠️ Function `exportedFunction` has no @telos annotation
- ⚠️ Class `MyClass` has no @telos annotation

## Validation Report

Display results:

```
═══════════════════════════════════════════════════════════════════════════
                         TELOS VALIDATION REPORT
═══════════════════════════════════════════════════════════════════════════

Specs Validation
────────────────────────────────────────────────────────────────────────────
✅ Found 12 specs (3 L4, 4 L3, 3 L2, 2 L1)
✅ All parent-child relationships valid
✅ No orphaned specs

Links Validation
────────────────────────────────────────────────────────────────────────────
✅ Found 24 @telos annotations
✅ All annotations point to valid specs
❌ 2 annotations point to non-existent specs:
   - src/utils/helper.ts:15 → L1:function:src/utils:nonExistent
   - src/api/handler.ts:42 → L2:contract:src/api:missing

Tests Validation
────────────────────────────────────────────────────────────────────────────
✅ Found 8 @telos-test annotations
⚠️ 2 L1 specs missing test coverage:
   - L1:function:src/auth/refresh
   - L1:function:src/utils/format

Orphans Detection
────────────────────────────────────────────────────────────────────────────
⚠️ 5 exported functions without @telos annotations:
   - src/utils/legacy.ts: formatDate, parseInput
   - src/helpers/index.ts: calculateTotal, validateEmail, sanitize

═══════════════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════════════

| Check    | Status | Count  |
| -------- | ------ | ------ |
| Specs    | ✅     | 12 OK  |
| Links    | ❌     | 2 bad  |
| Tests    | ⚠️     | 2 miss |
| Orphans  | ⚠️     | 5 found|

Overall: ❌ FAILED (2 critical issues)
```

## Exit Status

- **✅ PASSED**: All checks pass (enforcement level "hard" respected)
- **⚠️ WARNINGS**: Soft enforcement items have issues
- **❌ FAILED**: Hard enforcement items have issues

## Fixing Issues

### Bad Links

```typescript
// Fix: Update annotation to match existing spec
// Before:
// @telos L1:function:src/utils:nonExistent

// After:
// @telos L1:function:src/utils:helper
```

### Missing Tests

```typescript
// Add test file with @telos-test annotation
// @telos-test L1:function:src/auth/refresh
describe("refreshToken", () => {
  it("should refresh expired tokens", () => {
    // test
  });
});
```

### Orphaned Code

```typescript
// Add @telos annotation to function
// @telos L1:function:src/utils/legacy:formatDate
export function formatDate(date: Date): string {
  // implementation
}
```

## Next Steps

If validation passes: "🎉 All validations passed! Your codebase is
spec-aligned."

If warnings found: "⚠️ Some soft enforcement issues found. Consider addressing
them."

If failures found: "❌ Validation failed. Fix the issues above before
committing."

## Validation Frequency

- Run before every commit (install hooks with CLI)
- Run in CI/CD pipeline
- Run after major refactoring
