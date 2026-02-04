# Proposal: AI Gateway

## Why

Bento's AI features (Ghostwriter, error healing, summarization) need a unified
interface that abstracts over multiple providers (local LLM, OpenAI, Anthropic,
Google). The AI Gateway provides request/response normalization, intelligent
routing based on task complexity and connectivity, and privacy-respecting
fallback behavior.

## What Changes

- Define AIGateway abstract interface with generateCommand, healError,
  summarizeOutput
- Implement request/response normalization layer
- Create provider adapter pattern for pluggable providers
- Implement AIModelRouter with complexity-based selection
- Add connectivity-aware fallback (cloud unavailable → local)
- Create prompt template system

## Capabilities

### New Capabilities

- `ai-gateway`: Unified AI interface
- `ai-routing`: Intelligent provider selection
- `ai-fallback`: Connectivity-aware fallback
- `prompt-templates`: Reusable prompt system

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have**
