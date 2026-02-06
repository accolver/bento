# Proposal: Local LLM

## Why

Privacy-first AI requires on-device inference. Running models locally ensures:

- **Complete Privacy**: Commands/context never leave the device
- **Offline Capability**: Works without network connectivity
- **Zero Latency**: No round-trip to cloud servers
- **No API Costs**: Unlimited usage after initial model download

This is the recommended option for users who prioritize privacy over model
capability.

## What Changes

- Integrate `flutter_llama` package (v1.1.2) for on-device inference
- Support GPU acceleration on iOS (Metal) and Android (Vulkan)
- Implement model download from HuggingFace with progress tracking
- Support multiple model tiers (Tiny/Small/Medium)
- Implement LocalAiService conforming to AiService interface
- Add memory management and model lifecycle handling

## Technical Details

### Package Choice: flutter_llama

**Why flutter_llama over alternatives:**

- Active maintenance (v1.1.2 released Oct 2025)
- GPU acceleration via llama.cpp backend
- Supports GGUF quantized models
- Simple API: `loadModel()`, `generateCompletion()`
- Smaller app size impact than bundled solutions

**Rejected alternatives:**

- `fllama`: Unmaintained (last update Sept 2024)
- Custom FFI: Too much overhead for our needs
- Bundled models: Would bloat app to 500MB+

### Recommended Models

| Model             | Size  | RAM    | Use Case              |
| ----------------- | ----- | ------ | --------------------- |
| TinyLlama-1.1B-Q4 | 88MB  | ~600MB | Fast, simple commands |
| Phi-3-mini-Q4     | 800MB | ~2GB   | Better reasoning      |
| Llama-3.2-1B-Q4   | 600MB | ~1.5GB | Good balance          |

Default: TinyLlama (smallest, works on all devices)

### Model Download Strategy

1. **On-demand download**: No models bundled with app
2. **HuggingFace CDN**: Direct download from `huggingface.co/TheBloke/...`
3. **Resume support**: Continue interrupted downloads
4. **Storage location**: App Documents directory (user-manageable)

## Capabilities

### New Capabilities

- `local-inference`: On-device LLM execution via flutter_llama
- `model-download`: Download models from HuggingFace with progress
- `model-management`: Switch between downloaded models
- `gpu-acceleration`: Metal (iOS) and Vulkan (Android) support

### Modified Capabilities

- `ai-service`: LocalAiService implements AiService interface

## Dependencies

- Requires: `ai-gateway` (for AiService interface)
- Required by: `ai-setup-flow` (configuration wizard)

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P0 - Must Have**

Local inference is the privacy-first default; cloud/remote are opt-in
alternatives.
