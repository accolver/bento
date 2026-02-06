// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:cloud_provider_step

import 'package:flutter/material.dart';

import '../../../domain/entities/ai_config.dart';

/// Step for selecting a cloud AI provider.
class CloudProviderStep extends StatelessWidget {
  const CloudProviderStep({
    super.key,
    required this.onProviderSelected,
  });

  final void Function(CloudAiProvider provider) onProviderSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Choose AI Provider',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All providers use OpenRouter for unified access',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _ProviderCard(
                  name: 'Claude',
                  company: 'Anthropic',
                  description: 'Best reasoning and nuanced responses',
                  provider: CloudAiProvider.claude,
                  isRecommended: true,
                  onTap: () => onProviderSelected(CloudAiProvider.claude),
                ),
                const SizedBox(height: 12),
                _ProviderCard(
                  name: 'GPT-4o Mini',
                  company: 'OpenAI',
                  description: 'Fast and affordable',
                  provider: CloudAiProvider.gpt4oMini,
                  onTap: () => onProviderSelected(CloudAiProvider.gpt4oMini),
                ),
                const SizedBox(height: 12),
                _ProviderCard(
                  name: 'Llama 3.1',
                  company: 'Meta',
                  description: 'Open source, generous free tier',
                  provider: CloudAiProvider.llama3,
                  onTap: () => onProviderSelected(CloudAiProvider.llama3),
                ),
                const SizedBox(height: 12),
                _ProviderCard(
                  name: 'Gemini 2.0 Flash',
                  company: 'Google',
                  description: 'Very fast responses',
                  provider: CloudAiProvider.gemini,
                  onTap: () => onProviderSelected(CloudAiProvider.gemini),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.name,
    required this.company,
    required this.description,
    required this.provider,
    required this.onTap,
    this.isRecommended = false,
  });

  final String name;
  final String company;
  final String description;
  final CloudAiProvider provider;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRecommended
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          company,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRecommended) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Recommended',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
