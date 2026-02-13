import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/driba_colors.dart';
import 'core/shell/shell_state.dart';
import 'core/shell/engagement_overlay.dart';
import 'core/shell/content_chrome.dart';
import 'core/shell/masonry_overview.dart';

// Module imports
import 'modules/chat/chat_list_screen.dart';
import 'modules/feed/feed_screen.dart';
import 'modules/news/news_screen.dart';
import 'modules/food/food_screen.dart';
import 'modules/travel/travel_screen.dart';
import 'modules/commerce/commerce_screen.dart';
import 'modules/health/health_screen.dart';
import 'modules/utility/utility_screen.dart';
import 'modules/learn/learn_screen.dart';
import 'modules/profile/profile_screen.dart';
import 'modules/creator/creator_screen.dart';

// ============================================
// MAIN SHELL
// Root navigation — the OS itself.
//
// Architecture:
// ┌──────────────────────────────────┐
// │        Masonry Overlay           │ ← Long-press (above everything)
// │  ┌────────────────────────────┐  │
// │  │    Content Chrome          │  │ ← Tap-to-show nav (auto-hides)
// │  │  ┌──────────────────────┐  │  │
// │  │  │ Engagement Overlay   │  │  │ ← Dwell-time smart actions
// │  │  │  ┌────────────────┐  │  │  │
// │  │  │  │  SCREEN        │  │  │  │ ← PageView (horizontal swipe)
// │  │  │  │  (full-screen) │  │  │  │
// │  │  │  └────────────────┘  │  │  │
// │  │  └──────────────────────┘  │  │
// │  └────────────────────────────┘  │
// └──────────────────────────────────┘
//
// NO permanent bottom nav bar.
// Content is king. Everything else is transient.
// ============================================

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final shell = ref.read(shellProvider);
    _pageController = PageController(
      initialPage: shell.currentIndex.clamp(0, shell.screenOrder.length - 1),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Resolve DribaScreen enum → actual Widget
  Widget _resolveScreen(DribaScreen screen) {
    switch (screen) {
      case DribaScreen.chat:
        return const ChatListScreen();
      case DribaScreen.feed:
        return const FeedScreen();
      case DribaScreen.news:
        return const NewsScreen();
      case DribaScreen.food:
        return const FoodScreen();
      case DribaScreen.travel:
        return const TravelScreen();
      case DribaScreen.commerce:
        return const CommerceScreen();
      case DribaScreen.health:
        return const HealthScreen();
      case DribaScreen.utility:
        return const UtilityScreen();
      case DribaScreen.learn:
        return const LearnScreen();
      default:
        // Placeholder for add-on screens not yet built
        return _ComingSoonScreen(screen: screen);
    }
  }

  void _onPageChanged(int index) {
    final screenOrder = ref.read(shellProvider).screenOrder;
    if (index >= 0 && index < screenOrder.length) {
      HapticFeedback.selectionClick();
      ref.read(shellProvider.notifier).goToScreen(screenOrder[index]);
    }
  }

  void _navigateToScreen(DribaScreen screen) {
    final screenOrder = ref.read(shellProvider).screenOrder;
    final index = screenOrder.indexOf(screen);
    if (index >= 0) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTap() {
    ref.read(shellProvider.notifier).toggleChrome();
  }

  void _onLongPress() {
    ref.read(shellProvider.notifier).openMasonry();
  }

  void _openProfile() {
    ref.read(shellProvider.notifier).hideChrome();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProfileScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _openCreator() {
    ref.read(shellProvider.notifier).hideChrome();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreatorScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(shellProvider);
    final screenOrder = shell.screenOrder;

    // Full immersive - no system UI chrome
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: DribaColors.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Screen Content (PageView) ──
          GestureDetector(
            onTap: _onTap,
            onLongPress: _onLongPress,
            behavior: HitTestBehavior.translucent,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemCount: screenOrder.length,
              itemBuilder: (context, index) {
                return _resolveScreen(screenOrder[index]);
              },
            ),
          ),

          // ── Layer 2: Engagement Overlay ──
          // Smart dwell-time actions (low opacity, never blocks content)
          const EngagementOverlay(),

          // ── Layer 3: Content Chrome ──
          // Tap-to-show: screen name, nav dots, profile, create
          ContentChrome(
            onProfileTap: _openProfile,
            onCreateTap: _openCreator,
            pageController: _pageController,
          ),

          // ── Layer 4: Masonry Overview ──
          // Long-press: Pinterest grid of all screens
          if (shell.isMasonryOpen)
            MasonryOverview(
              onDismiss: () {
                ref.read(shellProvider.notifier).closeMasonry();
              },
              onScreenTap: (screen) {
                ref.read(shellProvider.notifier).closeMasonry(navigateTo: screen);
                _navigateToScreen(screen);
              },
            ),
        ],
      ),
    );
  }
}

// ── Coming Soon placeholder for add-on screens ──
class _ComingSoonScreen extends StatelessWidget {
  final DribaScreen screen;
  const _ComingSoonScreen({required this.screen});

  @override
  Widget build(BuildContext context) {
    final accent = screen.accent;
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(screen.emoji, style: const TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text(
              screen.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
