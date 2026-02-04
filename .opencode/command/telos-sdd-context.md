---
description: Load spec context for AI work
---

# Telos-SDD Context

Load recursive context for a spec ID to understand its full lineage.

## Usage

When you need to understand a piece of code or make changes, load its context:

```bash
npx telos context <spec-id>
```

Example:

```bash
npx telos context L1:function:src/auth/validation:validateToken
```

## What Context Includes

1. **TELOS.md** - Project entry point (always loaded)
2. **Lineage** - All ancestor specs from L4 down to target
3. **Target Spec** - Full content of the requested spec
4. **Siblings** - Adjacent specs with same parent (metadata only)
5. **Implementation** - Source file and test file paths

## Output Format

Default is markdown, suitable for AI consumption:

```bash
npx telos context L1:function:src/auth:validate --format=markdown
```

For JSON output:

```bash
npx telos context L1:function:src/auth:validate --format=json
```

## When to Use

Use context loading when:

1. Before modifying code - understand its purpose
2. Before creating specs - see the hierarchy
3. Reviewing code - trace back to requirements
4. Writing tests - understand scenarios

## Example Workflow

```bash
# 1. Find the spec for a file
npx telos coverage

# 2. Load context for the spec
npx telos context L1:function:src/auth/validation

# 3. Make changes aligned with purpose
# (edit code)

# 4. Validate changes
npx telos validate
```
