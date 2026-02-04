# Proposal: SSH Agent Support

## Why

SSH agent forwarding is essential for users who need to authenticate to multiple
servers in a chain (jump hosts) or access services like Git from remote servers.
Without agent support, users must either copy private keys to servers (security
risk) or cannot use key-based authentication for onward connections.

## What Changes

- Implement SSHAgentService for managing loaded keys
- Support adding keys to in-memory agent (requires biometric auth)
- Implement SSH agent protocol for signing requests
- Enable agent forwarding during SSH connections
- Clear loaded keys on app background/lock for security
- Track loaded keys with public key fingerprints
- Integrate with credential vault for secure key retrieval

## Capabilities

### New Capabilities

- `ssh-agent-service`: In-memory key management
- `agent-forwarding`: Forward agent to remote hosts
- `key-signing`: Sign data with loaded keys
- `agent-security`: Auto-clear keys on background

## Impact

- `lib/features/connections/data/services/ssh_agent_service.dart`: Agent service
- `lib/features/connections/domain/entities/agent_key.dart`: Loaded key entity
- `lib/features/connections/presentation/providers/ssh_agent_provider.dart`:
  Agent state
- Modify `ssh_datasource.dart` to enable agent forwarding option

## Dependencies

- `credential-storage`: Requires secure key storage
- `ssh-connectivity`: Integrates with SSH connections

## Phase

**Phase 1 - MVP** (Should Have P1)

## Priority

**P1 - Should Have**

Security-conscious users expect agent support for multi-hop SSH workflows.
