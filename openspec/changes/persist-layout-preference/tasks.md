## 1. Database Schema

- [x] 1.1 Update `DatabaseConstants.schemaVersion` from 4 to 5 in
      `app_constants.dart`
- [x] 1.2 Add migration case 5 in `database.dart` to add `preferred_view_mode`
      column to `saved_connections` table
- [x] 1.3 Add `preferredViewMode` column definition to `SavedConnections` table
      in `saved_connections.dart`

## 2. Entity Updates

- [x] 2.1 Add `preferredViewMode` field to `SavedConnection` entity with default
      value 'split'
- [x] 2.2 Run `dart run build_runner build` to regenerate Drift and Freezed code

## 3. Repository Layer

- [x] 3.1 Update `ConnectionRepository` to include `preferredViewMode` when
      saving connections
- [x] 3.2 Add `updateViewModePreference(int connectionId, String viewMode)`
      method to repository
- [x] 3.3 Ensure view mode preference is loaded when fetching saved connections

## 4. Provider Integration

- [x] 4.1 Add method to `ViewModeController` to load preference from a saved
      connection
- [x] 4.2 Add connection ID tracking to `ViewModeController` for knowing which
      connection to update
- [x] 4.3 Update `ViewModeController.setViewMode()` to persist changes when
      connected to a saved connection

## 5. Session Integration

- [x] 5.1 Load and apply saved view mode preference when session connects to a
      saved connection
- [x] 5.2 Clear connection tracking when session disconnects

## 6. Tests

- [x] 6.1 Add unit tests for database migration (schema version 5)
- [x] 6.2 Add unit tests for `SavedConnection` entity with `preferredViewMode`
      field
- [x] 6.3 Add unit tests for repository view mode save/load methods
- [x] 6.4 Add unit tests for `ViewModeController` persistence behavior
