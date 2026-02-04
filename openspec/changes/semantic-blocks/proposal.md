# Proposal: Semantic Blocks

## Why

Semantic Blocks are Bento's core differentiator. Instead of continuous scrolling
text, every command and its output is a discrete, self-contained unit that can
be collapsed, expanded, searched, and navigated independently. This transforms
the chaotic terminal experience into an organized, structured interface - like a
bento box with compartments.

## What Changes

- Define Block entity with freezed immutable data class
- Implement BlockStatus enum (running, success, failed, cancelled)
- Create BlockWidget UI component with header, output, actions
- Implement block collapse/expand with smooth animation
- Add block header with command, timestamp, status indicator
- Style blocks by status (green=success, red=failed, blue=running)
- Add block action buttons (copy, pin, search, share)
- Implement block creation when command is entered
- Stream output into block as it arrives

## Capabilities

### New Capabilities

- `block-entity`: Immutable block data model
- `block-widget`: Collapsible block UI component
- `block-states`: Visual status indicators
- `block-actions`: Copy, pin, search, share
- `block-streaming`: Real-time output display

## Impact

- `lib/features/terminal/domain/entities/block.dart`: Block entity
- `lib/features/terminal/presentation/widgets/block_widget.dart`: Block UI
- `lib/features/terminal/presentation/providers/block_provider.dart`: Block
  state
- `lib/core/constants/block_status.dart`: Status enum and colors

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `terminal-emulation`: Integrates with terminal output

## Phase

**Phase 1 - MVP** (Weeks 7-8)

## Priority

**P0 - Must Have**
