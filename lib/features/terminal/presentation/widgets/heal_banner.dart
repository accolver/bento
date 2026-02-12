// @telos L2:contract:component-heal-banner

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/presentation/providers/ai_providers.dart';

/// Banner shown inside a failed block offering AI-powered error healing.
///
/// When a command fails (non-zero exit code), this banner:
/// 1. Analyzes the stderr using the AI service
/// 2. Suggests a fix with explanation
/// 3. Allows one-tap application of the fix
class HealBanner extends ConsumerStatefulWidget {
  const HealBanner({
    required this.command,
    required this.stderr,
    required this.exitCode,
    required this.onApplyFix,
    super.key,
  });

  /// The original command that failed.
  final String command;

  /// The stderr output from the failed command.
  final String stderr;

  /// The exit code of the failed command.
  final int exitCode;

  /// Called when the user taps "Apply Fix" with the suggested command.
  final void Function(String fixedCommand) onApplyFix;

  @override
  ConsumerState<HealBanner> createState() => _HealBannerState();
}

class _HealBannerState extends ConsumerState<HealBanner> {
  _HealState _state = _HealState.idle;
  String? _explanation;
  String? _fixedCommand;
  String? _error;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _analyzeError();
  }

  Future<void> _analyzeError() async {
    // Check if AI is available via the config
    final configAsync = ref.read(aiConfigStateProvider);
    final config = configAsync.valueOrNull;
    if (config == null || !config.isConfigured) {
      setState(() => _state = _HealState.unavailable);
      return;
    }

    setState(() => _state = _HealState.analyzing);

    try {
      // Use the async AI service provider to get the fully-initialized service
      final aiService = await ref.read(aiServiceControllerProvider.future);
      if (!await aiService.isAvailable()) {
        if (mounted) setState(() => _state = _HealState.unavailable);
        return;
      }

      // Use the AI to generate a fix
      final prompt = _buildHealPrompt();
      final result = await aiService.generateCommand(prompt);

      if (!mounted) return;

      // Parse the response from the AiSuggestion
      final parsed = _parseHealResponse(result.command);
      if (parsed != null) {
        setState(() {
          _state = _HealState.ready;
          _explanation = parsed.$1;
          _fixedCommand = parsed.$2;
        });
      } else {
        setState(() {
          _state = _HealState.failed;
          _error = 'Could not determine a fix';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _HealState.failed;
          _error = e.toString();
        });
      }
    }
  }

  String _buildHealPrompt() {
    final truncatedStderr = widget.stderr.length > 500
        ? widget.stderr.substring(0, 500)
        : widget.stderr;

    return 'A command failed. Suggest a fix.\n\n'
        'Command: ${widget.command}\n'
        'Exit code: ${widget.exitCode}\n'
        'Error output:\n$truncatedStderr\n\n'
        'Respond with ONLY two lines:\n'
        'EXPLANATION: <brief explanation>\n'
        'FIXED: <the fixed command>';
  }

  (String, String)? _parseHealResponse(String response) {
    String? explanation;
    String? fixed;

    for (final line in response.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('EXPLANATION:')) {
        explanation = trimmed.substring('EXPLANATION:'.length).trim();
      } else if (trimmed.startsWith('FIXED:')) {
        fixed = trimmed.substring('FIXED:'.length).trim();
      }
    }

    // Fallback: if the response is just a command, use it
    if (fixed == null && response.trim().isNotEmpty) {
      final lines = response.trim().split('\n');
      if (lines.length == 1) {
        fixed = lines.first.trim();
        explanation = 'Suggested fix';
      }
    }

    if (explanation != null && fixed != null) {
      return (explanation, fixed);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _state == _HealState.unavailable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: switch (_state) {
        _HealState.idle || _HealState.analyzing => _buildAnalyzing(theme),
        _HealState.ready => _buildReady(theme),
        _HealState.failed => _buildFailed(theme),
        _HealState.unavailable => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildAnalyzing(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Analyzing error...',
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        _DismissButton(onTap: () => setState(() => _dismissed = true)),
      ],
    );
  }

  Widget _buildReady(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.build, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Fix Available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            _DismissButton(onTap: () => setState(() => _dismissed = true)),
          ],
        ),
        const SizedBox(height: 8),
        if (_explanation != null)
          Text(
            _explanation!,
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _fixedCommand ?? '',
            style: TextStyle(
              fontFamily: 'JetBrainsMonoNF',
              fontFamilyFallback: const ['Noto Color Emoji'],
              fontSize: 13,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _fixedCommand ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied fix to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                if (_fixedCommand != null) {
                  widget.onApplyFix(_fixedCommand!);
                }
              },
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Apply Fix'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFailed(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _error ?? 'Could not analyze error',
            style: TextStyle(
              color: theme.colorScheme.outline,
              fontSize: 12,
            ),
          ),
        ),
        _DismissButton(onTap: () => setState(() => _dismissed = true)),
      ],
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        Icons.close,
        size: 16,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

enum _HealState {
  idle,
  analyzing,
  ready,
  failed,
  unavailable,
}
