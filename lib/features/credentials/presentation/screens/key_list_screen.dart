// @telos L1:function:lib/features/credentials/presentation/screens:key_list_screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/utils/ssh_key_utils.dart';
import '../../domain/entities/credential.dart';
import '../providers/credential_providers.dart';
import 'key_generate_screen.dart';
import 'key_import_screen.dart';

/// Screen displaying all stored SSH keys with management options.
class KeyListScreen extends ConsumerWidget {
  const KeyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsAsync = ref.watch(credentialsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Keys'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToImport(context),
            tooltip: 'Import Key',
          ),
        ],
      ),
      body: credentialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error loading keys: $error'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(credentialsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (credentials) {
          // Filter to only show keys (not passwords)
          final keys = credentials
              .where((c) => c.type != CredentialType.password)
              .toList();

          if (keys.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              return _KeyCard(
                credential: key,
                onTap: () => _showKeyDetails(context, ref, key),
                onDelete: () => _confirmDelete(context, ref, key),
                onToggleBiometric: () => _toggleBiometric(ref, key),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'generate',
            onPressed: () => _navigateToGenerate(context),
            tooltip: 'Generate New Key',
            child: const Icon(Icons.key),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: () => _navigateToImport(context),
            icon: const Icon(Icons.file_download),
            label: const Text('Import Key'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vpn_key_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No SSH Keys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Import or generate SSH keys to use for authentication.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _navigateToImport(context),
              icon: const Icon(Icons.file_download),
              label: const Text('Import Key'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToImport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<Credential>(
        builder: (_) => const KeyImportScreen(),
      ),
    );
  }

  void _navigateToGenerate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<Credential>(
        builder: (_) => const KeyGenerateScreen(),
      ),
    );
  }

  void _showKeyDetails(BuildContext context, WidgetRef ref, Credential key) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _KeyDetailsSheet(credential: key),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Credential key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Key?'),
        content: Text(
          'Are you sure you want to delete "${key.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(credentialControllerProvider.notifier)
          .deleteCredential(key.id);
    }
  }

  Future<void> _toggleBiometric(WidgetRef ref, Credential key) async {
    await ref.read(credentialControllerProvider.notifier).setBiometric(
          key.id,
          require: !key.requiresBiometric,
        );
  }
}

/// Card widget for displaying an SSH key.
class _KeyCard extends StatelessWidget {
  const _KeyCard({
    required this.credential,
    required this.onTap,
    required this.onDelete,
    required this.onToggleBiometric,
  });

  final Credential credential;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleBiometric;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.vpn_key,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(credential.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    SSHKeyUtils.getKeyTypeString(credential.type),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                if (credential.requiresBiometric) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.fingerprint,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
            if (credential.fingerprint != null)
              Text(
                SSHKeyUtils.formatFingerprint(credential.fingerprint!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.outline,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'biometric':
                onToggleBiometric();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'biometric',
              child: Row(
                children: [
                  Icon(
                    credential.requiresBiometric
                        ? Icons.fingerprint_outlined
                        : Icons.fingerprint,
                  ),
                  const SizedBox(width: 8),
                  Text(credential.requiresBiometric
                      ? 'Disable Biometric'
                      : 'Enable Biometric'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Bottom sheet showing key details.
class _KeyDetailsSheet extends ConsumerStatefulWidget {
  const _KeyDetailsSheet({required this.credential});

  final Credential credential;

  @override
  ConsumerState<_KeyDetailsSheet> createState() => _KeyDetailsSheetState();
}

class _KeyDetailsSheetState extends ConsumerState<_KeyDetailsSheet> {
  String? _publicKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPublicKey();
  }

  Future<void> _loadPublicKey() async {
    setState(() => _isLoading = true);

    final controller = ref.read(credentialControllerProvider.notifier);
    final material = await controller.getSecureMaterial(widget.credential);

    if (material != null && mounted) {
      final pubKey = SSHKeyUtils.extractPublicKey(material);
      setState(() {
        _publicKey = pubKey;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.vpn_key,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.credential.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          SSHKeyUtils.getKeyTypeString(widget.credential.type),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fingerprint
              if (widget.credential.fingerprint != null) ...[
                _DetailRow(
                  icon: Icons.fingerprint,
                  label: 'Fingerprint',
                  value: SSHKeyUtils.formatFingerprint(
                      widget.credential.fingerprint!),
                  isMonospace: true,
                ),
                const SizedBox(height: 16),
              ],

              // Created at
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Created',
                value: _formatDate(widget.credential.createdAt),
              ),
              const SizedBox(height: 16),

              // Last used
              if (widget.credential.lastUsedAt != null) ...[
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Last Used',
                  value: _formatDate(widget.credential.lastUsedAt!),
                ),
                const SizedBox(height: 16),
              ],

              // Biometric
              _DetailRow(
                icon: Icons.lock,
                label: 'Biometric Protection',
                value: widget.credential.requiresBiometric
                    ? 'Enabled'
                    : 'Disabled',
              ),
              const SizedBox(height: 24),

              // Public key
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_publicKey != null) ...[
                Text(
                  'Public Key',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _publicKey!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copyPublicKey(context),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Public Key'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyPublicKey(BuildContext context) {
    if (_publicKey == null) return;

    // Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Public key copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Widget for displaying a detail row.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: isMonospace
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        )
                    : Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
