<!-- telos-metadata
id: L3:experience:ai-command-assistance
level: 3
title: AI Command Assistance
parent: L4:purpose
children:
  - L2:contract:service-ai-gateway
  - L2:contract:component-command-ribbon
  - L2:contract:component-ghostwriter-modal
-->

# L3: AI Command Assistance

## Overview

A mobile developer gets command help in two distinct ways: **fast predictive
completion while typing** and **explicit AI command generation when intent is
hard to express as shell syntax**. Bento must keep these flows separate so the
user gets instant, trustworthy suggestions without the ribbon feeling slow,
noisy, or invasive.

## User Story

As a **developer working in a terminal on a phone**, I want to **get immediate
command help without losing control of the shell** so that **I can type less,
avoid syntax mistakes, and still use AI when I need higher-level help**.

## Journey Steps

1. **Start Typing at a Shell Prompt**
   - User action: Begins typing into a normal shell prompt
   - System response: Shows a command ribbon with low-latency suggestions from
     history, command knowledge, snippets, and symbols
   - Success criteria: Suggestions appear within 100ms and do not block typing

2. **Use Fast Deterministic Completion**
   - User action: Types a partial token like `kub` or `docker co`
   - System response: Shows token-aware completions such as `kubectl` or
     `compose`
   - Success criteria: Tapping a suggestion replaces only the active token,
     preserves the rest of the line, and appends a trailing space when helpful

3. **Escalate to AI When Needed**
   - User action: Taps the AI affordance because the desired command is too
     complex to complete from syntax alone
   - System response: Opens explicit AI assistance for either full-command
     generation or line completion
   - Success criteria: AI is opt-in and never silently rewrites the line

4. **Review the AI Suggestion**
   - User action: Reads the suggested command and explanation
   - System response: Shows confidence, explanation, and safe actions to
     insert, replace, edit, copy, or execute
   - Success criteria: User can understand the command before it runs

5. **Apply the Suggestion Safely**
   - User action: Accepts a ribbon or AI suggestion
   - System response: Applies it only to the intended token or line region
   - Success criteria: No duplicated text, no corrupted shell state, no hidden
     mutations

6. **Return to Normal Typing**
   - User action: Continues editing or submits the command
   - System response: Ribbon updates based on the new prompt input state or
     hides when command execution/TUI mode begins
   - Success criteria: Assistance never appears during full-screen TUI apps or
     while command output is streaming

## Interaction Model

### 1. Predictive Ribbon

Used for:
- command name completion
- subcommand completion
- argument/resource hints
- history-based repetition
- symbol insertion
- snippet insertion

Properties:
- deterministic
- local/instant
- safe to use per keystroke
- no network/model call required

### 2. AI Assistance

Used for:
- natural-language-to-command generation
- complex flag composition
- turning partial intent into a full line
- offering alternatives when requests are ambiguous

Properties:
- explicit, never implicit
- may be local, remote, or cloud depending on privacy mode
- provides explanation and confidence
- should not fire on every keystroke

## Edge Cases

- **TUI active**: No ribbon suggestions while vim, htop, Claude Code, etc. own
  the screen
- **Command running**: Ribbon hides or freezes while the shell is not at a
  prompt
- **Unknown shell state**: Bento must avoid destructive inline edits if prompt
  state is uncertain
- **Ambiguous AI request**: Show alternatives or ask for clarification
- **Dangerous command**: Warn before execution for destructive operations
- **Cloud AI disabled**: Ribbon still works fully; AI uses allowed provider only

## Privacy Considerations

- Predictive ribbon should work without sending prompt text anywhere
- AI escalation must respect privacy mode before any external transmission
- Error output and sensitive command content remain local/private unless the
  user has explicitly chosen a non-private mode
- AI should receive the minimum context needed: shell, OS, cwd, recent commands,
  and optionally available tools

## Analytics Events

- `command_ribbon_shown`
- `command_ribbon_suggestion_tapped`
- `command_ribbon_ai_escalation_tapped`
- `command_ribbon_symbol_tapped`
- `ghostwriter_opened`
- `ghostwriter_query_submitted`
- `ghostwriter_suggestion_accepted`
- `ghostwriter_suggestion_edited`
- `ghostwriter_provider_used`

## Success Metrics

- Ribbon suggestion latency: < 100ms
- AI suggestion latency: < 2s local/private, < 5s cloud
- Keystroke reduction: > 50% for repeated command workflows
- Ribbon acceptance rate: > 35% for eligible prompt sessions
- AI acceptance rate: > 60% for explicit AI requests
- Command corruption incidents: 0 tolerated

## Related Specs

- L2: [AI Gateway Service](../L2-contract/service-ai-gateway.md)
- L2: [Command Ribbon Component](../L2-contract/component-command-ribbon.md)
- L2: [Ghostwriter Modal Component](../L2-contract/component-ghostwriter-modal.md)
