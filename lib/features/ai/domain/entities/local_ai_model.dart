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

  /// Full download URL from Ollama's registry.
  ///
  /// Uses Ollama's Docker-compatible registry which provides reliable
  /// CDN-backed (Cloudflare R2) access to GGUF model blobs.
  String get downloadUrl =>
      'https://registry.ollama.ai/v2/library/$ollamaLibrary/blobs/$ollamaBlobDigest';
}

/// Available models for local AI inference.
///
/// These are curated GGUF models from Ollama's registry that work well
/// with flutter_llama and are appropriate for mobile/desktop devices.
const List<LocalAiModel> availableLocalModels = [
  // TinyLlama - smallest, fastest
  LocalAiModel(
    id: 'tinyllama',
    name: 'TinyLlama',
    description: 'Fastest option, works on any device',
    ollamaLibrary: 'tinyllama',
    ollamaTag: 'latest',
    ollamaBlobDigest:
        'sha256:2af3b81862c6be03c769683af18efdadb2c33f60ff32ab6f83e42c043d6c7816',
    sizeBytes: 637699456, // ~608 MB
    qualityRating: 3,
  ),

  // Phi-3 Mini - best balance (RECOMMENDED)
  LocalAiModel(
    id: 'phi3-mini',
    name: 'Phi-3 Mini',
    description: 'Best balance of speed and quality',
    ollamaLibrary: 'phi3',
    ollamaTag: 'mini',
    ollamaBlobDigest:
        'sha256:633fc5be925f9a484b61d6f9b9a78021eeb462100bd557309f01ba84cac26adf',
    sizeBytes: 2176177120, // ~2.0 GB
    qualityRating: 5,
    isRecommended: true,
  ),

  // Gemma 2 2B - good for multiple languages
  LocalAiModel(
    id: 'gemma2-2b',
    name: 'Gemma 2 2B',
    description: 'Good for multiple languages',
    ollamaLibrary: 'gemma2',
    ollamaTag: '2b',
    ollamaBlobDigest:
        'sha256:7462734796d67c40ecec2ca98eddf970e171dbb6b370e43fd633ee75b69abe1b',
    sizeBytes: 1629509152, // ~1.5 GB
    qualityRating: 4,
  ),

  // Qwen2 0.5B - ultra-compact
  LocalAiModel(
    id: 'qwen2-0.5b',
    name: 'Qwen2 0.5B',
    description: 'Ultra-compact, very fast',
    ollamaLibrary: 'qwen2',
    ollamaTag: '0.5b',
    ollamaBlobDigest:
        'sha256:8de95da68dc485c0889c205384c24642f83ca18d089559c977ffc6a3972a71a8',
    sizeBytes: 352151968, // ~336 MB
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
