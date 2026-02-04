# Proposal: Mosh Connectivity

## Why

SSH connections drop when network changes (Wi-Fi to cellular, moving between
access points). Mosh (Mobile Shell) uses UDP with its State Synchronization
Protocol to maintain sessions across network transitions. This is critical for
mobile users who are constantly moving between networks.

## What Changes

- Set up platform channels for Mosh native code
- Integrate precompiled Mosh libraries (iOS/Android)
- Implement MoshClient wrapper class
- Handle Mosh session state persistence for resume
- Implement automatic reconnection on network change
- Add protocol selection logic (prefer Mosh when available)
- Show roaming indicator in session tab
- Fallback to SSH when Mosh unavailable on server

## Capabilities

### New Capabilities

- `mosh-client`: UDP-based mobile shell
- `session-roaming`: Survive network transitions
- `mosh-state`: Session state persistence
- `protocol-selection`: Auto-select best protocol

## Impact

- `lib/features/terminal/data/datasources/mosh_datasource.dart`: Mosh client
- `ios/Runner/MoshPlugin.swift`: iOS native code
- `android/app/src/main/kotlin/MoshPlugin.kt`: Android native code

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `ssh-connectivity`: Fallback and initial key exchange

## Phase

**Phase 1 - MVP** (Weeks 9-10)

## Priority

**P1 - Should Have**
