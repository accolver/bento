# AI Command Assistance Redesign

## Goal

Redesign Bento's command assistance so that mobile CLI help is reliable,
low-latency, and safe.

## Problem Summary

The previous implementation mixes several concerns:
- terminal byte-stream handling
- semantic block input capture
- command-ribbon suggestion state
- AI Ghostwriter flows

This causes incorrect insertion behavior, weak live updates, and blurry product
boundaries between autocomplete and AI generation.

## Product Split

### 1. Deterministic Ribbon

Purpose: instant autocomplete while typing at a shell prompt.

Sources:
- recent command history
- command knowledge base
- snippets
- symbols
- optional file/path completion later

Constraints:
- no network request
- no model call
- safe per keystroke
- hidden in TUI mode or uncertain shell state

### 2. AI Line Completion

Purpose: explicit AI refinement of the current shell line.

Examples:
- expand a partial AWS/Kubernetes command
- suggest missing flags
- provide multiple plausible completions

Constraints:
- user-initiated only
- never runs on every keystroke
- respects privacy mode
- returns insert/replace/edit choices before execution

### 3. Ghostwriter Modal

Purpose: natural language to full command generation.

Examples:
- "show S3 buckets tagged env=prod"
- "find large log files modified today"

Constraints:
- explicit invocation
- explanation + confidence required
- may use local, remote, or cloud AI

## Architecture

### PromptInputController

Canonical session-scoped model for the editable shell line.

Tracks:
- current line text
- cursor offset
- prompt availability
- TUI mode
- whether ribbon can be shown

It should be fed by:
- prompt detection events
- command start/finish events
- explicit local edits/applications from Bento

It should not attempt to model the remote shell perfectly when state is
uncertain.

### Suggestion Ranking Service

Pure deterministic ranking function.

Input:
- prompt input state
- history
- command knowledge
- snippets

Output:
- structured suggestions with replacement ranges

### Suggestion Apply Service

Pure function to apply one suggestion to the current line.

Must:
- replace only intended token range
- preserve surrounding text
- move cursor predictably
- clamp invalid ranges safely

### AI Gateway Extension

Add `completeCommandLine(...)` for explicit ribbon-to-AI escalation.

## Files Likely to Replace

High confidence replacement targets:
- `lib/features/terminal/presentation/providers/command_ribbon_provider.dart`
- `lib/features/terminal/presentation/widgets/command_ribbon.dart`

High confidence integration refactors:
- `lib/features/terminal/presentation/screens/terminal_screen.dart`
- `lib/features/session/presentation/providers/session_terminal_controller.dart`
- `lib/features/terminal/presentation/providers/output_router_provider.dart`

Likely reusable:
- `lib/features/terminal/domain/entities/command_knowledge.dart`
- `lib/features/ai/presentation/widgets/ai_ghostwriter_panel.dart`
- `lib/features/ai/domain/services/prompt_templates.dart`

## Delivery Phases

### Phase 1: Spec + Tests
- update Telos specs
- add prompt input controller tests
- add ranking tests
- add apply-suggestion tests
- add explicit AI line completion tests

### Phase 2: Deterministic Ribbon Rebuild
- create prompt input controller
- create pure ranking/apply services
- rebuild ribbon widget
- wire live prompt state into terminal screen

### Phase 3: AI Escalation
- add explicit AI chip/action
- implement `completeCommandLine(...)`
- connect to Ghostwriter or inline AI preview

### Phase 4: Cleanup
- delete obsolete ribbon logic
- remove dead history wiring
- verify TUI and semantic block interactions

## Non-Goals for First Rebuild

- true shell-native tab-completion parity
- full remote shell line-editor emulation
- AI inference on every keystroke
- aggressive file-system completion over SSH

## Success Criteria

- ribbon suggestions update from live prompt state
- tapping a suggestion never corrupts command text
- ribbon hides correctly in TUI mode
- deterministic path is fast and testable
- AI remains explicit and privacy-safe
