// @telos L1:function:lib/features/ai/domain/entities:local_ai_model

import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_ai_model.freezed.dart';

/// A local AI model that can be downloaded and run on-device.
///
/// Models are GGUF format files that work with flutter_llama.
/// Downloads are sourced from Ollama's registry which provides reliable
/// CDN-backed access to GGUF models.
@freezed
class LocalAiModel with _$LocalAiModel {
  const factory LocalAiModel({
    /// Unique identifier for this model.
    required String id,

    /// Display name for the model.
    required String name,

    /// Human-readable description of the model's strengths.
    required String description,

    /// Ollama library name (e.g., "tinyllama", "phi3", "qwen2").
    required String ollamaLibrary,

    /// Ollama model tag (e.g., "latest", "mini", "0.5b").
    required String ollamaTag,

    /// SHA256 digest of the model blob in Ollama registry.
    required String ollamaBlobDigest,

    /// Size in bytes.
    required int sizeBytes,

    /// Quality rating (1-5).
    required int qualityRating,

    /// Whether this is the recommended model.
    @Default(false) bool isRecommended,
  }) = _LocalAiModel;

  const LocalAiModel._();

  /// Human-readable size (e.g., "2.0 GB").
  String get formattedSize {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
  }

  /// Full download URL for the model.
  ///
  /// Supports two formats:
  /// - HuggingFace: `hf:org/repo/filename.gguf`
  /// - Ollama: `sha256:...` (legacy, may have compatibility issues)
  String get downloadUrl {
    if (ollamaBlobDigest.startsWith('hf:')) {
      // HuggingFace format: hf:org/repo/filename.gguf
      final path = ollamaBlobDigest.substring(3); // Remove 'hf:' prefix
      final parts = path.split('/');
      if (parts.length >= 3) {
        final org = parts[0];
        final repo = parts[1];
        final filename = parts.sublist(2).join('/');
        return 'https://huggingface.co/$org/$repo/resolve/main/$filename';
      }
    }
    // Ollama registry fallback
    return 'https://registry.ollama.ai/v2/library/$ollamaLibrary/blobs/$ollamaBlobDigest';
  }
}

/// Available models for local AI inference.
///
/// These are curated GGUF models from HuggingFace that work well
/// with llama_flutter_android and are appropriate for mobile devices.
///
/// Note: We use HuggingFace direct downloads because Ollama registry blobs
/// may have compatibility issues with some llama.cpp versions.
const List<LocalAiModel> availableLocalModels = [
  // Qwen2.5 0.5B - small, fast, good quality
  LocalAiModel(
    id: 'qwen2.5-0.5b',
    name: 'Qwen2.5 0.5B',
    description: 'Small and fast, good for commands',
    ollamaLibrary: 'qwen2.5',
    ollamaTag: '0.5b-instruct-q4_k_m',
    // Direct HuggingFace download - more compatible
    ollamaBlobDigest:
        'hf:Qwen/Qwen2.5-0.5B-Instruct-GGUF/qwen2.5-0.5b-instruct-q4_k_m.gguf',
    sizeBytes: 397000000, // ~397 MB
    qualityRating: 3,
    isRecommended: true,
  ),

  // SmolLM2 135M - ultra tiny
  LocalAiModel(
    id: 'smollm2-135m',
    name: 'SmolLM2 135M',
    description: 'Ultra-compact, very fast',
    ollamaLibrary: 'smollm2',
    ollamaTag: '135m-instruct-q8_0',
    ollamaBlobDigest:
        'hf:HuggingFaceTB/SmolLM2-135M-Instruct-GGUF/smollm2-135m-instruct-q8_0.gguf',
    sizeBytes: 145000000, // ~145 MB
    qualityRating: 2,
  ),

  // TinyLlama 1.1B - classic small model
  LocalAiModel(
    id: 'tinyllama-1.1b',
    name: 'TinyLlama 1.1B',
    description: 'Proven small model, good balance',
    ollamaLibrary: 'tinyllama',
    ollamaTag: '1.1b-chat-q4_k_m',
    ollamaBlobDigest:
        'hf:TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    sizeBytes: 669000000, // ~669 MB
    qualityRating: 3,
  ),

  // Phi-3.5 Mini - high quality
  LocalAiModel(
    id: 'phi3.5-mini',
    name: 'Phi-3.5 Mini',
    description: 'Best quality, needs more RAM',
    ollamaLibrary: 'phi3.5',
    ollamaTag: 'mini-instruct-q4_k_m',
    ollamaBlobDigest:
        'hf:bartowski/Phi-3.5-mini-instruct-GGUF/Phi-3.5-mini-instruct-Q4_K_M.gguf',
    sizeBytes: 2390000000, // ~2.4 GB
    qualityRating: 5,
  ),
];

/// Get a local model by its ID.
LocalAiModel? getLocalModelById(String id) {
  final matches = availableLocalModels.where((m) => m.id == id);
  return matches.isEmpty ? null : matches.first;
}

/// Get the recommended model.
LocalAiModel get recommendedLocalModel =>
    availableLocalModels.firstWhere((m) => m.isRecommended);
