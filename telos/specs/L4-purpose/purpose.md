<!-- telos-metadata
id: L4:purpose
level: 4
title: Bento
children:
  - L3:experience:incident-response
  - L3:experience:ai-command-assistance
  - L3:experience:error-recovery
  - L3:experience:session-management
  - L3:experience:mobile-vibe-coding
-->

# L4: Purpose

## Why This Project Exists

Transform the mobile terminal experience from chaotic scrolling text into
organized, navigable "Semantic Blocks" - enabling developers to be genuinely
productive on mobile devices through resilient Mosh connectivity, context-aware
input predictions, and AI-powered command assistance.

## Beneficiaries

- **On-call engineers** who need to diagnose and resolve incidents from mobile
- **Homelab enthusiasts** managing personal servers and infrastructure
- **Cloud developers** deploying and monitoring applications remotely

## Success Metrics

| Metric                   | Target                           | Current |
| ------------------------ | -------------------------------- | ------- |
| Keystroke reduction      | 50% vs raw typing                | -       |
| Session recovery rate    | 99.9% on network change          | -       |
| AI suggestion acceptance | > 60%                            | -       |
| Frame rate               | 60fps on mid-range 2023+ devices | -       |
| App launch to terminal   | < 2 seconds                      | -       |
| Daily active users       | 10K by month 6                   | -       |
| Error healing success    | > 70%                            | -       |
| Crash-free sessions      | > 99.5%                          | -       |

## Strategic Constraints

- **Mobile-only for v1.0**: No desktop application
- **No IDE features**: No code editing, syntax highlighting, or project
  management
- **No team collaboration**: No shared sessions in v1.0
- **Open source**: MIT license with sustainability via GitHub Sponsors/Open
  Collective
- **Privacy-first**: Local AI by default, explicit consent required for cloud AI

## Technology Stack

- **Framework**: Flutter 3.19+ with Impeller rendering engine
- **State Management**: Riverpod 3.x (async-first)
- **Terminal**: xterm (GPU-accelerated, 60fps mobile-optimized)
- **Connectivity**: dartssh2 (SSH/SFTP), Mosh (via FFI/platform channels)
- **Persistence**: Drift (SQLite), Hive (fast KV cache), flutter_secure_storage
- **AI**: Local LLM (GGML/GGUF) + optional cloud providers (OpenAI, Anthropic,
  Google)
- **Navigation**: go_router with deep linking

## Initialization

- **Date**: 2025-02-04
- **Method**: telos init
- **PRD Version**: 1.0
