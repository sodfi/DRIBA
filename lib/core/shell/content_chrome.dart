import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// CONTENT CHROME v3
//
// Tap-to-show/auto-hide overlay.
// Top: screen name pill + profile + create
// Bottom: action icons (like, comment, save, share)
//    ↑ These are the fallback for missed timed actions
// Auto-hides after 3.5s.
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
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isVisible = chromeState == ChromeState.visible;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: Stack(
          children: [
            // ── Top bar: screen name + profile + create ──
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
                          color: Colors.black.withOpacity(0.3),
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
                  _ChromeButton(icon: Icons.add, onTap: onCreateTap, accent: screen.accent, filled: true),
                  const SizedBox(width: 8),
                  _ChromeButton(icon: Icons.person_outline, onTap: onProfileTap),
                ],
              ),
            ),

            // ── Bottom: Action icons (fallback for missed timed actions) ──
            if (shell.isViewingPost)
              Positioned(
                bottom: bottomPad + 66,
                left: 0,
                right: 0,
                child: _ChromeActionBar(
                  postId: shell.currentPostId,
                  accent: screen.accent,
                ),
              ),

            // ── Screen indicator dots ──
            Positioned(
              bottom: bottomPad + 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(shell.screenOrder.length, (i) {
                  final isCurrent = shell.screenOrder[i] == screen;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isCurrent ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isCurrent ? screen.accent.withOpacity(0.9) : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action bar: like, comment, save, share (fallback for timed engagement) ──

class _ChromeActionBar extends StatefulWidget {
  final String? postId;
  final Color accent;
  const _ChromeActionBar({required this.postId, required this.accent});
  @override
  State<_ChromeActionBar> createState() => _ChromeActionBarState();
}

class _ChromeActionBarState extends State<_ChromeActionBar> {
  bool _liked = false;
  bool _saved = false;

  bool _isAnonymous() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  void _showSignUpPrompt() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DribaColors.primary.withOpacity(0.15)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_add_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 16),
                const Text('Join Driba', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Create a free account to interact.', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(gradient: DribaColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Maybe later', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _doAction(String field, {bool toggle = false, bool? toggleState}) {
    HapticFeedback.mediumImpact();
    if (_isAnonymous()) { _showSignUpPrompt(); return; }
    if (widget.postId == null) return;
    if (toggle && toggleState == true) {
      try { FirebaseFirestore.instance.collection('posts').doc(widget.postId!).update({field: FieldValue.increment(1)}); } catch (_) {}
    } else if (!toggle) {
      try { FirebaseFirestore.instance.collection('posts').doc(widget.postId!).update({field: FieldValue.increment(1)}); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIcon(
                  icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _liked ? const Color(0xFFFF2D55) : Colors.white.withOpacity(0.7),
                  onTap: () { setState(() => _liked = !_liked); _doAction('likes', toggle: true, toggleState: _liked); },
                ),
                const SizedBox(width: 28),
                _ActionIcon(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.white.withOpacity(0.7),
                  onTap: () => _doAction('comments'),
                ),
                const SizedBox(width: 28),
                _ActionIcon(
                  icon: _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _saved ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.7),
                  onTap: () { setState(() => _saved = !_saved); _doAction('saves', toggle: true, toggleState: _saved); },
                ),
                const SizedBox(width: 28),
                _ActionIcon(
                  icon: Icons.send_rounded,
                  color: Colors.white.withOpacity(0.7),
                  onTap: () => _doAction('shares'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Icon(icon, color: color, size: 26));
  }
}

// ── Glass chrome button ──

class _ChromeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;
  final bool filled;
  const _ChromeButton({required this.icon, required this.onTap, this.accent, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: filled ? (accent ?? Colors.white).withOpacity(0.2) : Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: filled ? (accent ?? Colors.white).withOpacity(0.3) : Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: filled ? Colors.white : Colors.white.withOpacity(0.7), size: 20),
          ),
        ),
      ),
    );
  }
}
