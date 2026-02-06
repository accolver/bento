// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:local_model_select_step

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/local_ai_model.dart';
import '../../providers/ai_providers.dart';

/// Step for selecting which local model to download.
class LocalModelSelectStep extends ConsumerStatefulWidget {
  const LocalModelSelectStep({
    super.key,
    required this.onModelSelected,
  });

  final void Function(LocalAiModel model) onModelSelected;

  @override
  ConsumerState<LocalModelSelectStep> createState() =>
      _LocalModelSelectStepState();
}

class _LocalModelSelectStepState extends ConsumerState<LocalModelSelectStep> {
  final Map<String, bool> _downloadedModels = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
  }

  Future<void> _checkDownloadedModels() async {
    final downloadService = ref.read(modelDownloadServiceProvider);

    for (final model in availableLocalModels) {
      final isDownloaded = await downloadService.isModelDownloaded(model.id);
      if (mounted) {
        setState(() {
          _downloadedModels[model.id] = isDownloaded;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            'Choose a Model',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select based on your device capabilities',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: availableLocalModels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final model = availableLocalModels[index];
                final isDownloaded = _downloadedModels[model.id] ?? false;
                return _ModelCard(
                  model: model,
                  isDownloaded: isDownloaded,
                  isLoading: _isLoading,
                  onTap: () => widget.onModelSelected(model),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.onTap,
    required this.isDownloaded,
    required this.isLoading,
  });

  final LocalAiModel model;
  final VoidCallback onTap;
  final bool isDownloaded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: model.isRecommended
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: model.isRecommended ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      model.formattedSize,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                model.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Quality stars
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < model.qualityRating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Downloaded badge
                  if (isDownloaded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ready',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (model.isRecommended)
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
