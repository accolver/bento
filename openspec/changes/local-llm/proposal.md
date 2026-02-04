# Proposal: Local LLM

## Why

Privacy-first AI requires on-device inference. Bundling a small but capable LLM
(Qwen-0.5B or similar) enables AI features without network dependency or data
leaving the device. This is the default for all AI operations unless the user
explicitly opts into cloud AI.

## What Changes

- Integrate GGML/llama.cpp via FFI
- Bundle optimized Qwen-0.5B GGUF model (~350MB)
- Implement LocalLLMProvider with load/unload
- Optimize for mobile (thread count, memory)
- Implement inference with timeout handling
- Add model download/update capability

## Capabilities

### New Capabilities

- `local-llm-provider`: On-device inference
- `model-management`: Load, unload, update models
- `mobile-optimization`: Tuned for mobile hardware

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have**
