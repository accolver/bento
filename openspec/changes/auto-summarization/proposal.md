# Proposal: Auto-Summarization

## Why

Long command output requires scrolling to understand. Auto-summarization uses AI
to distill verbose output into 1-2 sentences - "3 pods running, all healthy"
instead of 50 lines of kubectl output. Users can tap to see full details.

## What Changes

- Implement summarizeOutput usecase
- Create summary prompt templates
- Show summary in collapsed block header
- Add tap-to-expand full output
- Add enable/disable in settings

## Phase

**Phase 3 - Visualization** (Months 8-10)

## Priority

**P1 - Should Have**
