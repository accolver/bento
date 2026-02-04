# Proposal: AI Ghostwriter

## Why

Typing complex CLI commands on mobile is error-prone. The Ghostwriter modal lets
users describe what they want in natural language and get correct CLI syntax.
This is Bento's flagship AI feature - "show s3 buckets tagged with env=prod"
becomes the correct aws s3api command.

## What Changes

- Create GhostwriterModal widget
- Implement generateCommand usecase
- Build context-aware prompt templates (shell, OS, cwd)
- Show suggestions with confidence scores
- Add edit, copy, execute actions
- Show brief command explanation
- Track suggestion acceptance for improvement

## Capabilities

### New Capabilities

- `ghostwriter-modal`: Natural language input UI
- `command-generation`: AI-powered CLI synthesis
- `context-awareness`: Shell, OS, directory context

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have**
