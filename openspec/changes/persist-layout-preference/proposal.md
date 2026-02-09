## Why

Users switch between view modes (split, full terminal, full blocks) based on
their workflow for each connection. Currently, the layout resets to "split" on
every reconnect, forcing users to manually reconfigure their preferred view mode
each time. This friction disrupts productivity and feels inconsistent.

## What Changes

- Store each connection's last-used view mode in the database alongside other
  connection settings
- Automatically restore the saved view mode when reconnecting to a saved
  connection
- Save view mode changes immediately (or debounced) when user switches layouts
  during a session
- New/quick connections without saved entries default to split view (current
  behavior)

## Capabilities

### New Capabilities

- `layout-persistence`: Per-connection storage and restoration of view mode
  preferences

### Modified Capabilities

<!-- No existing specs require requirement changes - this is additive to the SavedConnection model -->

## Impact

- **Database**: Migration to schema version 5, adding `preferred_view_mode`
  column to `saved_connections` table
- **Entity**: `SavedConnection` gains `preferredViewMode` field
- **Repository**: `ConnectionRepository` updated for view mode save/load
- **Provider**: `ViewModeController` becomes connection-aware (loads from saved
  connection on session start, persists on change)
- **Session flow**: Session initialization loads view mode from saved connection
  if available
