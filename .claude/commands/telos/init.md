---
description: Initialize Telos spec-driven development for this project
---

# Telos Initialization

You are initializing the **Telos Framework** - a 4-level spec-driven development
system for AI-assisted software development. Your role is to analyze this
codebase, set up the spec hierarchy, and guide the user through defining their
project specs.

## The 4-Level Hierarchy

| Level | Name       | Description                                     |
| ----- | ---------- | ----------------------------------------------- |
| L4    | Purpose    | Why the project exists + success metrics        |
| L3    | Experience | User journeys, UX requirements, analytics needs |
| L2    | Contract   | API contracts, component interfaces, boundaries |
| L1    | Function   | Individual functions with TDD scenarios         |

## CRITICAL: One Question at a Time

**Throughout this initialization:**

- Ask ONLY ONE question at a time
- NEVER preview the next question or step
- STOP and WAIT for user response before proceeding

## Important Note

Platform setup (config files) was already completed by running
`npx telos-framework init`. The `telos/` directory structure also exists. Your
job is to help the user define their specs at all 4 levels.

---

## Step 1: Analyze Codebase

Read and analyze the following to understand this project:

### 1.1 Project Documentation

- **README.md** - Extract:
  - Project purpose and description
  - Target users/beneficiaries
  - Goals and success metrics
  - Technology stack

### 1.2 Package Configuration

Check for and read (if exists):

- **package.json** (Node.js)
- **pyproject.toml** or **requirements.txt** (Python)
- **Cargo.toml** (Rust)
- **go.mod** (Go)

### 1.3 Source Code Structure

Scan the primary source directory (src/, lib/, app/) to identify:

- Component patterns
- API structure
- Architectural patterns
- Database integration

### 1.4 Existing Specs

Check if `telos/specs/L4-purpose/purpose.md` exists and read it.

---

## Step 2: Propose Purpose (L4)

Based on your analysis, propose the L4 Purpose spec:

```
═══════════════════════════════════════════════════════════════════════════
                         PROPOSED L4: PURPOSE
═══════════════════════════════════════════════════════════════════════════

Project: [Project name from package.json or directory]

Purpose: [One sentence - why this project exists]

Beneficiaries: [Who benefits from this project]

Success Metrics:
- [Metric 1]
- [Metric 2]
- [Metric 3]

Constraints:
- [Any ethical or technical constraints]

═══════════════════════════════════════════════════════════════════════════
```

Then ask:

**Does this capture your project's purpose? Would you like to refine it?**

Options:

- "Accept" - Proceed with this purpose
- "Refine" - Let's adjust the purpose statement
- "Start over" - Re-analyze with different focus

**STOP and WAIT for user response.**

---

## Step 3: Update L4 Purpose Spec

Once the user accepts (or after refinements), update
`telos/specs/L4-purpose/purpose.md`:

```markdown
<!-- telos-metadata
id: L4:purpose
level: 4
title: [Project Name]
-->

# L4: Purpose

## Why This Project Exists

[Purpose statement]

## Beneficiaries

[Who benefits]

## Success Metrics

- [Metric 1]
- [Metric 2]
- [Metric 3]

## Constraints

- [Constraint 1]
- [Constraint 2]

## Technology Stack

- **Languages**: [Detected]
- **Frameworks**: [Detected]
- **Testing**: [Detected]
- **Linting**: [Detected]

## Initialization

- **Date**: [Current date]
- **Method**: telos init
```

---

## Step 4: Define L3 Experiences (User Journeys)

Now ask about key user experiences. These are the main things users DO with the
application.

Ask:

**What are the key user journeys in your application?**

Examples of user journeys:

- "User signs up and creates their first project"
- "User searches for products and completes checkout"
- "Admin reviews and approves pending submissions"

List 2-5 key journeys (or say "skip" if you want to define these later):

**STOP and WAIT for user response.**

### 4.1 Create L3 Experience Specs

For each journey the user provides, create a spec file in
`telos/specs/L3-experience/`:

**Filename**: Convert journey to kebab-case (e.g., `user-signup-flow.md`)

