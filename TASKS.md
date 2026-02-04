# Bento - Implementation Tasks

> Master task list derived from PRD.md, organized by implementation phase and
> priority.

---

## Overview

This document tracks all features extracted from the PRD, organized into
implementation phases with OpenSpec change references.

| Phase       | Timeline     | Focus         | Changes    |
| ----------- | ------------ | ------------- | ---------- |
| **Phase 1** | Months 1-4   | MVP Core      | 10 changes |
| **Phase 2** | Months 5-7   | Intelligence  | 7 changes  |
| **Phase 3** | Months 8-10  | Visualization | 5 changes  |
| **Phase 4** | Months 11-12 | Polish        | 4 changes  |

---

## Phase 1: MVP Core (Months 1-4)

### P0 - Must Have

#### 1. Project Scaffolding

- **Change**: `scaffold-flutter-project`
- **Scope**: Flutter project setup, architecture, CI/CD
- **Weeks**: 1-2
- **Tasks**:
  - [ ] Initialize Flutter project with pubspec.yaml
  - [ ] Set up Clean Architecture folder structure
  - [ ] Configure Riverpod for state management
  - [ ] Set up go_router for navigation
  - [ ] Configure Drift for SQLite
  - [ ] Set up build_runner and code generation
  - [ ] Configure linting (flutter_lints)
  - [ ] Set up CI/CD workflows (.github/workflows)
  - [ ] Add asset directories (icons, fonts, models)

#### 2. Terminal Emulation Core

- **Change**: `terminal-emulation`
- **Scope**: xterm integration, ANSI rendering
- **Weeks**: 3-4
- **Tasks**:
  - [ ] Integrate xterm package
  - [ ] Configure terminal view with 256 color support
  - [ ] Handle ANSI escape sequences
  - [ ] Implement terminal sizing/resize
  - [ ] Add font configuration (JetBrains Mono)
  - [ ] Implement input handling
  - [ ] Add cursor rendering

#### 3. SSH Connectivity

- **Change**: `ssh-connectivity`
- **Scope**: dartssh2 integration, key auth
- **Weeks**: 5-6
- **Tasks**:
  - [ ] Integrate dartssh2 package
  - [ ] Implement SSHClient wrapper
  - [ ] Support key-based authentication
  - [ ] Support password authentication
  - [ ] Handle connection errors with Either types
  - [ ] Implement PTY configuration
  - [ ] Stream stdout/stderr

#### 4. Semantic Blocks

- **Change**: `semantic-blocks`
- **Scope**: Block creation, state, UI
- **Weeks**: 7-8
- **Tasks**:
  - [ ] Define Block entity (freezed)
  - [ ] Implement BlockStatus enum
  - [ ] Create BlockWidget UI component
  - [ ] Implement block collapse/expand
  - [ ] Add block header with command, timestamp, status
  - [ ] Style blocks by status (success/failed/running)
  - [ ] Add block action buttons (copy, pin, search)

#### 5. Block Persistence

- **Change**: `block-persistence`
- **Scope**: SQLite storage with Drift
- **Weeks**: 7-8 (parallel with blocks)
- **Tasks**:
  - [ ] Create Blocks table schema
  - [ ] Create BlockDao for CRUD operations
  - [ ] Implement block save on command complete
  - [ ] Implement block list loading
  - [ ] Add block search capability
  - [ ] Handle large output storage

#### 6. Session Tabs

- **Change**: `session-tabs`
- **Scope**: Multi-session management
- **Weeks**: 9-10
- **Tasks**:
  - [ ] Define Session entity
  - [ ] Create Sessions table schema
  - [ ] Implement TabBar widget with status indicators
  - [ ] Handle session creation/switching
  - [ ] Implement session persistence
  - [ ] Add session close with confirmation
  - [ ] Support swipe navigation between tabs

#### 7. Credential Storage

