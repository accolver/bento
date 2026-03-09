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
/// We offer Qwen3.5-0.8B variants -- the smallest model in the Qwen 3.5
/// Small Model Series. Built on improved architecture with scaled RL,
/// these are designed for edge devices while providing meaningfully
/// better intelligence than prior sub-1B models.
///
/// Note: We use unsloth's public GGUF quantizations from HuggingFace.
const List<LocalAiModel> availableLocalModels = [
  // Qwen3.5 0.8B Q4_0 - compact quantization, ~507 MB
  // Good balance of size and speed for mobile inference
  LocalAiModel(
    id: 'qwen3.5-0.8b-q4',
    name: 'Qwen3.5 Tiny',
    description: 'Compact download (507 MB), fast inference',
    ollamaLibrary: 'qwen3.5',
    ollamaTag: '0.8b-q4_0',
    ollamaBlobDigest: 'hf:unsloth/Qwen3.5-0.8B-GGUF/Qwen3.5-0.8B-Q4_0.gguf',
    sizeBytes: 507000000, // ~507 MB
    qualityRating: 3,
    isRecommended: true,
  ),

  // Qwen3.5 0.8B Q8_0 - higher precision, ~812 MB
  // Better output quality with full 8-bit quantization
  LocalAiModel(
    id: 'qwen3.5-0.8b-q8',
    name: 'Qwen3.5 Quality',
    description: 'Higher quality (812 MB), best local output',
    ollamaLibrary: 'qwen3.5',
    ollamaTag: '0.8b-q8_0',
    ollamaBlobDigest: 'hf:unsloth/Qwen3.5-0.8B-GGUF/Qwen3.5-0.8B-Q8_0.gguf',
    sizeBytes: 812000000, // ~812 MB
    qualityRating: 4,
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
