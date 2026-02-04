# Proposal: Output Parsers

## Why

Common commands like `df -h` and `ps aux` produce tabular text output. Parsing
this into structured data enables visual widgets - progress bars for disk usage,
sortable tables for processes. This transforms text walls into actionable
information.

## What Changes

- Implement df parser for disk usage visualization
- Implement ps parser for process tables
- Implement free parser for memory stats
- Implement netstat parser for network connections
- Create visual widgets for each parsed data type

## Phase

**Phase 3 - Visualization** (Months 8-10)

## Priority

**P0 - Must Have**
