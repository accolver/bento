# Proposal: GitHub Templates

## Why

Open source projects need structured issue and PR templates to gather necessary
information from contributors. Bug reports need reproduction steps, feature
requests need use cases, and PRs need changelog entries. Templates reduce
back-and-forth and improve contribution quality.

## What Changes

- Create bug report issue template
  - Device, OS version, app version
  - Steps to reproduce
  - Expected vs actual behavior
  - Logs/screenshots
- Create feature request template
  - Use case description
  - Proposed solution
  - Alternatives considered
- Create question template
  - Context and what was tried
- Create PR template
  - Description of changes
  - Changelog entry
  - Testing performed
  - Checklist (tests, lint, docs)

## Capabilities

### New Capabilities

- `bug-template`: Structured bug reports
- `feature-template`: Feature request format
- `question-template`: Q&A format
- `pr-template`: PR submission format

## Impact

- `.github/ISSUE_TEMPLATE/bug_report.md`: Bug report template
- `.github/ISSUE_TEMPLATE/feature_request.md`: Feature request template
- `.github/ISSUE_TEMPLATE/question.md`: Question template
- `.github/PULL_REQUEST_TEMPLATE.md`: PR template

## Dependencies

- None - can be created independently

## Phase

**Phase 4 - Polish** (Months 11-12)

## Priority

**P1 - Should Have**

Important for open-source community engagement.
