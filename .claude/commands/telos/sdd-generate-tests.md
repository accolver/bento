---
description: Generate tests from spec scenarios
---

# Telos-SDD Generate Tests

Generate test skeletons from spec scenarios.

## Usage

Generate tests for a spec:

```bash
npx telos spec generate-tests <spec-id>
```

Example:

```bash
npx telos spec generate-tests L1:function:src/auth/validation
```

## Dry Run

Preview generated tests without writing files:

```bash
npx telos spec generate-tests L1:function:src/auth/validation --dry-run
```

## Test Framework

Specify a framework (default: auto-detected):

```bash
npx telos spec generate-tests L1:function:src/auth/validation --framework=vitest
npx telos spec generate-tests L1:function:src/auth/validation --framework=jest
npx telos spec generate-tests L1:function:src/auth/validation --framework=pytest
```

## Scenario Format in Specs

Scenarios in your spec should follow this format:

```markdown
### Scenario: Valid token

- GIVEN a properly signed JWT
- WHEN validateToken is called
- THEN return { valid: true }

### Scenario: Expired token

- GIVEN a JWT with expired `exp` claim
- WHEN validateToken is called
- THEN return { valid: false, error: 'TOKEN_EXPIRED' }
```

## Generated Test Format

The generator creates:

```typescript
// @telos-test L1:function:src/auth/validation:validateToken
describe("validateToken", () => {
  // @telos-scenario L1:function:src/auth/validation:validateToken:valid-token
  it("Valid token", () => {
    // GIVEN a properly signed JWT
    // TODO: Set up test conditions

    // WHEN validateToken is called
    // TODO: Execute the action

    // THEN return { valid: true }
    // TODO: Add assertions
    expect(true).toBe(true);
  });
});
```

## TDD Workflow

1. **Create spec with scenarios**
2. **Generate test skeletons**: `telos spec generate-tests <spec-id>`
3. **Run tests** → They fail (Red)
4. **Implement code** with @telos annotation
5. **Run tests** → They pass (Green)
6. **Validate**: `telos validate`
7. **Commit** (pre-commit hook verifies)
