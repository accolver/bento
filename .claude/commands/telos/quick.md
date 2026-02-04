---
description: Quick Telos initialization with auto-accepted AI proposals
---

# Telos Quick Initialization

This is the fast-track initialization mode that accepts all AI-proposed specs
without user review. Use this when you trust the AI analysis and want to get
started immediately.

## The 4-Level Hierarchy

| Level | Name       | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| L4    | Purpose    | Why the project exists + success metrics        |
| L3    | Experience | User journeys, UX requirements, analytics needs |
| L2    | Contract   | API contracts, component interfaces, boundaries |
| L1    | Function   | Individual functions with TDD scenarios         |

## Process

1. **Analyze codebase** silently
2. **Generate L4 purpose spec** from README/docs
3. **Show summary** of what was created

## Step 1: Silent Analysis

Analyze without user interaction:

- Read README.md
- Check package.json / pyproject.toml / Cargo.toml
- Scan src/ or lib/ directory
- Detect testing and linting tools

## Step 2: Auto-Generate L4 Purpose

Generate `telos/specs/L4-purpose/purpose.md` based on analysis:

```markdown
<!-- telos-metadata
id: L4:purpose
level: 4
title: [Project Name]
-->

# L4: Purpose

## Why This Project Exists

[Inferred from README]

## Beneficiaries

[Inferred from README or package description]

## Success Metrics

- [Inferred metric 1]
- [Inferred metric 2]
- [Inferred metric 3]

## Constraints

- [Any detected constraints]

## Technology Stack

- **Languages**: [Detected]
- **Frameworks**: [Detected]
- **Testing**: [Detected]
- **Linting**: [Detected]

## Initialization

- **Date**: [Current date]
- **Method**: /telos:quick
```

## Step 3: Display Summary

Once complete, show:

---

⚡ **Telos quick initialization complete!**

**Your project now has:**

```
telos/
├── TELOS.md                 # Entry point
├── .telosrc.json            # Configuration
├── index.json               # Spec registry
└── specs/
    ├── L4-purpose/
    │   └── purpose.md       # [Generated purpose]
    ├── L3-experience/       # Ready for user journey specs
    ├── L2-contract/         # Ready for API/component specs
    └── L1-function/         # Ready for function specs
```

**Generated L4 Purpose:**

| Field         | Value               |
| ------------- | ------------------- |
| Purpose       | [Purpose statement] |
| Beneficiaries | [Who benefits]      |
| Stack         | [Detected tech]     |

**How Spec-Driven Development works:**

1. **Before coding**: Create a spec at the appropriate level
2. **Write tests**: Generate tests from spec scenarios
3. **Implement**: Write code with `@telos` annotation
4. **Validate**: Run `/telos:validate` before commits

**Available commands:**

- `/telos:validate` - Validate specs, links, tests
- `/telos:status` - Show current configuration
- `/telos:sdd-discover` - Generate specs from existing code
- `/telos:sdd-context` - Load spec context before changes

**Next steps:**

1. Review `telos/specs/L4-purpose/purpose.md` and refine if needed
2. For existing code: Run `/telos:sdd-discover` to generate specs
3. For new features: Create specs before coding

**Not satisfied?** Run `/telos:init` for interactive mode with full
customization.

---

## When to Use Quick Mode

✅ **Use quick mode when:**

- Starting a new project with clear conventions
- The codebase already has comprehensive README
- You want to iterate quickly and refine later

❌ **Use full `/telos:init` when:**

- Project has unique or nuanced purpose
- Strategic direction needs human input
- Initial setup must be carefully reviewed