```markdown
<!-- telos-metadata
id: L3:experience:[filename-without-extension]
level: 3
title: [Journey Title]
parent: L4:purpose
-->

# L3: [Journey Title]

## Overview

[Brief description of this user journey]

## User Story

As a [user type], I want to [action] so that [benefit].

## Journey Steps

1. **[Step 1 name]**
   - User action: [What the user does]
   - System response: [What happens]
   - Success criteria: [How we know it worked]

2. **[Step 2 name]**
   - User action: [What the user does]
   - System response: [What happens]
   - Success criteria: [How we know it worked]

[Continue for each step...]

## Edge Cases

- [Edge case 1]: [How it's handled]
- [Edge case 2]: [How it's handled]

## Analytics Events

- `[event_name]`: [When it fires, what it tracks]

## Related Specs

- L2: [Related contracts - to be defined]
- L1: [Related functions - to be defined]
```

### 4.2 Confirm Experiences

After creating the L3 specs, summarize:

```
═══════════════════════════════════════════════════════════════════════════
                      L3 EXPERIENCES CREATED
═══════════════════════════════════════════════════════════════════════════

Created [N] user journey specs:

1. telos/specs/L3-experience/[journey-1].md
   "[Journey 1 title]"

2. telos/specs/L3-experience/[journey-2].md
   "[Journey 2 title]"

[etc...]

These journeys will guide your L2 contracts and L1 functions.
═══════════════════════════════════════════════════════════════════════════
```

---

## Step 5: Define L2 Contracts (APIs & Components)

Now analyze the codebase for existing contracts OR ask the user about them.

### 5.1 Check for Existing Code

Scan for:

- API routes/endpoints (Express, FastAPI, Next.js API routes, etc.)
- React/Vue/Svelte components
- Service classes
- Database models/schemas

### 5.2 If Code Exists → Propose Contracts

If you found existing APIs/components, propose L2 specs:

```
═══════════════════════════════════════════════════════════════════════════
                    DETECTED L2 CONTRACTS
═══════════════════════════════════════════════════════════════════════════

Based on your codebase, I found these contracts:

APIs:
- POST /api/auth/login → api-auth-login
- GET /api/users/:id → api-users-get
[etc...]

Components:
- LoginForm → component-login-form
- UserProfile → component-user-profile
[etc...]

Should I create L2 specs for these? (yes/no/select specific ones)
═══════════════════════════════════════════════════════════════════════════
```

**STOP and WAIT for user response.**

### 5.3 If No Code OR Greenfield → Ask User

If no existing code found, ask:

**What are the main APIs or components you plan to build?**

Examples:

- "Authentication API (login, logout, register)"
- "Product listing component"
- "Payment processing service"

List your key contracts (or say "skip" to define later):

**STOP and WAIT for user response.**

### 5.4 Create L2 Contract Specs

For each contract, create a spec file in `telos/specs/L2-contract/`:

**Filename**: `api-[name].md` or `component-[name].md`

````markdown
<!-- telos-metadata
id: L2:contract:[filename-without-extension]
level: 2
title: [Contract Title]
parent: L3:experience:[related-journey]
-->

# L2: [Contract Title]

## Overview

[What this API/component does]

## Interface

### [For APIs]

**Endpoint:** `[METHOD] /api/[path]`

**Request:**

```json
{
  "field": "type"
}
```
````

**Response:**

```json
{
  "field": "type"
}
```

**Errors:**

- 400: [When/why]
- 401: [When/why]
- 404: [When/why]

### [For Components]

**Props:**

```typescript
interface [ComponentName]Props {
  prop1: type;
  prop2: type;
  onEvent?: (data: type) => void;
}
```

## Behavior

- [Behavior 1]
- [Behavior 2]

## Related Specs

- L3: [Parent experience]
- L1: [Functions needed - to be defined]

```
### 5.5 Confirm Contracts

After creating the L2 specs, summarize:
```

═══════════════════════════════════════════════════════════════════════════ L2
CONTRACTS CREATED
═══════════════════════════════════════════════════════════════════════════

Created [N] contract specs:

1. telos/specs/L2-contract/[contract-1].md "[Contract 1 title]"

2. telos/specs/L2-contract/[contract-2].md "[Contract 2 title]"

[etc...]
═══════════════════════════════════════════════════════════════════════════

```
---

## Step 6: Define L1 Functions

Now identify the key functions needed to implement the L2 contracts.

### 6.1 Check for Existing Functions

Scan for functions/methods in:

- `src/`, `lib/`, `app/` directories
- Look for exported functions, class methods
- Focus on business logic, not utility functions

### 6.2 If Functions Exist → Propose L1 Specs
```

