# Proposal: Tailscale Integration

## Why

Tailscale users have a mesh VPN with easy access to all their devices.
Integrating with the Tailscale app allows Bento to show all connected nodes
directly in the connection picker, eliminating manual IP entry for homelab and
work devices.

## What Changes

- Set up platform channels for Tailscale API
- Implement TailscaleService for node queries
- Query list of available Tailscale nodes
- Show nodes in ConnectionPicker with online status
- Display node name, IP, and OS
- Handle offline nodes gracefully
- Add refresh capability for node list
- Auto-detect Tailscale availability

## Capabilities

### New Capabilities

- `tailscale-service`: Platform channel service
- `tailscale-nodes`: Node list query
- `tailscale-status`: Online/offline detection
- `tailscale-picker`: Nodes in connection picker

## Impact

- `lib/features/connections/data/services/tailscale_service.dart`: Service
- `ios/Runner/TailscalePlugin.swift`: iOS native code
- `android/app/src/main/kotlin/TailscalePlugin.kt`: Android native code

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `host-management`: Integrates with connection picker

## Phase

**Phase 1 - MVP** (Weeks 9-10)

## Priority

**P2 - Nice to Have**
