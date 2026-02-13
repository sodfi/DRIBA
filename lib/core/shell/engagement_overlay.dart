import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// ENGAGEMENT OVERLAY
// Smart actions that appear based on dwell time.
// Low opacity so content is never obscured.
// Like → Save → Comment → Share → Profile
// Each fades in independently, all fade out together.
// ============================================

class EngagementOverlay extends ConsumerWidget {
  const EngagementOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagement = ref.watch(engagementProvider);
    final screen = ref.watch(currentScreenProvider);
    final accent = screen.accent;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return IgnorePointer(
      ignoring: !engagement.showLike, // Only intercept taps when actions are visible
      child: Stack(
        children: [
          // ── Right-side action column (like TikTok but transparent) ──
          Positioned(
            right: 16,
            bottom: bottomPad + 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile avatar
                _EngagementAction(
                  visible: engagement.showProfile,
                  delay: 0,
                  child: _GhostCircle(
                    size: 44,
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Icon(Icons.person, color: Colors.white.withOpacity(0.8), size: 22),
                  ),
                ),
                const SizedBox(height: 20),

                // Like
                _EngagementAction(
                  visible: engagement.showLike,
                  delay: 0,
                  child: _GhostAction(
                    icon: Icons.favorite_outline,
                    label: '',
                    accent: accent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Toggle like
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Save
                _EngagementAction(
                  visible: engagement.showSave,
                  delay: 100,
                  child: _GhostAction(
                    icon: Icons.bookmark_outline,
                    label: '',
                    accent: accent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Toggle save
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Share
                _EngagementAction(
                  visible: engagement.showShare,
                  delay: 200,
                  child: _GhostAction(
                    icon: Icons.send_outlined,
                    label: '',
                    accent: accent,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Share
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom comment prompt ──
          Positioned(
            left: 16,
            right: 80,
            bottom: bottomPad + 24,
            child: _EngagementAction(
              visible: engagement.showComment,
              delay: 0,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Open comment sheet
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.35), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Add a comment...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual engagement action with animated fade-in
class _EngagementAction extends StatefulWidget {
  final bool visible;
  final int delay; // ms delay for stagger effect
  final Widget child;

  const _EngagementAction({
    required this.visible,
    this.delay = 0,
    required this.child,
  });

  @override
  State<_EngagementAction> createState() => _EngagementActionState();
}

class _EngagementActionState extends State<_EngagementAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    if (widget.visible) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(_EngagementAction old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _controller.forward();
      });
    } else if (!widget.visible && old.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        if (_opacity.value < 0.01) return const SizedBox.shrink();
        return Opacity(
          opacity: _opacity.value * 0.65, // Max 65% opacity — never block content
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Ghost-style action button (very transparent, unobtrusive)
class _GhostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _GhostAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

/// Ghost circle button (avatar placeholder)
class _GhostCircle extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;

  const _GhostCircle({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