═══════════════════════════════════════════════════════════════════════════
DETECTED L1 FUNCTIONS
═══════════════════════════════════════════════════════════════════════════

Found key functions that need specs:

From src/auth/:

- validateToken() → L1:function:src/auth:validateToken
- hashPassword() → L1:function:src/auth:hashPassword

From src/users/:

- createUser() → L1:function:src/users:createUser
- getUserById() → L1:function:src/users:getUserById

[etc...]

Should I create L1 specs for these? (yes/no/select specific ones)
═══════════════════════════════════════════════════════════════════════════

````
**STOP and WAIT for user response.**

### 6.3 If No Functions OR Greenfield → Ask User

If no existing functions found, ask:

**What are the core functions your application needs?**

Think about the L2 contracts you defined. What functions implement them?

Examples:

- "validateToken - checks if JWT is valid"
- "processPayment - handles Stripe charges"
- "sendNotification - sends push/email notifications"

List key functions (or say "skip" to define later):

**STOP and WAIT for user response.**

### 6.4 Create L1 Function Specs

For each function, create a spec file in `telos/specs/L1-function/`:

**Filename**: `[module]-[function-name].md`

```markdown
<!-- telos-metadata
id: L1:function:[path]:[functionName]
level: 1
title: [functionName]
parent: L2:contract:[related-contract]
-->

# L1: [functionName]

## Purpose

[What this function does and why]

## Signature

```typescript
function [functionName](
  param1: Type,
  param2: Type
): ReturnType
````

## Parameters

| Name   | Type | Description |
| ------ | ---- | ----------- |
| param1 | Type | Description |
| param2 | Type | Description |

## Returns

| Type       | Description     |
| ---------- | --------------- |
| ReturnType | What it returns |

## TDD Scenarios

### Scenario: [Happy path name]

```gherkin
Given [precondition]
When [action]
Then [expected result]
```

### Scenario: [Error case name]

```gherkin
Given [precondition]
When [action]
Then [expected error]
```

### Scenario: [Edge case name]

```gherkin
Given [edge condition]
When [action]
Then [expected behavior]
```

## Related Specs

- L2: [Parent contract]

```
### 6.5 Confirm Functions

After creating the L1 specs, summarize:
```

═══════════════════════════════════════════════════════════════════════════ L1
FUNCTIONS CREATED
═══════════════════════════════════════════════════════════════════════════

Created [N] function specs:

1. telos/specs/L1-function/[function-1].md "[function1Name]" - [brief
   description]

2. telos/specs/L1-function/[function-2].md "[function2Name]" - [brief
   description]

[etc...]
═══════════════════════════════════════════════════════════════════════════

```
---

## Step 7: Update TELOS.md

Update `telos/TELOS.md` with all the specs created:

- **User Experiences** section listing all L3 journeys
- **Spec Levels** table with correct counts for all levels
- Verify all parent-child relationships are correct

---

## Step 8: Final Summary

After saving all specs, provide the final summary:

---

✅ **Telos initialization complete!**

**Your project now has:**

- `telos/specs/L4-purpose/purpose.md` - Your project purpose
- `telos/specs/L3-experience/*.md` - [N] user journey specs
- `telos/specs/L2-contract/*.md` - [N] API/component contracts
- `telos/specs/L1-function/*.md` - [N] function specs with TDD scenarios
- `telos/TELOS.md` - Entry point with workflow guidance

**Spec Summary:**

| Level | Count | Description |
| ----- | ----- | ----------- |
| L4    | 1     | Purpose     |
| L3    | [N]   | Experiences |
| L2    | [N]   | Contracts   |
| L1    | [N]   | Functions   |

**Next steps:**

1. Generate tests from L1 specs
2. Implement code with `@telos` annotations
3. Validate before commits
4. For new features: Follow the workflow in `telos/TELOS.md`

---

## Tips

- If README is missing or vague, ask user for clarification
- For empty/greenfield projects, focus on defining clear specs before coding
- For brownfield projects, propose specs based on detected code
- Be conversational - this is a dialogue, not a survey
- Users can say "skip" at any level to define specs later
- Remind users that specs come before code
```
