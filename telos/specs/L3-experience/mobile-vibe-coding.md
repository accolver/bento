<!-- telos-metadata
id: L3:experience:mobile-vibe-coding
level: 3
title: Mobile Vibe Coding
parent: L4:purpose
children:
  - L2:contract:service-snippet
  - L2:contract:service-ai-gateway
  - L2:contract:component-ghostwriter-modal
-->

# L3: Mobile Vibe Coding

## Overview

A developer connects to their remote development environment while on the go -
at a coffee shop, on transit, or lounging at home - and productively works on
code using AI assistance to overcome mobile input limitations.

## User Story

As a **developer who wants to code from anywhere**, I want to **connect to my
dev environment and use AI to help write and run code** so that **I can be
productive during downtime without needing my laptop**.

## Journey Steps

1. **Spontaneous Coding Session**
   - User action: Has an idea while away from desk, opens Bento
   - System response: Shows recent sessions, including dev server connection
   - Success criteria: Can quickly connect to familiar dev environment

2. **Connect to Dev Environment**
   - User action: Taps saved "dev-server" or Tailscale node
   - System response: Connects via Mosh, navigates to project directory
   - Success criteria: In project directory ready to work within 5 seconds

3. **Review Current State**
   - User action: Runs `git status`, `git log --oneline -5`
   - System response: Shows blocks with clean output, tappable commit hashes
   - Success criteria: Understands current branch state quickly

4. **AI-Assisted Code Writing**
   - User action: Opens AI Ghostwriter, describes "create a function that
     validates email addresses with proper RFC 5322 regex"
   - System response: AI generates code snippet or full command to create file
   - Success criteria: Gets working code without typing it character by
     character

5. **Edit with AI Help**
   - User action: Asks AI "add error handling to the validateEmail function in
     src/utils.ts"
   - System response: AI suggests sed/awk command or generates patch
   - Success criteria: Can make targeted code changes via CLI

6. **Run and Test**
   - User action: Executes `npm test` or equivalent
   - System response: Test output in block, AI summarizes "3 tests passed, 1
     failed"
   - Success criteria: Understands test results without reading full output

7. **Fix Failing Test**
   - User action: Reviews error, asks AI for fix suggestion
   - System response: AI analyzes test failure, suggests code change
   - Success criteria: Can iterate on code until tests pass

8. **Commit and Push**
   - User action: Uses snippet or AI to generate commit message
   - System response: AI suggests "feat: add email validation with RFC 5322
     compliance"
   - Success criteria: Clean commit with good message, pushed to remote

9. **Context Preservation**
   - User action: Puts phone away, resumes later
   - System response: Session survives, all blocks and context preserved
   - Success criteria: Can pick up exactly where left off

## Vibe Coding Enablers

| Challenge                    | Bento Solution                            |
| ---------------------------- | ----------------------------------------- |
| Typing code on phone is slow | AI generates code from descriptions       |
| Can't see enough context     | Blocks collapse, AI summarizes output     |
| Hard to navigate files       | AI suggests correct paths, tab completion |
| Typos in commands            | Predictive ribbon, error healing          |
| Losing work on disconnect    | Mosh persistence, local block storage     |
| Complex git commands         | Snippets for common workflows             |

## AI Prompts for Vibe Coding

- "Show me the last 20 lines of src/auth/login.ts"
- "Add a try-catch block around the database call in line 45"
- "Create a new React component called UserProfile with name and email props"
- "Run the tests for the auth module only"
- "Generate a commit message for these changes"
- "What files have I modified today?"

## Edge Cases

- **Large file edits**: Suggest using vim/nano with AI-generated commands
- **Merge conflicts**: AI helps understand conflicts, suggests resolutions
- **Build failures**: Error healing kicks in for compilation errors
- **Network interruption**: Mosh maintains session, can continue on reconnect
- **Battery concerns**: Minimal CPU usage, session survives backgrounding

## Workflow Snippets

```yaml
# Quick git workflow
- name: "Commit & Push"
  command: "git add -A && git commit -m '${message}' && git push"
  variables:
    - name: message
      required: true

# Run specific test
- name: "Test File"
  command: "npm test -- --grep '${pattern}'"
  variables:
    - name: pattern
      default: ""

# Quick file view
- name: "View File"
  command: "bat --paging=never ${filepath}"
  variables:
    - name: filepath
      required: true
```

## Analytics Events

- `vibe_coding_session_started`: Long session with multiple AI interactions
- `ai_code_generation_requested`: User asked AI to write code
- `code_commit_via_mobile`: Successful git commit from Bento
- `test_run_completed`: Test suite executed
- `session_duration_extended`: Session lasted > 30 minutes

## Success Metrics

- Code commits from mobile: Track adoption of mobile development
- AI interactions per session: Higher = more "vibe coding"
- Session duration for dev work: > 15 minutes indicates productive sessions
- Return rate: Users who vibe-code come back regularly

## Related Specs

- L3: [AI Command Assistance](ai-command-assistance.md)
- L3: [Error Recovery](error-recovery.md)
- L2: [To be defined - AI code generation contract]
- L2: [To be defined - Snippet execution contract]
- L1: [To be defined - Git workflow helpers]
