import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/driba_colors.dart';
import 'core/shell/shell_state.dart';
import 'core/shell/content_chrome.dart';
import 'core/shell/engagement_overlay.dart';
import 'core/shell/masonry_overview.dart';

import 'modules/chat/chat_screen.dart';
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
// MAIN SHELL v2
//
// Changes:
// - iOS-style glassmorphic bottom nav bar
// - Persistent tab icons (Home, Discover, Create, Chat, Profile)
// - Horizontal swipe still works between content screens
// - No more engagement overlay (actions live on post cards now)
// - Double-tap to like handled by post cards
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

  Widget _resolveScreen(DribaScreen screen) {
    switch (screen) {
      case DribaScreen.chat:
        return const ChatScreen();
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
      _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProfileScreen(),
        transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _openCreator() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreatorScreen(),
        transitionsBuilder: (_, anim, __, child) =>
          SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _onLongPress() {
    ref.read(shellProvider.notifier).openMasonry();
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(shellProvider);
    final screenOrder = shell.screenOrder;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: DribaColors.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Screen PageView ──
          GestureDetector(
            onTap: () => ref.read(shellProvider.notifier).toggleChrome(),
            onLongPress: _onLongPress,
            behavior: HitTestBehavior.translucent,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemCount: screenOrder.length,
              itemBuilder: (context, index) => _resolveScreen(screenOrder[index]),
            ),
          ),

          // ── Layer 2: Engagement Overlay (timed actions) ──
          const EngagementOverlay(),

          // ── Layer 3: Content Chrome (tap-to-show with action fallbacks) ──
          ContentChrome(
            onProfileTap: _openProfile,
            onCreateTap: _openCreator,
            pageController: _pageController,
          ),

          // ── Layer 4: Bottom Nav Bar (iOS-style) ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomNavBar(
              currentScreen: shell.currentScreen,
              screenOrder: screenOrder,
              onHomeTap: () => _navigateToScreen(DribaScreen.feed),
              onChatTap: () => _navigateToScreen(DribaScreen.chat),
              onCreateTap: _openCreator,
              onDiscoverTap: () {
                ref.read(shellProvider.notifier).openMasonry();
              },
              onProfileTap: _openProfile,
              bottomPad: bottomPad,
            ),
          ),

          // ── Layer 5: Masonry Overview ──
          if (shell.isMasonryOpen)
            MasonryOverview(
              onDismiss: () => ref.read(shellProvider.notifier).closeMasonry(),
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

// ============================================
// iOS-STYLE BOTTOM NAV BAR
// Glassmorphic, 5 tabs, always visible
// ============================================

class _BottomNavBar extends StatelessWidget {
  final DribaScreen currentScreen;
  final List<DribaScreen> screenOrder;
  final VoidCallback onHomeTap;
  final VoidCallback onChatTap;
  final VoidCallback onCreateTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onProfileTap;
  final double bottomPad;

  const _BottomNavBar({
    required this.currentScreen,
    required this.screenOrder,
    required this.onHomeTap,
    required this.onChatTap,
    required this.onCreateTap,
    required this.onDiscoverTap,
    required this.onProfileTap,
    required this.bottomPad,
  });

  bool get _isHome => currentScreen == DribaScreen.feed ||
      currentScreen == DribaScreen.news ||
      currentScreen == DribaScreen.food ||
      currentScreen == DribaScreen.travel ||
      currentScreen == DribaScreen.commerce ||
      currentScreen == DribaScreen.health ||
      currentScreen == DribaScreen.utility;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.only(top: 8, bottom: bottomPad + 6, left: 8, right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF050B14).withOpacity(0.75),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _isHome,
                onTap: () { HapticFeedback.selectionClick(); onHomeTap(); },
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Discover',
                isActive: false,
                onTap: () { HapticFeedback.selectionClick(); onDiscoverTap(); },
              ),
              // Create button (center, larger)
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); onCreateTap(); },
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: DribaColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: DribaColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                ),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                isActive: currentScreen == DribaScreen.chat,
                onTap: () { HapticFeedback.selectionClick(); onChatTap(); },
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: false,
                onTap: () { HapticFeedback.selectionClick(); onProfileTap(); },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? DribaColors.primary : Colors.white.withOpacity(0.4), size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: isActive ? DribaColors.primary : Colors.white.withOpacity(0.35),
              fontSize: 10, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  final DribaScreen screen;
  const _ComingSoonScreen({required this.screen});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(screen.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(screen.label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Coming soon', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
