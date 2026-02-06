// @telos L1:function:lib/features/ai/domain/entities:ai_privacy_mode

/// Indicates whether AI processing is happening locally or in the cloud.
///
/// This is displayed to users so they understand where their data is being
/// processed.
enum AiPrivacyMode {
  /// AI processing happens entirely on-device using local LLM.
  /// No data is sent to external servers.
  local,

  /// AI processing uses cloud APIs.
  /// Data is sent to external servers for processing.
  cloud,
}
