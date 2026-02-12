// @telos L2:contract:lib/features/ai/presentation/widgets:remote_ai_notification

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/remote_ai_detection.dart';
import '../providers/remote_ai_providers.dart';

/// Non-intrusive notification banner shown when AI providers are detected
/// on a remote SSH host.
///
/// Displays the count of detected providers and allows the user to tap
/// to configure. Can be dismissed per-host.
class RemoteAiNotification extends ConsumerStatefulWidget {
  const RemoteAiNotification({
    super.key,
    required this.hostId,
    required this.hostname,
    required this.onConfigure,
  });

  /// The SSH host identifier for detection state lookup.
  final String hostId;

  /// Display name of the connected host.
  final String hostname;

  /// Called when the user taps to configure remote AI.
  final VoidCallback onConfigure;

  @override
  ConsumerState<RemoteAiNotification> createState() =>
      _RemoteAiNotificationState();
}

class _RemoteAiNotificationState extends ConsumerState<RemoteAiNotification>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _dismissed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final detectionAsync =
        ref.watch(remoteAiDetectionStateProvider(widget.hostId));
    final result = detectionAsync.valueOrNull;

    if (result == null || !result.hasAnyProvider) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 60),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildBanner(context, result),
    );
  }

  Widget _buildBanner(BuildContext context, RemoteAiDetectionResult result) {
    final theme = Theme.of(context);
    final providerCount = result.providerCount;
    final summary = _buildSummary(result);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onConfigure,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$providerCount AI provider${providerCount > 1 ? 's' : ''} found',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Configure',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                // Dismiss button
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSummary(RemoteAiDetectionResult result) {
    final parts = <String>[];
    if (result.hasOllama) {
      parts.add(
        'Ollama (${result.ollamaModels.length} model${result.ollamaModels.length > 1 ? 's' : ''})',
      );
    }
    if (result.hasCloudProviders) {
      final names =
          result.cloudProviders.take(2).map((p) => p.displayName).join(', ');
      if (result.cloudProviders.length > 2) {
        parts.add('$names +${result.cloudProviders.length - 2} more');
      } else {
        parts.add(names);
      }
    }
    return 'on ${widget.hostname}: ${parts.join(', ')}';
  }
}
