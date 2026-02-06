// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:mode_selection_step

import 'package:flutter/material.dart';

import '../../../domain/entities/ai_config.dart';

/// First step of the AI setup wizard - choose AI mode.
class ModeSelectionStep extends StatelessWidget {
  const ModeSelectionStep({
    super.key,
    required this.onModeSelected,
    this.onSkip,
  });

  final void Function(AiMode mode) onModeSelected;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            'Set up AI Assistant',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bento can help you write commands using AI',
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
                    icon: Icons.shield_outlined,
                    title: 'Local AI',
                    subtitle: 'Private',
                    description:
                        'Run AI on your device. Your data never leaves your phone.',
                    isPrivate: true,
                    onTap: () => onModeSelected(AiMode.local),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud AI',
                    subtitle: 'Powerful',
                    description:
                        'Use advanced models via OpenRouter. Sends prompts to external servers.',
                    isPrivate: false,
                    onTap: () => onModeSelected(AiMode.cloud),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    icon: Icons.dns_outlined,
                    title: 'Remote AI',
                    subtitle: 'On your server',
                    description:
                        'Use Ollama on servers you SSH into. Data stays on your infrastructure.',
                    isPrivate: true,
                    onTap: () => onModeSelected(AiMode.remote),
                  ),
                ],
              ),
            ),
          ),

          // Skip option
          TextButton(
            onPressed: () => onModeSelected(AiMode.unconfigured),
            child: const Text('Skip for now'),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isPrivate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
