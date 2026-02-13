import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// ENGAGEMENT OVERLAY — v2
// One action visible at a time. Slow fade in/out.
// Hidden on Chat screen (chat has its own input).
// Comment field appears prefilled with AI suggestion.
// ============================================

class EngagementOverlay extends ConsumerWidget {
  const EngagementOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagement = ref.watch(engagementProvider);
    final screen = ref.watch(currentScreenProvider);
    final accent = screen.accent;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Hide engagement on Chat screen — it has its own input field
    if (screen == DribaScreen.chat) return const SizedBox.shrink();

    return Stack(
      children: [
        // ── Right-side: single action icon ──
        Positioned(
          right: 16,
          bottom: bottomPad + 120,
          child: _SingleActionIcon(
            engagement: engagement,
            accent: accent,
          ),
        ),

        // ── Bottom: prefilled comment field (only when comment action is active) ──
        Positioned(
          left: 16,
          right: 80,
          bottom: bottomPad + 24,
          child: _PrefillCommentBar(
            visible: engagement.showComment,
          ),
        ),
      ],
    );
  }
}

/// Shows exactly ONE icon at a time with slow cross-fade
class _SingleActionIcon extends StatelessWidget {
  final EngagementState engagement;
  final Color accent;

  const _SingleActionIcon({required this.engagement, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: engagement.isVisible
            ? _buildAction(engagement.activeAction, accent)
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildAction(EngagementAction action, Color accent) {
    final config = _actionConfig(action);
    return GestureDetector(
      key: ValueKey(action),
      onTap: () => HapticFeedback.mediumImpact(),
      child: Opacity(
        opacity: 0.6,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(config.$1, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  (IconData, String) _actionConfig(EngagementAction action) {
    switch (action) {
      case EngagementAction.like:
        return (Icons.favorite_outline, 'Like');
      case EngagementAction.save:
        return (Icons.bookmark_outline, 'Save');
      case EngagementAction.comment:
        return (Icons.chat_bubble_outline, 'Comment');
      case EngagementAction.share:
        return (Icons.send_outlined, 'Share');
      case EngagementAction.profile:
        return (Icons.person_outline, 'Profile');
      case EngagementAction.none:
        return (Icons.circle, '');
    }
  }
}

/// Prefilled comment bar — appears during comment phase
class _PrefillCommentBar extends StatefulWidget {
  final bool visible;
  const _PrefillCommentBar({required this.visible});

  @override
  State<_PrefillCommentBar> createState() => _PrefillCommentBarState();
}

class _PrefillCommentBarState extends State<_PrefillCommentBar> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'Love this! 🔥',
    'This is amazing ✨',
    'So inspiring 💡',
    'Need this in my life 🙌',
    'Incredible work 👏',
  ];

  int _suggestionIndex = 0;

  @override
  void didUpdateWidget(covariant _PrefillCommentBar old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length;
      _controller.text = _suggestions[_suggestionIndex];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: widget.visible
          ? _buildBar()
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildBar() {
    return ClipRRect(
      key: const ValueKey('comment_bar'),
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _controller.clear();
                  // TODO: submit comment to Firestore
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: DribaColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
