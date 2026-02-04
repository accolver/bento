# Proposal: Block Persistence

## Why

Users expect their command history and output to survive app restarts. Block
persistence using Drift (SQLite) provides type-safe, queryable storage for all
blocks. This enables features like history search, session restoration, and
offline browsing of past commands.

## What Changes

- Create Blocks table schema with Drift
- Create BlockDao for CRUD operations
- Implement block save on command completion
- Implement block list loading for sessions
- Add full-text search capability for blocks
- Handle large output storage efficiently
- Implement block indexing for fast queries
- Add block count limits per session (configurable)

## Capabilities

### New Capabilities

- `block-storage`: SQLite persistence via Drift
- `block-crud`: Create, read, update, delete operations
- `block-search`: Full-text search across blocks
- `block-loading`: Efficient lazy loading

## Impact

- `lib/database/tables/blocks.dart`: Blocks table definition
- `lib/database/daos/block_dao.dart`: Block data access object
- `lib/features/terminal/data/repositories/block_repository_impl.dart`:
  Repository
- `lib/database/database.dart`: Database configuration

## Dependencies

- `scaffold-flutter-project`: Requires Drift setup
- `semantic-blocks`: Requires block entity definition

## Phase

**Phase 1 - MVP** (Weeks 7-8, parallel with semantic-blocks)

## Priority

**P0 - Must Have**