- **Change**: `credential-storage`
- **Scope**: Secure key storage, biometrics
- **Weeks**: 5-6 (parallel with SSH)
- **Tasks**:
  - [ ] Integrate flutter_secure_storage
  - [ ] Integrate local_auth for biometrics
  - [ ] Implement CredentialVault service
  - [ ] Store SSH private keys encrypted
  - [ ] Implement biometric unlock for keys
  - [ ] Add key import from file/clipboard
  - [ ] Add key generation capability

#### 8. Command Ribbon (Basic)

- **Change**: `command-ribbon-basic`
- **Scope**: History-based suggestions
- **Weeks**: 11-12
- **Tasks**:
  - [ ] Create CommandRibbon widget
  - [ ] Implement history-based suggestions
  - [ ] Add tap-to-insert functionality
  - [ ] Show recent commands when idle
  - [ ] Filter suggestions as user types
  - [ ] Add symbol quick-access row

### P1 - Should Have

#### 9. Mosh Support

- **Change**: `mosh-connectivity`
- **Scope**: FFI integration for Mosh
- **Weeks**: 9-10
- **Tasks**:
  - [ ] Set up platform channels for Mosh
  - [ ] Integrate precompiled Mosh libraries (iOS/Android)
  - [ ] Implement MoshClient wrapper
  - [ ] Handle Mosh session state persistence
  - [ ] Implement reconnection on network change
  - [ ] Add protocol selection logic (Mosh vs SSH)

#### 10. Modifier Drawer

- **Change**: `modifier-drawer`
- **Scope**: Special key access
- **Weeks**: 11-12
- **Tasks**:
  - [ ] Create ModifierDrawer widget
  - [ ] Implement swipe-up gesture to open
  - [ ] Add modifier keys (Ctrl, Alt, Esc, Tab)
  - [ ] Add arrow keys
  - [ ] Add quick combos (Ctrl+C, Ctrl+D, etc.)
  - [ ] Implement modifier state management
  - [ ] Add haptic feedback

### P2 - Nice to Have (Phase 1)

#### 11. Host Management

- **Change**: `host-management`
- **Scope**: Save/organize hosts
- **Tasks**:
  - [ ] Define Host entity
  - [ ] Create Hosts table schema
  - [ ] Implement ConnectionPicker modal
  - [ ] Add host create/edit/delete
  - [ ] Support host folders
  - [ ] Show recent connections

#### 12. Tappable Elements

- **Change**: `tappable-elements`
- **Scope**: Interactive output parsing
- **Tasks**:
  - [ ] Implement BlockParser for IP addresses
  - [ ] Implement BlockParser for file paths
  - [ ] Implement BlockParser for URLs
  - [ ] Create context menus for tappable elements
  - [ ] Add actions (copy, SSH, view file)

#### 13. Tailscale Integration

- **Change**: `tailscale-integration`
- **Scope**: Query Tailscale nodes
- **Tasks**:
  - [ ] Set up platform channels for Tailscale
  - [ ] Implement TailscaleService
  - [ ] Query available nodes
  - [ ] Show nodes in ConnectionPicker
  - [ ] Handle offline nodes

---

## Phase 2: Intelligence (Months 5-7)

### P0 - Must Have

#### 14. AI Gateway Architecture

- **Change**: `ai-gateway`
- **Scope**: Unified AI interface
- **Tasks**:
  - [ ] Define AIGateway abstract interface
  - [ ] Implement request/response normalization
  - [ ] Create provider adapter pattern
  - [ ] Implement model router logic
  - [ ] Add connectivity-aware fallback

#### 15. Local LLM Integration

- **Change**: `local-llm`
- **Scope**: On-device inference
- **Tasks**:
  - [ ] Integrate GGML/llama.cpp FFI
  - [ ] Bundle Qwen-0.5B model
  - [ ] Implement LocalLLMProvider
  - [ ] Optimize for mobile (threads, memory)
  - [ ] Implement model loading/unloading

