import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// CONTENT CHROME
// Tap-to-show/auto-hide overlays.
// Shows: screen name, nav dots, profile, create.
// Hidden by default. Content is king.
//
// Netflix/YouTube behavior:
// - Tap anywhere → show chrome → auto-hide 3.5s
// - Tap again → hide immediately
// - Swipe between screens → brief flash then hide
// ============================================

class ContentChrome extends ConsumerWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onCreateTap;
  final PageController pageController;

  const ContentChrome({
    super.key,
    required this.onProfileTap,
    required this.onCreateTap,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chromeState = ref.watch(chromeStateProvider);
    final shell = ref.watch(shellProvider);
    final screen = shell.currentScreen;
    final screenOrder = shell.screenOrder;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final isVisible = chromeState == ChromeState.visible;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            // ── Top bar: screen name + profile ──
            Positioned(
              top: topPad + 8,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Screen name pill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(screen.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              screen.label,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Create button
                  _ChromeButton(
                    icon: Icons.add,
                    onTap: onCreateTap,
                    accent: screen.accent,
                    filled: true,
                  ),
                  const SizedBox(width: 8),
                  // Profile
                  _ChromeButton(
                    icon: Icons.person_outline,
                    onTap: onProfileTap,
                  ),
                ],
              ),
            ),

            // ── Bottom: screen indicator dots + swipe hint ──
            Positioned(
              bottom: bottomPad + 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Screen dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(screenOrder.length, (i) {
                      final isCurrent = screenOrder[i] == screen;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final targetIndex = i;
                          pageController.animateToPage(
                            targetIndex,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCurrent ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? screen.accent.withOpacity(0.9)
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // Screen name labels (tiny, for orientation)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (shell.currentIndex > 0)
                        Text(
                          '← ${screenOrder[shell.currentIndex - 1].label}',
                          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(width: 20),
                      Text(
                        screen.label,
                        style: TextStyle(color: screen.accent.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 20),
                      if (shell.currentIndex < screenOrder.length - 1)
                        Text(
                          '${screenOrder[shell.currentIndex + 1].label} →',
                          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass chrome button
class _ChromeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;
  final bool filled;

  const _ChromeButton({
    required this.icon,
    required this.onTap,
    this.accent,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: filled
                  ? (accent ?? Colors.white).withOpacity(0.2)
                  : Colors.black.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: filled
                    ? (accent ?? Colors.white).withOpacity(0.3)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.white : Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
