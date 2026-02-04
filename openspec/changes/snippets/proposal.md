# Proposal: Snippets

## Why

Power users have commands they run repeatedly with slight variations. Snippets
are command templates with variable substitution - "kubectl set image
deployment/${deployment} ${container}=${image}:${tag}" becomes a form with
fields. This eliminates repetitive typing and reduces errors.

## What Changes

- Define Snippet entity with variables (name, default, required)
- Create Snippets table schema
- Implement renderSnippet function for variable substitution
- Create SnippetEditor widget for creation/editing
- Create SnippetExecutor widget with variable form
- Add snippet library browser with search
- Support tags for organization

## Capabilities

### New Capabilities

- `snippet-entity`: Template data model
- `snippet-rendering`: Variable substitution
- `snippet-library`: Browse and search snippets

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P1 - Should Have**
