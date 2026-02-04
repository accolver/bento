---
description: Validate SDD structure and links
---

# Telos-SDD Validate

Validate all specs, code-spec links, tests, and orphaned code.

## Full Validation

Run complete validation:

```bash
npx telos validate
```

This checks:

1. **Specs** - Structure, parent-child integrity, no circular refs
2. **Links** - All @telos annotations point to existing specs
3. **Tests** - All L1 specs have @telos-test annotations
4. **Orphans** - All functions have @telos annotations

## Selective Validation

Validate specific aspects:

```bash
npx telos validate --specs     # Spec structure only
npx telos validate --links     # Code-spec links only
npx telos validate --tests     # Test coverage only
npx telos validate --orphans   # Orphaned code only
```

## Exit Codes

- `0` - All validations passed
- `1` - One or more validations failed

Use in CI/CD:

```yaml
- name: Validate Telos-SDD
  run: npx telos validate
```

## Fixing Issues

### Invalid Annotation

```
✗ src/auth/legacy.ts:12 → L2:auth-legacy:oldValidate (spec deleted)
```

Fix: Update annotation to point to existing spec, or remove the code.

### Missing Tests

```
⚠ L1:function:src/payment:formatCurrency - missing tests
```

Fix: Run `telos spec generate-tests L1:function:src/payment` to create test
skeletons.

### Orphaned Code

```
✗ src/utils.ts:45 - helper function has no @telos annotation
```

Fix: Add `// @telos L1:function:src/utils:helper` above the function.

## Pre-commit Hook

Install automatic validation:

```bash
npx telos hooks install
```

This blocks commits that fail validation.
