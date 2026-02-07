// @telos L1:function:lib/features/ai/presentation/widgets:ai_ghostwriter_panel

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../data/services/local_ai_service.dart';
import '../../domain/entities/ai_privacy_mode.dart';
import '../providers/ai_providers.dart';
import 'ai_command_suggestion.dart';

/// Bottom sheet panel for AI Ghostwriter natural language input.
///
/// Features:
/// - Header with title, AI icon, and privacy indicator
/// - Natural language input field with auto-focus
/// - AI command suggestion display
/// - Action buttons: Regenerate, Edit, Copy, Execute
class AiGhostwriterPanel extends ConsumerStatefulWidget {
  const AiGhostwriterPanel({
    super.key,
    required this.onExecute,
    required this.onDismiss,
  });

  /// Callback when user wants to execute a command.
  final void Function(String command) onExecute;

  /// Callback when panel should be dismissed.
  final VoidCallback onDismiss;

  @override
  ConsumerState<AiGhostwriterPanel> createState() => _AiGhostwriterPanelState();
}

class _AiGhostwriterPanelState extends ConsumerState<AiGhostwriterPanel> {
  late TextEditingController _inputController;
  late FocusNode _inputFocusNode;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputFocusNode = FocusNode();

    // Listen to focus changes to rebuild with correct border color
    _inputFocusNode.addListener(_onFocusChange);

    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    // Trigger rebuild when focus changes
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _inputFocusNode.removeListener(_onFocusChange);
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the new aiPrivacyModeProvider that reads from the service
    final privacyMode = ref.watch(aiPrivacyModeProvider);
    final suggestionAsync = ref.watch(aiSuggestionControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.aiPanelBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              _buildHeader(context, privacyMode),

              const SizedBox(height: 16),

              // Input field
              _buildInputField(context),

              const SizedBox(height: 16),

              // Suggestion display
              suggestionAsync.when(
                data: (suggestion) => AiCommandSuggestion(
                  suggestion: suggestion,
                ),
                loading: () => const AiCommandSuggestion(isLoading: true),
                error: (error, _) => AiCommandSuggestion(
                  error: error.toString(),
                  onRetry: () => ref
                      .read(aiSuggestionControllerProvider.notifier)
                      .regenerate(),
                ),
              ),

              // Action buttons (only show when we have a suggestion)
              if (suggestionAsync.hasValue &&
                  suggestionAsync.value != null) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context, suggestionAsync.value!.command),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AiPrivacyMode privacyMode) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // AI icon and title
        Icon(
          Icons.auto_awesome,
          color: theme.aiPrimaryColor,
          size: 24,
          semanticLabel: 'AI',
        ),
        const SizedBox(width: 8),
        Text(
          'AI Ghostwriter',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),

        // Privacy indicator
        _PrivacyBadge(mode: privacyMode),

        const SizedBox(width: 8),

        // Close button
        IconButton(
          onPressed: () async {
            // Stop any in-progress LLM generation before closing
            final service = ref.read(aiServiceProvider);
            if (service is LocalAiService) {
              await service.stopGeneration();
            }
            widget.onDismiss();
          },
          icon: Icon(
            Icons.close,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: 'Close panel',
          ),
          tooltip: 'Close',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12);
    final isFocused = _inputFocusNode.hasFocus;

    return Semantics(
      label: 'Natural language command input',
      hint: 'Describe what command you want to run',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: isFocused
                ? theme.aiPrimaryColor
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isFocused ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: TextField(
            controller: _inputController,
            focusNode: _inputFocusNode,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Describe what you want to do...',
              hintStyle: TextStyle(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: theme.aiSuggestionBackground,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
            onChanged: (value) {
              ref.read(aiInputProvider.notifier).update(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String command) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Regenerate button
        Expanded(
          child: _ActionButton(
            icon: Icons.refresh,
            label: 'Regenerate',
            onPressed: () {
              ref.read(aiSuggestionControllerProvider.notifier).regenerate();
            },
          ),
        ),
        const SizedBox(width: 8),

        // Edit button
        Expanded(
          child: _ActionButton(
            icon: Icons.edit,
            label: 'Edit',
            onPressed: () {
              // Copy command to input for editing
              _inputController.text = command;
              _inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: command.length),
              );
              _inputFocusNode.requestFocus();
            },
          ),
        ),
        const SizedBox(width: 8),

        // Copy button
        Expanded(
          child: _ActionButton(
            icon: Icons.copy,
            label: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Execute button (primary)
        Expanded(
          flex: 2,
          child: Semantics(
            button: true,
            label: 'Execute command',
            hint: 'Run this command in the terminal',
            child: FilledButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();

                // Stop any in-progress LLM generation before executing
                // This prevents native crashes in llama.cpp
                final service = ref.read(aiServiceProvider);
                if (service is LocalAiService) {
                  await service.waitForCompletion();
                }

                widget.onExecute(command);
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Execute'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.aiPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Privacy mode indicator badge.
class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge({required this.mode});

  final AiPrivacyMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocal = mode == AiPrivacyMode.local;

    return Semantics(
      label: isLocal
          ? 'Privacy mode: Local processing'
          : 'Privacy mode: Cloud processing',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLocal
              ? theme.aiHighConfidenceColor.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocal
                ? theme.aiHighConfidenceColor.withValues(alpha: 0.3)
                : Colors.blue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocal ? Icons.security : Icons.cloud,
              size: 12,
              color: isLocal ? theme.aiHighConfidenceColor : Colors.blue,
            ),
            const SizedBox(width: 4),
            Text(
              isLocal ? 'Local' : 'Cloud',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLocal ? theme.aiHighConfidenceColor : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary action button.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
