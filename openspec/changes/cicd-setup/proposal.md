# Proposal: CI/CD Setup

## Why

Automated testing and deployment ensures code quality and enables consistent
releases. CI validates every PR with tests, linting, and analysis. CD automates
TestFlight/Play Store deployments for beta testing. This is essential for
open-source sustainability.

## What Changes

- Create GitHub Actions workflow for CI
  - Run `flutter analyze` for static analysis
  - Run `flutter test` for unit tests
  - Check code formatting with `dart format`
  - Run build_runner to verify code generation
- Create release workflow for CD
  - Build iOS and Android artifacts
  - Deploy to TestFlight and Play Store internal track
  - Generate changelog from commits
- Add CodeQL workflow for security scanning
- Configure CODEOWNERS for review requirements

## Capabilities

### New Capabilities

- `ci-workflow`: Automated PR validation
- `release-workflow`: Automated app deployment
- `security-scanning`: CodeQL analysis
- `code-ownership`: CODEOWNERS configuration

## Impact

- `.github/workflows/ci.yml`: CI workflow
- `.github/workflows/release.yml`: Release workflow
- `.github/workflows/codeql.yml`: Security scanning
- `.github/CODEOWNERS`: Code ownership rules
- `scripts/build.sh`: Build helper script

## Dependencies

- `scaffold-flutter-project`: Requires project structure

## Phase

**Phase 1 - MVP** (Weeks 1-2 - Project Setup)

## Priority

**P0 - Must Have**

Foundation for development workflow and quality assurance.
