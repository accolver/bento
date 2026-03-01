// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:remote_detect_step

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../session/domain/entities/session_status.dart';
import '../../../../session/presentation/providers/session_list_controller.dart';
import '../../../domain/entities/ollama_model.dart';
import '../../../domain/entities/remote_ai_config.dart';
import '../../../domain/entities/remote_ai_detection.dart';
import '../../../domain/entities/remote_ai_provider.dart';
import '../../providers/remote_ai_providers.dart';

/// Represents the user's selected provider from the detection results.
class RemoteProviderSelection {
  const RemoteProviderSelection.cloud({
    required this.cloudProvider,
    required this.envVarName,
  })  : backendType = RemoteBackendType.cloudProxy,
        ollamaModel = null;

  const RemoteProviderSelection.ollama({
    required this.ollamaModel,
  })  : backendType = RemoteBackendType.ollama,
        cloudProvider = null,
        envVarName = null;

  final RemoteBackendType backendType;
  final RemoteCloudProvider? cloudProvider;
  final String? envVarName;
  final String? ollamaModel;
}

/// Step for configuring remote AI detection (Ollama + cloud providers).
///
/// Shows live detection results when SSH is connected, or a description
/// of how detection works when no SSH session is active. When providers are
/// detected, shows them as selectable rows so the user can choose which
/// provider to use.
class RemoteDetectStep extends ConsumerStatefulWidget {
  const RemoteDetectStep({
    super.key,
    required this.onComplete,
    this.onAutoDetectChanged,
    this.onProviderSelected,
  });

  final VoidCallback onComplete;

  /// Called when the auto-detect toggle changes.
  final ValueChanged<bool>? onAutoDetectChanged;

  /// Called when the user selects a provider. Passes the selection info
  /// so the wizard can save the correct config.
  final ValueChanged<RemoteProviderSelection>? onProviderSelected;

  @override
  ConsumerState<RemoteDetectStep> createState() => _RemoteDetectStepState();
}

class _RemoteDetectStepState extends ConsumerState<RemoteDetectStep> {
  bool _autoDetect = true;

  /// The currently selected provider. Null means "auto" (best ranked).
  /// This is a tag that identifies the selection:
  /// - "cloud:<provider_name>" for cloud providers
  /// - "ollama:<model_name>" for Ollama models
  String? _selectedTag;

  /// Whether we've auto-selected the default provider for this detection.
  /// Used to avoid re-selecting on every rebuild.
  String? _autoSelectedForHostId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check for active SSH connection
    final sessionState = ref.watch(sessionListControllerProvider);
    final connectedSession = sessionState.sessions
        .where((s) => s.status == SessionStatus.connected)
        .firstOrNull;
    final hasSSHConnection = connectedSession != null;

    // Get detection result if SSH connected
    RemoteAiDetectionResult? detectionResult;
    bool isDetecting = false;
    String? hostId;
    if (hasSSHConnection) {
      hostId =
          '${connectedSession.connectionConfig.host}:${connectedSession.connectionConfig.port}';
      final detectionAsync = ref.watch(remoteAiDetectionStateProvider(hostId));
      detectionResult = detectionAsync.valueOrNull;
      isDetecting = detectionAsync.isLoading;
    }

