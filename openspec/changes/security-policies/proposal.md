# Proposal: Security Policies

## Why

A mobile terminal app handles sensitive credentials and connects to critical
infrastructure. Comprehensive security policies protect users from device theft,
malicious apps, and data leaks. Users must trust that their SSH keys and session
data are secure.

## What Changes

- Implement session timeout (clear keys after 5 min inactivity)
- Auto-clear clipboard after 60 seconds for sensitive data
- Disable screen capture on credential screens (FLAG_SECURE)
- Implement certificate pinning for cloud AI API calls
- Run local AI models in sandboxed process
- Detect and warn about rooted/jailbroken devices
- Implement secure memory handling for keys
- Add security settings screen for user configuration

## Capabilities

### New Capabilities

- `session-timeout`: Auto-lock after inactivity
- `clipboard-security`: Auto-clear sensitive clipboard data
- `screen-security`: Prevent screenshots of credential screens
- `certificate-pinning`: Pin cloud API certificates
- `device-integrity`: Root/jailbreak detection
- `secure-memory`: Clear sensitive data from memory

## Impact

- `lib/core/security/security_policy_service.dart`: Policy enforcement
- `lib/core/security/clipboard_security.dart`: Clipboard management
- `lib/core/security/screen_security.dart`: Screenshot prevention
- `lib/core/security/certificate_pinning.dart`: Network security
- `lib/features/settings/presentation/screens/security_settings_screen.dart`:
  Settings UI
- Platform-specific code for FLAG_SECURE and secure memory

## Dependencies

- `credential-storage`: Works with secure storage
- `ssh-agent`: Manages key timeout behavior

## Phase

**Phase 1 - MVP** (Should Have P1)

## Priority

**P1 - Should Have**

Security is foundational - users must trust the app with their credentials.
