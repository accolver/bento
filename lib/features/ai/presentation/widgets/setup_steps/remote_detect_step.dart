// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:remote_detect_step

import 'package:flutter/material.dart';

/// Step for configuring remote Ollama detection.
class RemoteDetectStep extends StatefulWidget {
  const RemoteDetectStep({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<RemoteDetectStep> createState() => _RemoteDetectStepState();
}

class _RemoteDetectStepState extends State<RemoteDetectStep> {
  bool _autoDetect = true;

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
            'Remote AI Detection',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Ollama on servers you connect to via SSH',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Auto-detect toggle
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-detect Ollama',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Check for Ollama when connecting via SSH',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoDetect,
                    onChanged: (value) {
                      setState(() {
                        _autoDetect = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Privacy First',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your prompts stay on the remote server. Nothing is sent to external services.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // How it works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _HowItWorksItem(
                  number: '1',
                  text: 'Connect to a server via SSH',
                ),
                const SizedBox(height: 4),
                _HowItWorksItem(
                  number: '2',
                  text: 'Bento checks if Ollama is running',
                ),
                const SizedBox(height: 4),
                _HowItWorksItem(
                  number: '3',
                  text: 'AI commands run on that server',
                ),
              ],
            ),
          ),

          const Spacer(),

          // Done button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onComplete,
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  const _HowItWorksItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