#### 16. AI Ghostwriter

- **Change**: `ai-ghostwriter`
- **Scope**: Natural language to command
- **Tasks**:
  - [ ] Create GhostwriterModal UI
  - [ ] Implement generateCommand usecase
  - [ ] Create prompt templates
  - [ ] Show suggestions with confidence
  - [ ] Add edit/copy/execute actions
  - [ ] Show command explanation

#### 17. Error Healing

- **Change**: `error-healing`
- **Scope**: One-tap fix suggestions
- **Tasks**:
  - [ ] Implement healError usecase
  - [ ] Create HealBanner widget
  - [ ] Detect failed commands (non-zero exit)
  - [ ] Generate fix suggestions
  - [ ] Implement apply-fix action
  - [ ] Log healing success/failure

### P1 - Should Have

#### 18. SFTP Browser

- **Change**: `sftp-browser`
- **Scope**: Basic file transfer
- **Tasks**:
  - [ ] Implement SFTP client with dartssh2
  - [ ] Create FileBrowser widget
  - [ ] Implement directory listing
  - [ ] Add file download with progress
  - [ ] Add file upload with progress
  - [ ] Integrate share sheet

#### 19. Snippets

- **Change**: `snippets`
- **Scope**: Command templates
- **Tasks**:
  - [ ] Define Snippet entity with variables
  - [ ] Create Snippets table schema
  - [ ] Implement renderSnippet function
  - [ ] Create SnippetEditor widget
  - [ ] Create SnippetExecutor widget
  - [ ] Add snippet library browser

#### 20. Cloud AI Providers

- **Change**: `cloud-ai-providers`
- **Scope**: OpenAI/Anthropic/Google
- **Tasks**:
  - [ ] Implement OpenAI provider
  - [ ] Implement Anthropic provider
  - [ ] Implement Google provider
  - [ ] Add API key management
  - [ ] Implement privacy consent flow

---

## Phase 3: Visualization (Months 8-10)

### P0 - Must Have

#### 21. Dashboard Overlay

- **Change**: `dashboard-overlay`
- **Scope**: Native charts for TUI
- **Tasks**:
  - [ ] Implement TUI detection (htop, top, nvidia-smi)
  - [ ] Create process monitor widget
  - [ ] Create GPU monitor widget
  - [ ] Add real-time update streaming
  - [ ] Implement toggle to raw view

#### 22. Output Parsers

- **Change**: `output-parsers`
- **Scope**: Command output to structured data
- **Tasks**:
  - [ ] Implement df parser (disk usage)
  - [ ] Implement ps parser (processes)
  - [ ] Implement free parser (memory)
  - [ ] Implement netstat parser
  - [ ] Create visual widgets for parsed data

### P1 - Should Have

#### 23. Auto-Summarization

- **Change**: `auto-summarization`
- **Scope**: AI output summaries
- **Tasks**:
  - [ ] Implement summarizeOutput usecase
  - [ ] Create summary prompt template
  - [ ] Show summary in block header
  - [ ] Add tap-to-expand full output
  - [ ] Add enable/disable setting

#### 24. Advanced Command Ribbon

- **Change**: `command-ribbon-advanced`
- **Scope**: Subcommand completion, knowledge base
- **Tasks**:
  - [ ] Implement CommandKnowledge base
  - [ ] Add subcommand suggestions
  - [ ] Add nested subcommand support
  - [ ] Implement argument suggestions
  - [ ] Add snippet suggestions in ribbon

### P2 - Nice to Have

#### 25. Voice Input

- **Change**: `voice-input`
- **Scope**: Speech-to-command
- **Tasks**:
  - [ ] Integrate speech_to_text
  - [ ] Add microphone button to ribbon
  - [ ] Implement voice-to-text flow
  - [ ] Route through AI Ghostwriter
  - [ ] Handle continuous dictation

---

