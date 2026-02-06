// @telos L2:contract:lib/features/ai/presentation/widgets/setup_steps:complete_step

import 'package:flutter/material.dart';

/// Final step showing setup completion success.
class CompleteStep extends StatefulWidget {
  const CompleteStep({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<CompleteStep> createState() => _CompleteStepState();
}

class _CompleteStepState extends State<CompleteStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Success icon with animation
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 64,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Title
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              );
            },
            child: Column(
              children: [
                Text(
                  'AI is Ready!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the AI button to start writing commands',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onComplete,
              child: const Text('Start Using AI'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
