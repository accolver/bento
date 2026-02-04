# Proposal: Error Healing

## Why

When commands fail, users often need to google the error message. Error healing
analyzes stderr and exit codes to suggest fixes - adding sudo, installing
packages, fixing syntax. One-tap fix application reduces frustration and speeds
recovery.

## What Changes

- Implement healError usecase
- Create HealBanner widget for failed blocks
- Detect non-zero exit codes automatically
- Analyze common error patterns
- Generate fix suggestions with explanations
- Implement apply-fix action
- Track healing success/failure rates

## Capabilities

### New Capabilities

- `error-detection`: Automatic failure detection
- `heal-banner`: Fix suggestion UI
- `fix-generation`: AI-powered error analysis
- `fix-application`: One-tap fix execution

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have**
