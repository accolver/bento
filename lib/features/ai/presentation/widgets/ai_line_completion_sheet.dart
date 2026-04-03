// @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;

import '../../domain/entities/ai_failure.dart';
import '../../domain/entities/command_suggestion.dart';

/// Review/apply UI for explicit AI refinement of the current prompt line.
class AiLineCompletionSheet extends StatefulWidget {
  const AiLineCompletionSheet({
    required this.originalLine,
    required this.onGenerate,
    required this.onApply,
    required this.onRun,
    required this.onDismiss,
    super.key,
  });

  final String originalLine;
  final Future<Either<AIFailure, CommandSuggestion>> Function() onGenerate;
  final void Function(String command) onApply;
  final void Function(String command) onRun;
  final VoidCallback onDismiss;

  @override
  State<AiLineCompletionSheet> createState() => _AiLineCompletionSheetState();
}

class _AiLineCompletionSheetState extends State<AiLineCompletionSheet> {
  bool _loading = true;
  AIFailure? _error;
  CommandSuggestion? _suggestion;
  String? _selectedCommand;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await widget.onGenerate();
    if (!mounted) return;

    result.match(
      (AIFailure failure) => setState(() {
        _loading = false;
        _error = failure;
      }),
      (CommandSuggestion suggestion) => setState(() {
        _loading = false;
        _suggestion = suggestion;
        _selectedCommand = suggestion.command;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              Row(
                children: [
                  const Icon(Icons.auto_awesome),
                  const SizedBox(width: 8),
                  const Text(
                    'Refine Command',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Current line',
                child: SelectableText(
                  widget.originalLine,
                  key: const Key('current-line'),
                  style: const TextStyle(fontFamily: 'JetBrainsMonoNF'),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _SectionCard(
                  title: 'Unable to refine command',
                  child: Text(_error!.message, key: const Key('error-text')),
                )
              else if (_suggestion != null) ...[
                _SectionCard(
                  title: 'Suggested command',
                  child: SelectableText(
                    _selectedCommand ?? _suggestion!.command,
                    key: const Key('suggested-command'),
                    style: const TextStyle(fontFamily: 'JetBrainsMonoNF'),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Why',
                  child: Text(_suggestion!.explanation),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(_suggestion!.confidence * 100).round()}% '
                  '• ${_suggestion!.privacyMode.name}',
                  key: const Key('confidence-text'),
                ),
                if (_suggestion!.alternatives.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Alternatives', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestion!.alternatives.map((alternative) {
                      final selected = alternative == _selectedCommand;
                      return ChoiceChip(
                        label: Text(alternative),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCommand = alternative;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onDismiss,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onApply(_selectedCommand ?? _suggestion!.command),
                        child: const Text('Apply to line'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => widget.onRun(_selectedCommand ?? _suggestion!.command),
                        child: const Text('Run'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
