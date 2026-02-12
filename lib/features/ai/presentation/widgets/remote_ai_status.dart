// @telos L2:contract:lib/features/ai/presentation/widgets:remote_ai_status

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/cloud_proxy_backend.dart';
import '../../data/services/ollama_backend.dart';
import '../providers/remote_ai_providers.dart';

/// Compact status indicator showing the active remote AI provider.
///
/// Displays: "Remote AI: [provider] on [host]" when active,
/// or "Disconnected" when SSH drops. Tap to open provider selector.
class RemoteAiStatus extends ConsumerWidget {
  const RemoteAiStatus({
    super.key,
    required this.hostId,
    required this.hostname,
    this.onTap,
  });

  /// SSH host identifier.
  final String hostId;

  /// Display name of the host.
  final String hostname;

  /// Called when the status indicator is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.watch(remoteAiServiceControllerProvider(hostId));

    final isConnected = service?.isConnected ?? false;
    final backendName = service?.backend.displayName ?? 'Not configured';

    // Determine icon and color based on backend type
    final IconData icon;
    final Color statusColor;
    final String label;

    if (!isConnected || service == null) {
      icon = Icons.cloud_off;
      statusColor = theme.colorScheme.error;
      label = 'Disconnected';
    } else if (service.backend is OllamaBackend) {
      icon = Icons.memory;
      statusColor = theme.colorScheme.secondary;
      label = backendName;
    } else if (service.backend is CloudProxyBackend) {
      icon = Icons.cloud_outlined;
      statusColor = theme.colorScheme.tertiary;
      label = backendName;
    } else {
      icon = Icons.auto_awesome;
      statusColor = theme.colorScheme.primary;
      label = backendName;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected
                    ? const Color(0xFF4CAF50) // green
                    : theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 14,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.unfold_more,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
