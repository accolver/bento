// @telos L1:function:lib/features/ai/domain/entities:local_ai_model

import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_ai_model.freezed.dart';

/// A local AI model that can be downloaded and run on-device.
///
/// Models are GGUF format files that work with flutter_llama.
@freezed
class LocalAiModel with _$LocalAiModel {
  const factory LocalAiModel({
    /// Unique identifier for this model.
    required String id,

    /// Display name for the model.
    required String name,

    /// Human-readable description of the model's strengths.
    required String description,

    /// HuggingFace repository containing the model.
    required String huggingFaceRepo,

    /// Filename within the repository.
    required String huggingFaceFile,

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

  /// Full download URL from HuggingFace.
  String get downloadUrl =>
      'https://huggingface.co/$huggingFaceRepo/resolve/main/$huggingFaceFile';
}

/// Available models for local AI inference.
///
/// These are curated GGUF models that work well with flutter_llama
/// and are appropriate for mobile/desktop devices.
const List<LocalAiModel> availableLocalModels = [
  // TinyLlama - smallest, fastest
  LocalAiModel(
    id: 'tinyllama',
    name: 'TinyLlama',
    description: 'Fastest option, works on any device',
    huggingFaceRepo: 'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
    huggingFaceFile: 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf',
    sizeBytes: 669 * 1024 * 1024, // ~669 MB
    qualityRating: 3,
  ),

  // Phi-3 Mini - best balance (RECOMMENDED)
  LocalAiModel(
    id: 'phi3-mini',
    name: 'Phi-3 Mini',
    description: 'Best balance of speed and quality',
    huggingFaceRepo: 'microsoft/Phi-3-mini-4k-instruct-gguf',
    huggingFaceFile: 'Phi-3-mini-4k-instruct-q4.gguf',
    sizeBytes: 2 * 1024 * 1024 * 1024, // ~2 GB
    qualityRating: 5,
    isRecommended: true,
  ),

  // Gemma 2B - good for multiple languages
  LocalAiModel(
    id: 'gemma-2b',
    name: 'Gemma 2B',
    description: 'Good for multiple languages',
    huggingFaceRepo: 'google/gemma-2b-it-GGUF',
    huggingFaceFile: 'gemma-2b-it-q4_k_m.gguf',
    sizeBytes: 1503238553, // ~1.4 GB
    qualityRating: 4,
  ),

  // Qwen2 0.5B - ultra-compact
  LocalAiModel(
    id: 'qwen2-0.5b',
    name: 'Qwen2 0.5B',
    description: 'Ultra-compact, very fast',
    huggingFaceRepo: 'Qwen/Qwen2-0.5B-Instruct-GGUF',
    huggingFaceFile: 'qwen2-0_5b-instruct-q4_k_m.gguf',
    sizeBytes: 400 * 1024 * 1024, // ~400 MB
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
