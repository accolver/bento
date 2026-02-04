# Proposal: Session Tabs

## Why

Power users need multiple concurrent terminal sessions - production, staging,
local development. Session tabs provide a familiar interface for managing
multiple connections with visual status indicators showing connection state at a
glance. Session persistence ensures work isn't lost when the app is closed.

## What Changes

- Define Session entity with freezed
- Create Sessions table schema with Drift
- Implement TabBar widget with status indicators
- Handle session creation, switching, closing
- Implement session persistence across app restarts
- Add session close confirmation for active sessions
- Support swipe navigation between tabs
- Show connection status (green=connected, red=disconnected, yellow=background)

## Capabilities

### New Capabilities

- `session-entity`: Session data model
- `session-tabs`: Tab bar UI component
- `session-state`: Connection status tracking
- `session-persistence`: SQLite storage
- `session-navigation`: Tab switching and swipe

## Impact

- `lib/features/terminal/domain/entities/session.dart`: Session entity
- `lib/database/tables/sessions.dart`: Sessions table
- `lib/features/terminal/presentation/widgets/session_tab_bar.dart`: Tab bar
- `lib/features/terminal/presentation/providers/session_provider.dart`: State

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `ssh-connectivity`: Requires connection management

## Phase

**Phase 1 - MVP** (Weeks 9-10)

## Priority

**P0 - Must Have**
