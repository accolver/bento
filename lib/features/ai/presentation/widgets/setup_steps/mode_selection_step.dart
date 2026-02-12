// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:mode_selection_step

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ai_config.dart';
import '../../../../session/domain/entities/session_status.dart';
import '../../../../session/presentation/providers/session_list_controller.dart';
import '../../providers/ai_providers.dart';
import '../../providers/remote_ai_providers.dart';

/// First step of the AI setup wizard - choose AI mode.
class ModeSelectionStep extends ConsumerWidget {
  const ModeSelectionStep({
    super.key,
    required this.onModeSelected,
    this.onSkip,
  });

  final void Function(AiMode mode) onModeSelected;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(aiConfigStateProvider);
    final currentMode = configAsync.valueOrNull?.mode ?? AiMode.unconfigured;
    final isReconfiguring = currentMode != AiMode.unconfigured;

    // Check if any SSH session is connected
    final sessionState = ref.watch(sessionListControllerProvider);
    final connectedSession = sessionState.sessions
        .where((s) => s.status == SessionStatus.connected)
        .firstOrNull;
    final hasSSHConnection = connectedSession != null;

    // Check if providers have been detected on the active host
    String? remoteSubtitle;
    String remoteDescription;
    if (hasSSHConnection) {
      final hostId =
          '${connectedSession.connectionConfig.host}:${connectedSession.connectionConfig.port}';
      final detectionAsync = ref.watch(remoteAiDetectionStateProvider(hostId));
      final result = detectionAsync.valueOrNull;

      if (result != null && result.hasAnyProvider) {
        final count = result.providerCount;
        remoteSubtitle = '$count provider${count == 1 ? '' : 's'} detected';
        remoteDescription =
            'AI providers found on ${connectedSession.displayName}. '
            'Data stays on your infrastructure.';
      } else if (detectionAsync.isLoading) {
        remoteSubtitle = 'Detecting...';
        remoteDescription =
            'Checking for AI on ${connectedSession.displayName}...';
      } else {
        remoteSubtitle = 'SSH connected';
        remoteDescription =
            'Use AI on servers you SSH into. Data stays on your infrastructure.';
      }
    } else {
      remoteSubtitle = 'No SSH connection';
      remoteDescription =
          'Use AI on servers you SSH into. Connect via SSH first to enable.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            isReconfiguring ? 'Change AI Mode' : 'Set up AI Assistant',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReconfiguring
                ? 'Your current settings will be preserved'
                : 'Bento can help you write commands using AI',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Mode options
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _ModeCard(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud AI',
                    subtitle: 'Recommended',
                    description:
                        'Fast, reliable AI via OpenRouter. Requires API key.',
                    isPrivate: false,
                    isSelected: currentMode == AiMode.cloud,
                    onTap: () => onModeSelected(AiMode.cloud),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.shield_outlined,
                    title: 'Local AI',
                    subtitle: 'Experimental',
                    description:
                        'Run AI on your device. Private but may not work on all devices.',
                    isPrivate: true,
                    isSelected: currentMode == AiMode.local,
                    onTap: () => onModeSelected(AiMode.local),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.dns_outlined,
                    title: 'Remote AI',
                    subtitle: remoteSubtitle,
                    description: remoteDescription,
                    isPrivate: true,
                    isSelected: currentMode == AiMode.remote,
                    isHighlighted: hasSSHConnection,
                    isDisabled: !hasSSHConnection,
                    onTap: hasSSHConnection
                        ? () => onModeSelected(AiMode.remote)
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Skip/Cancel option
          TextButton(
            onPressed: () => onModeSelected(AiMode.unconfigured),
            child: Text(isReconfiguring ? 'Cancel' : 'Skip for now'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isPrivate,
    required this.isSelected,
    this.onTap,
    this.isHighlighted = false,
    this.isDisabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isPrivate;
  final bool isSelected;
  final VoidCallback? onTap;

  /// Whether this card should be visually highlighted (e.g., providers detected).
  final bool isHighlighted;

  /// Whether this card is disabled (grayed out, not tappable).
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final showHighlight = !isDisabled && (isSelected || isHighlighted);
    final effectiveOpacity = isDisabled ? 0.5 : 1.0;

    return Opacity(
      opacity: effectiveOpacity,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: showHighlight
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: showHighlight ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrivate
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isPrivate
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPrivate
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subtitle,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isPrivate
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