    // Auto-select the best provider when detection results arrive
    if (detectionResult != null &&
        detectionResult.hasAnyProvider &&
        _autoSelectedForHostId != hostId) {
      _autoSelectedForHostId = hostId;
      // Check if user has a saved config for this host
      final savedConfig =
          hostId != null ? ref.read(remoteAiConfigStateProvider(hostId)) : null;
      if (savedConfig != null) {
        _selectedTag = _tagFromConfig(savedConfig);
      } else {
        _selectedTag = _bestProviderTag(detectionResult);
      }
      // Notify parent of initial selection
      _notifySelection();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Remote AI Detection',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use AI on servers you connect to via SSH',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Live detection results (when SSH connected)
          if (hasSSHConnection) ...[
            _buildDetectionResults(
              theme,
              connectedSession.displayName,
              detectionResult,
              isDetecting,
            ),
            const SizedBox(height: 16),
          ],

          // Auto-detect toggle
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-detect AI providers',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Check for Ollama and cloud API keys on SSH connect',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoDetect,
                    onChanged: (value) {
                      setState(() {
                        _autoDetect = value;
                      });
                      widget.onAutoDetectChanged?.call(value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Show "What Bento detects" when no SSH, or privacy info when SSH connected
          if (!hasSSHConnection) ...[
            _buildWhatBentoDetects(theme),
            const SizedBox(height: 16),
          ],

          // Privacy info
          _buildPrivacyInfo(theme),
          const SizedBox(height: 16),

          // How it works (only when not connected)
          if (!hasSSHConnection) ...[
            _buildHowItWorks(theme),
          ],

          const Spacer(),

          // Done button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onComplete,
              child: Text(
                detectionResult?.hasAnyProvider == true
                    ? 'Enable Remote AI'
                    : 'Done',
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ===========================================================================
  // Selection helpers
  // ===========================================================================

  /// Generate a tag string for a cloud provider.
  /// Format: "cloud:<provider_name>:<env_var_name>"
  static String _cloudTag(DetectedCloudProvider p) =>
      'cloud:${p.provider.name}:${p.envVarName}';

  /// Generate a tag string for an Ollama model.
  static String _ollamaTag(OllamaModel m) => 'ollama:${m.name}';

  /// Derive a tag from a saved config.
  static String? _tagFromConfig(RemoteAiConfig config) {
    switch (config.backendType) {
      case RemoteBackendType.cloudProxy:
        return config.cloudProvider != null && config.envVarName != null
            ? 'cloud:${config.cloudProvider!.name}:${config.envVarName}'
            : null;
      case RemoteBackendType.ollama:
        return config.ollamaModel != null
            ? 'ollama:${config.ollamaModel}'
            : null;
      case RemoteBackendType.claudeCode:
        return 'claude-code';
    }
  }

  /// Pick the best provider tag from detection results.
  ///
  /// Priority: best cloud provider (by quality rank), then first Ollama model.
  static String _bestProviderTag(RemoteAiDetectionResult result) {
    if (result.hasCloudProviders) {
      return _cloudTag(result.bestCloudProvider!);
    }
    if (result.hasOllama) {
      return _ollamaTag(result.ollamaModels.first);
    }
    return '';
  }

  /// Notify the parent of the current selection.
  void _notifySelection() {
    if (_selectedTag == null) return;
    final selection = _selectionFromTag(_selectedTag!);
    if (selection != null) {
      widget.onProviderSelected?.call(selection);
    }
  }

  /// Convert a tag string back to a [RemoteProviderSelection].
  static RemoteProviderSelection? _selectionFromTag(String tag) {
    if (tag.startsWith('cloud:')) {
      // Format: "cloud:<provider_name>:<env_var_name>"
      final parts = tag.split(':');
      if (parts.length < 3) return null;
      final providerName = parts[1];
      final envVarName = parts.sublist(2).join(':');
      final provider = RemoteCloudProvider.values.firstWhere(
        (p) => p.name == providerName,
        orElse: () => RemoteCloudProvider.anthropic,
      );
      return RemoteProviderSelection.cloud(
        cloudProvider: provider,
        envVarName: envVarName,
      );
    }
    if (tag.startsWith('ollama:')) {
      final modelName = tag.substring(7);
      return RemoteProviderSelection.ollama(ollamaModel: modelName);
    }
    return null;
  }

  void _onProviderTapped(String tag) {
    setState(() {
      _selectedTag = tag;
    });
    _notifySelection();
  }

  // ===========================================================================
  // UI builders
  // ===========================================================================

  /// Builds the live detection results panel.
  Widget _buildDetectionResults(
    ThemeData theme,
    String hostName,
    RemoteAiDetectionResult? result,
    bool isDetecting,
  ) {
    if (isDetecting) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Detecting AI providers on $hostName...',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (result == null || !result.hasAnyProvider) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No AI providers found on $hostName',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Found on $hostName',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to choose your preferred provider',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Ollama models
          if (result.hasOllama) ...[
            for (final model in result.ollamaModels)
              _ProviderRow(
                tag: _ollamaTag(model),
                isSelected: _selectedTag == _ollamaTag(model),
                onTap: () => _onProviderTapped(_ollamaTag(model)),
                icon: Icons.memory,
                name: model.displayName,
                detail: model.tag,
                badge: 'Local',
                badgeColor: theme.colorScheme.primaryContainer,
                badgeTextColor: theme.colorScheme.onPrimaryContainer,
              ),
          ],

          // Cloud providers
          if (result.hasCloudProviders) ...[
            if (result.hasOllama) const SizedBox(height: 2),
            for (final provider in result.cloudProviders)
              _ProviderRow(
                tag: _cloudTag(provider),
                isSelected: _selectedTag == _cloudTag(provider),
                onTap: () => _onProviderTapped(_cloudTag(provider)),
                icon: Icons.cloud_outlined,
                name: provider.displayName,
                badge: provider == result.bestCloudProvider ? 'Best' : null,
                badgeColor: theme.colorScheme.secondaryContainer,
                badgeTextColor: theme.colorScheme.onSecondaryContainer,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatBentoDetects(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Bento detects',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _DetectionItem(
            icon: Icons.memory,
            title: 'Ollama',
            description: 'Local models running on the server',
          ),
          const SizedBox(height: 6),
          _DetectionItem(
            icon: Icons.cloud_outlined,
            title: 'Cloud API keys',
            description:
                'Anthropic, OpenAI, Groq, Google, and 7 more providers',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy First',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bento never reads your API key values. '
            'It only checks if specific environment variables exist. '
            'API calls are executed on the remote host using shell '
            'variable expansion.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const _HowItWorksItem(
            number: '1',
            text: 'Connect to a server via SSH',
          ),
          const SizedBox(height: 4),
          const _HowItWorksItem(
            number: '2',
            text: 'Bento silently checks for AI providers',
          ),
          const SizedBox(height: 4),
          const _HowItWorksItem(
            number: '3',
            text: 'A notification shows what was found',
          ),
          const SizedBox(height: 4),
          const _HowItWorksItem(
            number: '4',
            text: 'Tap to choose which provider to use',
          ),
        ],
      ),
    );
  }
}

/// A single selectable provider row in the detection results panel.
class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.tag,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.name,
    this.detail,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  final String tag;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String name;
  final String? detail;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Radio indicator
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              // Provider icon
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              // Provider name
              Expanded(
                child: Row(
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (detail != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        detail!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Badge (Local, Best, etc.)
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionItem extends StatelessWidget {
  const _DetectionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  const _HowItWorksItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
