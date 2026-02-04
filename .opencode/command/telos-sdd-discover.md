---
description: Generate specs from existing code
---

# Telos-SDD Discover

Scan the existing codebase and generate spec structure (brownfield).

## What This Does

1. Scans source directories for modules and functions
2. Detects routes, components, and API endpoints
3. Proposes a spec hierarchy based on code structure
4. Generates spec files for review

## Instructions

Run the discovery command:

```bash
npx telos discover
```

For a dry run (preview without generating files):

```bash
npx telos discover --dry-run
```

## Review Process

After discovery, review the generated specs:

1. **L4:purpose** - Edit to reflect actual project purpose
2. **L3:experience** - Rename journeys to match your terminology
3. **L2:contract** - Verify API contracts match implementation
4. **L1:function** - Add missing scenarios for TDD

## Adding Annotations

After specs are generated, add @telos annotations to code:

```typescript
// @telos L1:function:src/auth/validation:validateToken
export function validateToken(token: string): boolean {
  // implementation
}
```

## Validation

After adding annotations, validate coverage:

```bash
npx telos validate
```

This checks:

- All specs have valid structure
- All annotations point to existing specs
- All L1 specs have tests
- No orphaned code (functions without annotations)
