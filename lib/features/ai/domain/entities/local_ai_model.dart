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
/// We only offer SmolLM2-135M variants as they are the smallest models
/// that can reliably load on memory-constrained mobile devices.
///
/// Note: We use bartowski's public HuggingFace repo (official repo requires auth).
const List<LocalAiModel> availableLocalModels = [
  // SmolLM2 135M Q4 - smallest possible, ~90 MB
  // Aggressive quantization, fastest to download and load
  LocalAiModel(
    id: 'smollm2-135m-q4',
    name: 'SmolLM2 Tiny',
    description: 'Smallest download (90 MB), fastest to load',
    ollamaLibrary: 'smollm2',
    ollamaTag: '135m-instruct-q4_0',
    ollamaBlobDigest:
        'hf:bartowski/SmolLM2-135M-Instruct-GGUF/SmolLM2-135M-Instruct-Q4_0.gguf',
    sizeBytes: 90000000, // ~90 MB
    qualityRating: 2,
    isRecommended: true,
  ),

  // SmolLM2 135M Q8 - better quality, still small
  // Higher precision quantization for better output
  LocalAiModel(
    id: 'smollm2-135m-q8',
    name: 'SmolLM2 Quality',
    description: 'Better quality (140 MB), slightly slower',
    ollamaLibrary: 'smollm2',
    ollamaTag: '135m-instruct-q8_0',
    ollamaBlobDigest:
        'hf:bartowski/SmolLM2-135M-Instruct-GGUF/SmolLM2-135M-Instruct-Q8_0.gguf',
    sizeBytes: 140000000, // ~140 MB
    qualityRating: 3,
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
