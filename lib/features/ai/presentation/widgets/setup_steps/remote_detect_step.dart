// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:remote_detect_step

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../session/domain/entities/session_status.dart';
import '../../../../session/presentation/providers/session_list_controller.dart';
import '../../../domain/entities/remote_ai_detection.dart';
import '../../providers/remote_ai_providers.dart';

/// Step for configuring remote AI detection (Ollama + cloud providers).
///
/// Shows live detection results when SSH is connected, or a description
/// of how detection works when no SSH session is active.
class RemoteDetectStep extends ConsumerStatefulWidget {
  const RemoteDetectStep({
    super.key,
    required this.onComplete,
    this.onAutoDetectChanged,
  });

  final VoidCallback onComplete;

  /// Called when the auto-detect toggle changes.
  final ValueChanged<bool>? onAutoDetectChanged;

  @override
  ConsumerState<RemoteDetectStep> createState() => _RemoteDetectStepState();
}

class _RemoteDetectStepState extends ConsumerState<RemoteDetectStep> {
  bool _autoDetect = true;

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
    if (hasSSHConnection) {
      final hostId =
          '${connectedSession.connectionConfig.host}:${connectedSession.connectionConfig.port}';
      final detectionAsync = ref.watch(remoteAiDetectionStateProvider(hostId));
      detectionResult = detectionAsync.valueOrNull;
      isDetecting = detectionAsync.isLoading;
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
              Text(
                'Found on $hostName',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ollama models
          if (result.hasOllama) ...[
            for (final model in result.ollamaModels)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.memory,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      model.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (model.tag != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        model.tag!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Local',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // Cloud providers
          if (result.hasCloudProviders) ...[
            if (result.hasOllama) const SizedBox(height: 4),
            for (final provider in result.cloudProviders)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (provider == result.bestCloudProvider)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Best',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
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
