// @telos L1:function:lib/features/ai/presentation/widgets:ai_command_suggestion

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/ai_suggestion.dart';

/// Displays an AI-generated command suggestion.
///
/// Shows:
/// - The suggested command in monospace font
/// - A confidence indicator with color coding
/// - A brief explanation of what the command does
/// - Loading state with shimmer animation
/// - Error state with retry option
class AiCommandSuggestion extends StatelessWidget {
  const AiCommandSuggestion({
    super.key,
    this.suggestion,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  /// The suggestion to display, or null if none available.
  final AiSuggestion? suggestion;

  /// Whether a suggestion is currently being generated.
  final bool isLoading;

  /// Error message if suggestion generation failed.
  final String? error;

  /// Callback when user wants to retry after error.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (error != null) {
      return _buildErrorState(context);
    }

    if (suggestion == null) {
      return const SizedBox.shrink();
    }

    return _buildSuggestionCard(context, suggestion!);
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Generating AI suggestion',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.aiSuggestionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.aiPrimaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading header with spinner
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.aiPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Generating command...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.aiPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Shimmer placeholders
            _ShimmerEffect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Command placeholder
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Explanation placeholder
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Error: ${error ?? "Failed to generate suggestion"}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                  semanticLabel: 'Error',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error ?? 'Failed to generate suggestion',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, AiSuggestion suggestion) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Suggested command: ${suggestion.command}. ${suggestion.explanation}. Confidence: ${suggestion.confidencePercent}',
      child: Container(
        decoration: BoxDecoration(
          color: theme.aiSuggestionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.aiPrimaryColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.aiGlowColor,
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and confidence
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'SUGGESTED COMMAND',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.aiPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  _buildConfidenceBadge(context, suggestion),
                ],
              ),
            ),

            // Command display
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                suggestion.command,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMonoNF',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),

            // Explanation
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.aiPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: BorderSide(
                    color: theme.aiPrimaryColor,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: theme.aiPrimaryColor,
                    semanticLabel: 'Explanation',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, AiSuggestion suggestion) {
    final theme = Theme.of(context);

    Color badgeColor;
    if (suggestion.isHighConfidence) {
      badgeColor = theme.aiHighConfidenceColor;
    } else if (suggestion.isMediumConfidence) {
      badgeColor = theme.aiMediumConfidenceColor;
    } else {
      badgeColor = theme.aiLowConfidenceColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (suggestion.isLowConfidence) ...[
            Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: badgeColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            suggestion.confidencePercent,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple shimmer effect widget for loading states.
class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect({required this.child});

  final Widget child;

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
