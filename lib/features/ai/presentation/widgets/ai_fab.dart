// @telos L1:function:lib/features/ai/presentation/widgets:ai_fab

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';

/// Floating Action Button for accessing AI Ghostwriter.
///
/// Features:
/// - Purple/magenta gradient background
/// - Chat/AI icon
/// - Subtle pulse animation to draw attention
/// - Opens AI Ghostwriter panel on tap
class AiFab extends ConsumerStatefulWidget {
  const AiFab({
    super.key,
    required this.onPressed,
  });

  /// Callback when the FAB is pressed.
  final VoidCallback onPressed;

  @override
  ConsumerState<AiFab> createState() => _AiFabState();
}

class _AiFabState extends ConsumerState<AiFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    // Stop animation if user prefers reduced motion
    if (disableAnimations && _pulseController.isAnimating) {
      _pulseController.stop();
    } else if (!disableAnimations && !_pulseController.isAnimating) {
      _pulseController.repeat();
    }

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse effect ring
          if (!disableAnimations)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 56 + (_pulseAnimation.value * 16),
                  height: 56 + (_pulseAnimation.value * 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.aiPrimaryColor
                        .withValues(alpha: 0.3 * (1 - _pulseAnimation.value)),
                  ),
                );
              },
            ),

          // Main FAB button
          Material(
            elevation: 6,
            shadowColor: theme.aiGlowColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.aiGradientStart,
                      theme.aiGradientEnd,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.aiGlowColor,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                  semanticLabel: 'AI Assistant',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap() {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }
}
