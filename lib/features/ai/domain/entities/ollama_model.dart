// @telos L1:function:lib/features/ai/domain/entities:ollama_model

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ollama_model.freezed.dart';
part 'ollama_model.g.dart';

/// Metadata for an Ollama model installed on a remote server.
///
/// Parsed from the `/api/tags` endpoint response. Contains information
/// about the model's name, size, and configuration.
@freezed
class OllamaModel with _$OllamaModel {
  const factory OllamaModel({
    /// Model identifier (e.g., "llama3:8b", "codellama:7b").
    required String name,

    /// SHA256 digest of the model, used to identify specific versions.
    String? digest,

    /// Size of the model on disk in bytes.
    /// Ollama API returns this as `size` in JSON.
    @Default(0) @JsonKey(name: 'size') int sizeBytes,

    /// When the model was last modified.
    /// Ollama API returns this as `modified_at` in JSON.
    @JsonKey(name: 'modified_at') required DateTime modifiedAt,

    /// Additional model details (family, parameter size, quantization, etc.).
    Map<String, dynamic>? details,
  }) = _OllamaModel;

  const OllamaModel._();

  /// Pretty name for UI display.
  ///
  /// Extracts the base model name and capitalizes it.
  /// Examples:
  /// - "llama3:8b" → "Llama3"
  /// - "codellama:7b" → "Codellama"
  /// - "mistral:latest" → "Mistral"
  String get displayName {
    final base = name.split(':').first;
    if (base.isEmpty) return name;
    return base[0].toUpperCase() + base.substring(1);
  }

  /// Size formatted for human-readable display.
  ///
  /// Examples:
  /// - 4661224676 → "4.3 GB"
  /// - 3825820160 → "3.6 GB"
  String get formattedSize => '${(sizeBytes / 1e9).toStringAsFixed(1)} GB';

  /// Tag portion of the name (e.g., "8b" from "llama3:8b").
  String? get tag {
    final parts = name.split(':');
    return parts.length > 1 ? parts.sublist(1).join(':') : null;
  }

  /// Parameter size if available from details.
  String? get parameterSize => details?['parameter_size'] as String?;

  /// Quantization level if available from details.
  String? get quantizationLevel => details?['quantization_level'] as String?;

  /// Creates an [OllamaModel] from the Ollama `/api/tags` JSON format.
  factory OllamaModel.fromJson(Map<String, dynamic> json) =>
      _$OllamaModelFromJson(json);
}
