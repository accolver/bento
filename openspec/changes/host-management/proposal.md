# Proposal: Host Management

## Why

Users connect to the same servers repeatedly. Host management allows saving,
organizing, and quickly accessing frequently used connections. Folders help
organize hosts by environment (production, staging) or purpose (work, personal).

## What Changes

- Define Host entity with freezed
- Create Hosts table schema with Drift
- Implement ConnectionPicker modal UI
- Add host create/edit/delete functionality
- Support host folders for organization
- Show recent connections with timestamps
- Add host search and filtering
- Support jump host (bastion) configuration

## Capabilities

### New Capabilities

- `host-entity`: Host configuration model
- `connection-picker`: Host selection modal
- `host-folders`: Organizational structure
- `host-crud`: Create, read, update, delete
- `recent-connections`: Quick access to recent hosts

## Impact

- `lib/features/connections/domain/entities/host.dart`: Host entity
- `lib/database/tables/hosts.dart`: Hosts table
- `lib/features/connections/presentation/screens/connection_picker.dart`: Picker
  UI
- `lib/features/connections/presentation/screens/host_editor.dart`: Editor UI

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `credential-storage`: Requires secure key references

## Phase

**Phase 1 - MVP** (Weeks 9-10)

## Priority

**P2 - Nice to Have**
