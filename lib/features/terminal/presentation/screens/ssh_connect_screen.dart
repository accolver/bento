// @telos L1:function:lib/features/terminal/presentation/screens:ssh_connect_screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../connections/domain/entities/saved_connection.dart';
import '../../../connections/presentation/providers/saved_connections_provider.dart';
import '../../../credentials/domain/entities/credential.dart';
import '../../../credentials/presentation/providers/credential_providers.dart';
import '../../../credentials/presentation/screens/key_list_screen.dart';
import '../../../session/domain/entities/session_status.dart';
import '../../../session/presentation/providers/session_list_controller.dart';
import '../../domain/entities/ssh_auth_method.dart';
import '../../domain/entities/ssh_connection_config.dart';
import '../providers/terminal_provider.dart';

/// Screen for entering SSH connection details and connecting.
///
/// Provides form fields for host, port, username, and password.
/// Connects via SSH and displays terminal output on success.
class SSHConnectScreen extends ConsumerStatefulWidget {
  const SSHConnectScreen({super.key});

  @override
  ConsumerState<SSHConnectScreen> createState() => _SSHConnectScreenState();
}

class _SSHConnectScreenState extends ConsumerState<SSHConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _connectionNameController = TextEditingController();

  bool _isConnecting = false;
  bool _saveConnection = false;
  String? _errorMessage;

  // Key-based auth state
  bool _useKeyAuth = false;
  Credential? _selectedKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _connectionNameController.dispose();
    super.dispose();
  }

  Future<void> _connect({SavedConnection? savedConnection}) async {
    String host;
    int port;
    String username;
    String? password;
    String? privateKey;
    String? passphrase;

    if (savedConnection != null) {
      // Use saved connection
      host = savedConnection.host;
      port = savedConnection.port;
      username = savedConnection.username;

      // Get stored credential
      final controller = ref.read(savedConnectionsControllerProvider.notifier);
      password = await controller.getCredential(savedConnection.id);

      if (password == null) {
        setState(() {
          _errorMessage = 'Could not retrieve saved password';
        });
        return;
      }

      // Mark as used
      await controller.markUsed(savedConnection.id);
    } else {
      // Use form values
      if (!_formKey.currentState!.validate()) return;

      host = _hostController.text.trim();
      port = int.tryParse(_portController.text) ?? 22;
      username = _usernameController.text.trim();

      if (_useKeyAuth && _selectedKey != null) {
        // Get key material with biometric if required
        final credController = ref.read(credentialControllerProvider.notifier);
        privateKey = await credController.getSecureMaterial(_selectedKey!);

        if (privateKey == null) {
          setState(() {
            _errorMessage = 'Could not retrieve SSH key';
          });
          return;
        }

        // Get passphrase if key might be encrypted
        passphrase = await credController.getPassphrase(_selectedKey!.id);

        // Mark key as used
        await credController.markUsed(_selectedKey!.id);
      } else {
        password = _passwordController.text;
      }
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    // Create auth method based on type
    final SSHAuthMethod authMethod;
    if (_useKeyAuth && privateKey != null) {
      authMethod = SSHAuthMethod.key(
        username: username,
        privateKey: privateKey,
        passphrase: passphrase,
      );
    } else {
      authMethod = SSHAuthMethod.password(
        username: username,
        password: password ?? '',
      );
    }

    final config = SSHConnectionConfig(
      host: host,
      port: port,
      authMethod: authMethod,
    );

    // Create session name
    final sessionName = savedConnection?.name ??
        (_connectionNameController.text.trim().isNotEmpty
            ? _connectionNameController.text.trim()
            : '$username@$host');

    // Create a new session for tab display
    final sessionId =
        ref.read(sessionListControllerProvider.notifier).createSession(
              config: config,
              name: sessionName,
            );

    // Connect via the shared terminal controller (for now)
    // TODO: Use per-session terminals once TerminalScreen is updated
    final result =
        await ref.read(terminalControllerProvider.notifier).connectSSH(config);

    if (!mounted) return;

    result.fold(
      (failure) {
        // Remove failed session
        ref
            .read(sessionListControllerProvider.notifier)
            .closeSession(sessionId);

        setState(() {
          _isConnecting = false;
          _errorMessage = failure.message;
        });
      },
      (_) async {
        // Mark session as connected
        ref.read(sessionListControllerProvider.notifier).updateSessionStatus(
              sessionId,
              SessionStatus.connected,
            );

        try {
          // Save connection if requested
          if (_saveConnection && savedConnection == null) {
            await ref
                .read(savedConnectionsControllerProvider.notifier)
                .saveConnection(
                  name: sessionName,
                  host: host,
                  port: port,
                  username: username,
                  authType: _useKeyAuth ? 'key' : 'password',
                  password: _useKeyAuth ? null : password,
                );
          }
        } catch (e) {
          debugPrint('Error saving connection: $e');
          // Continue anyway - connection succeeded even if save failed
        }

        if (!mounted) return;

        setState(() {
          _isConnecting = false;
        });
        // Connection successful - navigate to sessions screen
        if (mounted) {
          // Push sessions screen so back button can return to previous screen
          context.push(Routes.sessions);
        }
      },
    );
  }

  void _fillFromSaved(SavedConnection connection) {
    _hostController.text = connection.host;
    _portController.text = connection.port.toString();
    _usernameController.text = connection.username;
    _connectionNameController.text = connection.name;
    _passwordController.clear();
    _tabController.animateTo(1); // Switch to "New" tab to show filled form
  }

  void _navigateToKeyList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const KeyListScreen(),
      ),
    );
  }

  Widget _buildKeySelector() {
    final credentialsAsync = ref.watch(credentialsProvider);

    return credentialsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.error),
        title: const Text('Error loading keys'),
        subtitle: Text('$error'),
      ),
      data: (credentials) {
        // Filter to only show SSH keys (not passwords)
        final keys = credentials
            .where((c) => c.type != CredentialType.password)
            .toList();

        if (keys.isEmpty) {
          return ListTile(
            leading: const Icon(Icons.vpn_key_off),
            title: const Text('No SSH keys'),
            subtitle: const Text('Import or generate a key first'),
            trailing: FilledButton.tonal(
              onPressed: _navigateToKeyList,
              child: const Text('Manage'),
            ),
          );
        }

        return DropdownButtonFormField<Credential>(
          value: _selectedKey,
          decoration: const InputDecoration(
            labelText: 'Select SSH Key',
            prefixIcon: Icon(Icons.vpn_key),
          ),
          items: keys.map((key) {
            return DropdownMenuItem<Credential>(
              value: key,
              child: Row(
                children: [
                  if (key.requiresBiometric)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.fingerprint, size: 16),
                    ),
                  Text(key.name),
                  const SizedBox(width: 8),
                  Text(
                    key.typeDisplay,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (key) => setState(() => _selectedKey = key),
          validator: (value) {
            if (_useKeyAuth && value == null) {
              return 'Please select an SSH key';
            }
            return null;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Connect'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Saved', icon: Icon(Icons.bookmark)),
            Tab(text: 'New', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedConnectionsTab(),
          _buildNewConnectionTab(),
        ],
      ),
    );
  }

  Widget _buildSavedConnectionsTab() {
    final connectionsAsync = ref.watch(savedConnectionsProvider);

    return connectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading connections: $error'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(savedConnectionsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (connections) {
        if (connections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved connections',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new connection to save it',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.add),
                  label: const Text('New Connection'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            return _SavedConnectionCard(
              connection: connection,
              isConnecting: _isConnecting,
              onConnect: () => _connect(savedConnection: connection),
              onEdit: () => _fillFromSaved(connection),
              onDelete: () => _confirmDelete(connection),
              onToggleFavorite: () async {
                await ref
                    .read(savedConnectionsControllerProvider.notifier)
                    .toggleFavorite(connection.id);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(SavedConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection?'),
        content: Text('Are you sure you want to delete "${connection.name}"?'),
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
          .read(savedConnectionsControllerProvider.notifier)
          .deleteConnection(connection.id);
    }
  }

  Widget _buildNewConnectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Host field
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'e.g., 192.168.1.100 or server.example.com',
                prefixIcon: Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Host is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Port field
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '22',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Port is required';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'e.g., root or admin',
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Auth method selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Password'),
                                icon: Icon(Icons.lock),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('SSH Key'),
                                icon: Icon(Icons.vpn_key),
                              ),
                            ],
                            selected: {_useKeyAuth},
                            onSelectionChanged: (selection) {
                              setState(() => _useKeyAuth = selection.first);
                            },
                          ),
                        ),
                        if (_useKeyAuth)
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: _navigateToKeyList,
                            tooltip: 'Manage Keys',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_useKeyAuth) ...[
                      // Key selection
                      _buildKeySelector(),
                    ] else ...[
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _connect(),
                        validator: (value) {
                          if (!_useKeyAuth &&
                              (value == null || value.isEmpty)) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save connection option
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Save this connection'),
                      subtitle: const Text('Store credentials securely'),
                      value: _saveConnection,
                      onChanged: (value) =>
                          setState(() => _saveConnection = value),
                    ),
                    if (_saveConnection) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextFormField(
                          controller: _connectionNameController,
                          decoration: const InputDecoration(
                            labelText: 'Connection name (optional)',
                            hintText: 'e.g., Work Server, Home NAS',
                            prefixIcon: Icon(Icons.label),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Connect button
            FilledButton.icon(
              onPressed: _isConnecting ? null : _connect,
              icon: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying a saved connection.
class _SavedConnectionCard extends StatelessWidget {
  const _SavedConnectionCard({
    required this.connection,
    required this.isConnecting,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final SavedConnection connection;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: connection.color != null
              ? Color(int.parse(connection.color!, radix: 16))
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.computer,
            color: connection.color != null
                ? Colors.white
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(connection.name),
        subtitle: Text(
          connection.displayString,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                connection.isFavorite ? Icons.star : Icons.star_border,
                color: connection.isFavorite ? Colors.amber : null,
              ),
              onPressed: onToggleFavorite,
              tooltip: connection.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
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
          ],
        ),
        onTap: isConnecting ? null : onConnect,
      ),
    );
  }
}