## Phase 4: Polish (Months 11-12)

### P0 - Must Have

#### 26. Performance Optimization

- **Change**: `performance-optimization`
- **Scope**: Memory, battery, startup
- **Tasks**:
  - [ ] Profile memory usage
  - [ ] Optimize block list rendering
  - [ ] Implement lazy loading
  - [ ] Reduce startup time
  - [ ] Optimize AI model loading

#### 27. Accessibility

- **Change**: `accessibility`
- **Scope**: VoiceOver/TalkBack compliance
- **Tasks**:
  - [ ] Audit all widgets for semantics
  - [ ] Add accessibility labels
  - [ ] Test with VoiceOver (iOS)
  - [ ] Test with TalkBack (Android)
  - [ ] Add high contrast mode

#### 28. Theme System

- **Change**: `theme-system`
- **Scope**: Dark/light themes
- **Tasks**:
  - [ ] Define BentoColors for dark theme
  - [ ] Define BentoColors for light theme
  - [ ] Implement theme switching
  - [ ] Persist theme preference
  - [ ] Add terminal color schemes

### P1 - Should Have

#### 29. Documentation & Community

- **Change**: `documentation`
- **Scope**: User guide, contributing
- **Tasks**:
  - [ ] Write README.md
  - [ ] Write CONTRIBUTING.md
  - [ ] Create issue templates
  - [ ] Write architecture docs
  - [ ] Create user guide

---

## Change Status Summary

| Change                   | Phase | Priority | Status  |
| ------------------------ | ----- | -------- | ------- |
| scaffold-flutter-project | 1     | P0       | Pending |
| terminal-emulation       | 1     | P0       | Pending |
| ssh-connectivity         | 1     | P0       | Pending |
| semantic-blocks          | 1     | P0       | Pending |
| block-persistence        | 1     | P0       | Pending |
| session-tabs             | 1     | P0       | Pending |
| credential-storage       | 1     | P0       | Pending |
| command-ribbon-basic     | 1     | P0       | Pending |
| mosh-connectivity        | 1     | P1       | Pending |
| modifier-drawer          | 1     | P1       | Pending |
| host-management          | 1     | P2       | Pending |
| tappable-elements        | 1     | P2       | Pending |
| tailscale-integration    | 1     | P2       | Pending |
| ai-gateway               | 2     | P0       | Pending |
| local-llm                | 2     | P0       | Pending |
| ai-ghostwriter           | 2     | P0       | Pending |
| error-healing            | 2     | P0       | Pending |
| sftp-browser             | 2     | P1       | Pending |
| snippets                 | 2     | P1       | Pending |
| cloud-ai-providers       | 2     | P1       | Pending |
| dashboard-overlay        | 3     | P0       | Pending |
| output-parsers           | 3     | P0       | Pending |
| auto-summarization       | 3     | P1       | Pending |
| command-ribbon-advanced  | 3     | P1       | Pending |
| voice-input              | 3     | P2       | Pending |
| performance-optimization | 4     | P0       | Pending |
| accessibility            | 4     | P0       | Pending |
| theme-system             | 4     | P0       | Pending |
| documentation            | 4     | P1       | Pending |

---

## Dependencies

```
scaffold-flutter-project
├── terminal-emulation
│   └── semantic-blocks
│       └── block-persistence
│       └── tappable-elements
├── ssh-connectivity
│   └── credential-storage
│   └── mosh-connectivity
│   └── sftp-browser
├── session-tabs
│   └── host-management
│       └── tailscale-integration
├── command-ribbon-basic
│   └── modifier-drawer
│   └── command-ribbon-advanced
│       └── snippets
├── ai-gateway
│   └── local-llm
│   └── cloud-ai-providers
│   └── ai-ghostwriter
│   └── error-healing
│   └── auto-summarization
└── dashboard-overlay
    └── output-parsers
```

---

_Last Updated: 2026-02-04_
