# Proposal: Tappable Elements

## Why

Terminal output contains actionable data - IP addresses, file paths, URLs - that
users want to interact with. Parsing and making these elements tappable
transforms passive text into an interactive interface, enabling quick actions
like "SSH to this IP" or "View this file".

## What Changes

- Implement BlockParser for pattern detection
- Parse IP addresses with regex
- Parse file paths (absolute and relative)
- Parse URLs (http, https)
- Parse JSON blocks for tree view
- Create context menus for tappable elements
- Add actions: copy, SSH to host, view file, open URL
- Highlight tappable elements on touch

## Capabilities

### New Capabilities

- `block-parser`: Pattern detection in output
- `tappable-ip`: Interactive IP addresses
- `tappable-path`: Interactive file paths
- `tappable-url`: Interactive URLs
- `context-menu`: Action menus for elements

## Impact

- `lib/features/terminal/domain/usecases/parse_tappable_elements.dart`: Parser
- `lib/features/terminal/domain/entities/tappable_element.dart`: Element entity
- `lib/features/terminal/presentation/widgets/tappable_text.dart`: Tappable
  widget

## Dependencies

- `semantic-blocks`: Requires block output
- `scaffold-flutter-project`: Requires Flutter project structure

## Phase

**Phase 1 - MVP** (Weeks 7-8)

## Priority

**P2 - Nice to Have**
