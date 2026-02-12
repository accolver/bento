// @telos L2:contract:lib/features/ai/presentation/widgets:remote_provider_selector

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/cloud_proxy_backend.dart';
import '../../data/services/ollama_backend.dart';
import '../../data/services/remote_ai_service.dart';
import '../../domain/entities/ollama_model.dart';
import '../../domain/entities/remote_ai_config.dart';
import '../../domain/entities/remote_ai_detection.dart';
import '../../domain/entities/remote_ai_provider.dart';
import '../providers/remote_ai_providers.dart';

/// Bottom sheet widget for selecting a remote AI provider.
///
/// Shows both Ollama models and cloud providers in a ranked list,
/// highlights the recommended provider, and shows privacy badges.
class RemoteProviderSelector extends ConsumerWidget {
  const RemoteProviderSelector({
    super.key,
    required this.hostId,
    required this.hostname,
    required this.detectionResult,
    this.onSelected,
  });

  /// SSH host identifier.
  final String hostId;

  /// Display name of the host.
  final String hostname;

  /// Detection results with available providers.
  final RemoteAiDetectionResult detectionResult;

  /// Called when a provider is selected. Null to close the selector.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentService = ref.watch(remoteAiServiceControllerProvider(hostId));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Providers on $hostname',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Provider list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  // Cloud providers (sorted by quality rank)
                  if (detectionResult.hasCloudProviders) ...[
                    _SectionHeader(
                      title: 'Cloud Providers',
                      subtitle: 'Keys on remote host',
                    ),
                    ...detectionResult.cloudProviders.map(
                      (provider) => _CloudProviderTile(
                        provider: provider,
                        isActive: _isCloudActive(currentService, provider),
                        isRecommended:
                            provider == detectionResult.bestCloudProvider,
                        onTap: () => _selectCloud(ref, provider),
                      ),
                    ),
                  ],
                  // Ollama models
                  if (detectionResult.hasOllama) ...[
                    if (detectionResult.hasCloudProviders)
                      const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Ollama',
                      subtitle: 'Local inference on server',
                    ),
                    ...detectionResult.ollamaModels.map(
                      (model) => _OllamaModelTile(
                        model: model,
                        isActive: _isOllamaActive(currentService, model),
                        onTap: () => _selectOllama(ref, model),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isCloudActive(
    RemoteAiService? service,
    DetectedCloudProvider provider,
  ) {
    if (service == null) return false;
    final backend = service.backend;
    return backend is CloudProxyBackend &&
        backend.envVarName == provider.envVarName;
  }

  bool _isOllamaActive(RemoteAiService? service, OllamaModel model) {
    if (service == null) return false;
    final backend = service.backend;
    return backend is OllamaBackend && backend.selectedModel == model.name;
  }

  void _selectCloud(WidgetRef ref, DetectedCloudProvider provider) {
    final providerConfig =
        RemoteProviderRegistry.forProvider(provider.provider);
    if (providerConfig == null) return;

    final backend = CloudProxyBackend(
      providerConfig: providerConfig,
      envVarName: provider.envVarName,
    );

    ref
        .read(remoteAiServiceControllerProvider(hostId).notifier)
        .switchBackend(backend);

    // Save preference
    ref.read(remoteAiConfigStateProvider(hostId).notifier).save(
          RemoteAiConfig(
            hostId: hostId,
            backendType: RemoteBackendType.cloudProxy,
            cloudProvider: provider.provider,
            envVarName: provider.envVarName,
          ),
        );

    onSelected?.call();
  }

  void _selectOllama(WidgetRef ref, OllamaModel model) {
    final backend = OllamaBackend(
      selectedModel: model.name,
      availableModels: detectionResult.ollamaModels,
    );

    ref
        .read(remoteAiServiceControllerProvider(hostId).notifier)
        .switchBackend(backend);

    // Save preference
    ref.read(remoteAiConfigStateProvider(hostId).notifier).save(
          RemoteAiConfig(
            hostId: hostId,
            backendType: RemoteBackendType.ollama,
            ollamaModel: model.name,
          ),
        );

    onSelected?.call();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloudProviderTile extends StatelessWidget {
  const _CloudProviderTile({
    required this.provider,
    required this.isActive,
    required this.isRecommended,
    required this.onTap,
  });

  final DetectedCloudProvider provider;
  final bool isActive;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Provider icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  size: 20,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // Provider info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          provider.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Best',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'via \$${provider.envVarName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Privacy badge
              _PrivacyBadge(
                label: 'Cloud via remote',
                color: theme.colorScheme.tertiary,
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OllamaModelTile extends StatelessWidget {
  const _OllamaModelTile({
    required this.model,
    required this.isActive,
    required this.onTap,
  });

  final OllamaModel model;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Model icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.memory,
                  size: 20,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // Model info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${model.name} (${model.formattedSize})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Privacy badge
              _PrivacyBadge(
                label: 'Local inference',
                color: theme.colorScheme.secondary,
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show the remote provider selector as a modal bottom sheet.
Future<void> showRemoteProviderSelector({
  required BuildContext context,
  required String hostId,
  required String hostname,
  required RemoteAiDetectionResult detectionResult,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => RemoteProviderSelector(
      hostId: hostId,
      hostname: hostname,
      detectionResult: detectionResult,
      onSelected: () => Navigator.of(context).pop(),
    ),
  );
}
