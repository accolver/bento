// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:cloud_api_key_step

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/ai_config.dart';
import '../../providers/ai_providers.dart';

/// Step for entering the OpenRouter API key.
class CloudApiKeyStep extends ConsumerStatefulWidget {
  const CloudApiKeyStep({
    super.key,
    required this.provider,
    required this.onComplete,
  });

  final CloudAiProvider provider;
  final void Function(String apiKey) onComplete;

  @override
  ConsumerState<CloudApiKeyStep> createState() => _CloudApiKeyStepState();
}

class _CloudApiKeyStepState extends ConsumerState<CloudApiKeyStep> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscureText = true;
  bool _isValidating = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  /// Load existing API key if available, so user doesn't have to re-enter.
  Future<void> _loadExistingKey() async {
    final configNotifier = ref.read(aiConfigStateProvider.notifier);
    final existingKey = await configNotifier.getApiKey();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (existingKey != null && existingKey.isNotEmpty) {
          _controller.text = existingKey;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  Future<void> _openOpenRouter() async {
    final url = Uri.parse('https://openrouter.ai/keys');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Could not open URL. Please visit openrouter.ai/keys'),
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _error = 'Please enter an API key';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _error = null;
    });

    // TODO: Implement actual OpenRouter API key validation
    // For now, just check the format
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (apiKey.startsWith('sk-or-') && apiKey.length > 20) {
      setState(() {
        _isValidating = false;
      });
      // Show success briefly then proceed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key looks valid!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _isValidating = false;
        _error = 'Invalid API key format. It should start with "sk-or-"';
      });
    }
  }

  void _save() {
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _error = 'Please enter an API key';
      });
      return;
    }

    widget.onComplete(apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = _controller.text.isNotEmpty;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            hasValue ? 'Update Your API Key' : 'Enter Your API Key',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasValue
                ? 'Your existing key is pre-filled. You can update it or continue with the current key.'
                : 'Get a key from openrouter.ai',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // API key input
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-or-v1-...',
              errorText: _error,
              border: const OutlineInputBorder(),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    tooltip: _obscureText ? 'Show' : 'Hide',
                  ),
                  IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste',
                  ),
                ],
              ),
            ),
            onChanged: (_) {
              setState(() {
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),

          // Privacy notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your API key is stored securely on this device only.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Get API key link
          TextButton.icon(
            onPressed: _openOpenRouter,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Get an API key from OpenRouter'),
          ),

          const Spacer(),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isValidating ? null : _testConnection,
                  child: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Connection'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: hasValue && !_isValidating ? _save : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
