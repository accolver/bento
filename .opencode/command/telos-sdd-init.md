---
description: Initialize SDD structure (alternative to init)
---

# Telos-SDD Initialize

Initialize the Spec-Driven Development (SDD) structure for this project.

## What This Does

1. Creates the telos/specs/ directory hierarchy (L4-L1)
2. Generates an initial L4:purpose spec from project metadata
3. Creates TELOS.md entry point
4. Initializes the spec index

## Instructions

Run the CLI command to initialize SDD:

```bash
npx telos spec init
```

Then help the user refine their L4:purpose by:

1. Reading telos/specs/L4-purpose/purpose.md
2. Asking clarifying questions about:
   - The ultimate purpose of the project
   - Success metrics (KPIs)
   - Target users
   - Constraints (technical, regulatory, etc.)
3. Updating the spec with their answers

## Spec Level Overview

| Level | Name       | Description                               |
| ----- | ---------- | ----------------------------------------- |
| L4    | Purpose    | Why the project exists + success metrics  |
| L3    | Experience | User journeys, UX requirements, analytics |
| L2    | Contract   | API contracts, component interfaces       |
| L1    | Function   | Individual functions with TDD scenarios   |

## Next Steps

After initialization, guide the user to:

1. Run `telos discover` to generate specs from existing code
2. Run `telos spec create 3 <name>` to add user journeys
3. Add `@telos` annotations to their code
4. Run `telos validate` to check coverage
