import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================
// SHELL STATE
// Core navigation + chrome visibility +
// engagement sensing + masonry mode
//
// 8 STANDARD SCREENS (non-negotiable):
// Chat, Feed, News, Food, Travel, Commerce, Health, Utility
// ============================================

/// The 8 standard screens + optional add-ons
enum DribaScreen {
  chat,
  feed,
  news,
  food,
  travel,
  commerce,
  health,
  utility,
  // ── Optional (added via onboarding) ──
  learn,
  art,
  music,
  gaming,
  fitness,
  finance,
  dating,
}

extension DribaScreenInfo on DribaScreen {
  String get id => name;

  /// Whether this is a standard (non-negotiable) screen
  bool get isStandard => standardScreens.contains(this);

  String get label {
    switch (this) {
      case DribaScreen.chat: return 'Chat';
      case DribaScreen.feed: return 'Feed';
      case DribaScreen.news: return 'News';
      case DribaScreen.food: return 'Food';
      case DribaScreen.travel: return 'Travel';
      case DribaScreen.commerce: return 'Commerce';
      case DribaScreen.health: return 'Health';
      case DribaScreen.utility: return 'Utility';
      case DribaScreen.learn: return 'Learn';
      case DribaScreen.art: return 'Art';
      case DribaScreen.music: return 'Music';
      case DribaScreen.gaming: return 'Gaming';
      case DribaScreen.fitness: return 'Fitness';
      case DribaScreen.finance: return 'Finance';
      case DribaScreen.dating: return 'Dating';
    }
  }

  String get emoji {
    switch (this) {
      case DribaScreen.chat: return '💬';
      case DribaScreen.feed: return '🏠';
      case DribaScreen.news: return '📰';
      case DribaScreen.food: return '🍽️';
      case DribaScreen.travel: return '✈️';
      case DribaScreen.commerce: return '🛍️';
      case DribaScreen.health: return '💚';
      case DribaScreen.utility: return '⚡';
      case DribaScreen.learn: return '📚';
      case DribaScreen.art: return '🎨';
      case DribaScreen.music: return '🎵';
      case DribaScreen.gaming: return '🎮';
      case DribaScreen.fitness: return '💪';
      case DribaScreen.finance: return '💰';
      case DribaScreen.dating: return '💘';
    }
  }

  IconData get icon {
    switch (this) {
      case DribaScreen.chat: return Icons.chat_bubble_outline;
      case DribaScreen.feed: return Icons.home_outlined;
      case DribaScreen.news: return Icons.newspaper_outlined;
      case DribaScreen.food: return Icons.restaurant_outlined;
      case DribaScreen.travel: return Icons.flight_outlined;
      case DribaScreen.commerce: return Icons.shopping_bag_outlined;
      case DribaScreen.health: return Icons.favorite_outline;
      case DribaScreen.utility: return Icons.bolt_outlined;
      case DribaScreen.learn: return Icons.school_outlined;
      case DribaScreen.art: return Icons.brush_outlined;
      case DribaScreen.music: return Icons.music_note_outlined;
      case DribaScreen.gaming: return Icons.sports_esports_outlined;
      case DribaScreen.fitness: return Icons.fitness_center_outlined;
      case DribaScreen.finance: return Icons.account_balance_wallet_outlined;
      case DribaScreen.dating: return Icons.favorite_border;
    }
  }

  IconData get iconFilled {
    switch (this) {
      case DribaScreen.chat: return Icons.chat_bubble;
      case DribaScreen.feed: return Icons.home;
      case DribaScreen.news: return Icons.newspaper;
      case DribaScreen.food: return Icons.restaurant;
      case DribaScreen.travel: return Icons.flight;
      case DribaScreen.commerce: return Icons.shopping_bag;
      case DribaScreen.health: return Icons.favorite;
      case DribaScreen.utility: return Icons.bolt;
      case DribaScreen.learn: return Icons.school;
      case DribaScreen.art: return Icons.brush;
      case DribaScreen.music: return Icons.music_note;
      case DribaScreen.gaming: return Icons.sports_esports;
      case DribaScreen.fitness: return Icons.fitness_center;
      case DribaScreen.finance: return Icons.account_balance_wallet;
      case DribaScreen.dating: return Icons.favorite;
    }
  }

  Color get accent {
    switch (this) {
      case DribaScreen.chat: return const Color(0xFF00E1FF);
      case DribaScreen.feed: return const Color(0xFF00E1FF);
      case DribaScreen.news: return const Color(0xFFFF3D71);
      case DribaScreen.food: return const Color(0xFFFF6B35);
      case DribaScreen.travel: return const Color(0xFF00B4D8);
      case DribaScreen.commerce: return const Color(0xFFFFD700);
      case DribaScreen.health: return const Color(0xFF00D68F);
      case DribaScreen.utility: return const Color(0xFF8B5CF6);
      case DribaScreen.learn: return const Color(0xFF8B5CF6);
      case DribaScreen.art: return const Color(0xFFFFAA00);
      case DribaScreen.music: return const Color(0xFF1DB954);
      case DribaScreen.gaming: return const Color(0xFF9146FF);
      case DribaScreen.fitness: return const Color(0xFF2DD4BF);
      case DribaScreen.finance: return const Color(0xFF10B981);
      case DribaScreen.dating: return const Color(0xFFFF2E93);
    }
  }
}

/// The 8 non-negotiable standard screens
const List<DribaScreen> standardScreens = [
  DribaScreen.chat,
  DribaScreen.feed,
  DribaScreen.news,
  DribaScreen.food,
  DribaScreen.travel,
  DribaScreen.commerce,
  DribaScreen.health,
  DribaScreen.utility,
];

/// Optional screens the user can add during onboarding
const List<DribaScreen> optionalScreens = [
  DribaScreen.learn,
  DribaScreen.art,
  DribaScreen.music,
  DribaScreen.gaming,
  DribaScreen.fitness,
  DribaScreen.finance,
  DribaScreen.dating,
];

/// Chrome visibility state
enum ChromeState {
  hidden,     // Content only — default
  visible,    // User tapped — show all chrome
  engagement, // Dwell-time smart actions appearing
}

/// Which engagement actions are currently visible
class EngagementState {
  final bool showLike;
  final bool showSave;
  final bool showComment;
  final bool showShare;
  final bool showProfile;

  const EngagementState({
    this.showLike = false,
    this.showSave = false,
    this.showComment = false,
    this.showShare = false,
    this.showProfile = false,
  });

  static const hidden = EngagementState();
}

/// Complete shell state
class ShellState {
  final DribaScreen currentScreen;
  final List<DribaScreen> screenOrder;
  final ChromeState chromeState;
  final EngagementState engagement;
  final bool isMasonryOpen;
  final bool isTransitioning;

  const ShellState({
    this.currentScreen = DribaScreen.feed,
    this.screenOrder = const [
      DribaScreen.chat,
      DribaScreen.feed,
      DribaScreen.news,
      DribaScreen.food,
      DribaScreen.travel,
      DribaScreen.commerce,
      DribaScreen.health,
      DribaScreen.utility,
    ],
    this.chromeState = ChromeState.hidden,
    this.engagement = EngagementState.hidden,
    this.isMasonryOpen = false,
    this.isTransitioning = false,
  });

  int get currentIndex => screenOrder.indexOf(currentScreen);

  ShellState copyWith({
    DribaScreen? currentScreen,
    List<DribaScreen>? screenOrder,
    ChromeState? chromeState,
    EngagementState? engagement,
    bool? isMasonryOpen,
    bool? isTransitioning,
  }) {
    return ShellState(
      currentScreen: currentScreen ?? this.currentScreen,
      screenOrder: screenOrder ?? this.screenOrder,
      chromeState: chromeState ?? this.chromeState,
      engagement: engagement ?? this.engagement,
      isMasonryOpen: isMasonryOpen ?? this.isMasonryOpen,
      isTransitioning: isTransitioning ?? this.isTransitioning,
    );
  }
}

/// Shell state notifier — manages all shell behavior
class ShellNotifier extends StateNotifier<ShellState> {
  Timer? _chromeHideTimer;
  Timer? _engageLikeTimer;
  Timer? _engageSaveTimer;
  Timer? _engageCommentTimer;
  Timer? _engageShareTimer;
  Timer? _engageProfileTimer;
  Timer? _engageFadeTimer;
  DateTime _lastContentChange = DateTime.now();

  ShellNotifier() : super(const ShellState());

  /// Navigate to a specific screen
  void goToScreen(DribaScreen screen) {
    _cancelAllTimers();
    state = state.copyWith(
      currentScreen: screen,
      chromeState: ChromeState.hidden,
      engagement: EngagementState.hidden,
      isMasonryOpen: false,
    );
    _lastContentChange = DateTime.now();
    _startEngagementTimers();
  }

  /// User tapped the screen — toggle chrome
  void toggleChrome() {
    if (state.chromeState == ChromeState.visible) {
      hideChrome();
    } else {
      showChrome();
    }
  }

  /// Show chrome overlay (tap or gesture)
  void showChrome() {
    _chromeHideTimer?.cancel();
    state = state.copyWith(chromeState: ChromeState.visible);
    // Auto-hide chrome after 3.5s of inactivity
    _chromeHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (state.chromeState == ChromeState.visible) {
        hideChrome();
      }
    });
  }

  /// Hide chrome
  void hideChrome() {
    _chromeHideTimer?.cancel();
    state = state.copyWith(chromeState: ChromeState.hidden);
  }

  /// Content changed (new post in feed, new card swiped)
  /// Resets engagement timers
  void onContentChanged() {
    _cancelEngagementTimers();
    _lastContentChange = DateTime.now();
    state = state.copyWith(engagement: EngagementState.hidden);
    _startEngagementTimers();
  }

  /// Start engagement sensing timers
  /// Like → Save → Comment → Share → Profile (then all fade)
  void _startEngagementTimers() {
    _cancelEngagementTimers();

    // Like appears after 3s
    _engageLikeTimer = Timer(const Duration(seconds: 3), () {
      if (_isStillOnSameContent()) {
        state = state.copyWith(
          engagement: EngagementState(showLike: true),
          chromeState: ChromeState.engagement,
        );
      }
    });

    // Save appears after 5s
    _engageSaveTimer = Timer(const Duration(seconds: 5), () {
      if (_isStillOnSameContent()) {
        state = state.copyWith(
          engagement: EngagementState(showLike: true, showSave: true),
        );
      }
    });

    // Comment appears after 8s
    _engageCommentTimer = Timer(const Duration(seconds: 8), () {
      if (_isStillOnSameContent()) {
        state = state.copyWith(
          engagement: EngagementState(
            showLike: true, showSave: true, showComment: true,
          ),
        );
      }
    });

    // Share appears after 11s
    _engageShareTimer = Timer(const Duration(seconds: 11), () {
      if (_isStillOnSameContent()) {
        state = state.copyWith(
          engagement: EngagementState(
            showLike: true, showSave: true,
            showComment: true, showShare: true,
          ),
        );
      }
    });

    // Profile appears after 14s
    _engageProfileTimer = Timer(const Duration(seconds: 14), () {
      if (_isStillOnSameContent()) {
        state = state.copyWith(
          engagement: EngagementState(
            showLike: true, showSave: true,
            showComment: true, showShare: true,
            showProfile: true,
          ),
        );
      }
    });

    // All engagement fades after 20s
    _engageFadeTimer = Timer(const Duration(seconds: 20), () {
      state = state.copyWith(
        engagement: EngagementState.hidden,
        chromeState: ChromeState.hidden,
      );
    });
  }

  bool _isStillOnSameContent() {
    return DateTime.now().difference(_lastContentChange).inMilliseconds > 2000;
  }

  /// Open masonry overview
  void openMasonry() {
    _cancelAllTimers();
    state = state.copyWith(
      isMasonryOpen: true,
      chromeState: ChromeState.hidden,
      engagement: EngagementState.hidden,
    );
  }

  /// Close masonry and optionally navigate
  void closeMasonry({DribaScreen? navigateTo}) {
    if (navigateTo != null) {
      state = state.copyWith(
        currentScreen: navigateTo,
        isMasonryOpen: false,
      );
    } else {
      state = state.copyWith(isMasonryOpen: false);
    }
    _startEngagementTimers();
  }

  /// Reorder screens (from masonry drag)
  void reorderScreens(int oldIndex, int newIndex) {
    final list = [...state.screenOrder];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(screenOrder: list);
  }

  void _cancelEngagementTimers() {
    _engageLikeTimer?.cancel();
    _engageSaveTimer?.cancel();
    _engageCommentTimer?.cancel();
    _engageShareTimer?.cancel();
    _engageProfileTimer?.cancel();
    _engageFadeTimer?.cancel();
  }

  void _cancelAllTimers() {
    _chromeHideTimer?.cancel();
    _cancelEngagementTimers();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}

// ── PROVIDERS ─────────────────────────────────

final shellProvider = StateNotifierProvider<ShellNotifier, ShellState>(
  (ref) => ShellNotifier(),
);

final currentScreenProvider = Provider<DribaScreen>((ref) {
  return ref.watch(shellProvider).currentScreen;
});

final chromeStateProvider = Provider<ChromeState>((ref) {
  return ref.watch(shellProvider).chromeState;
});

final engagementProvider = Provider<EngagementState>((ref) {
  return ref.watch(shellProvider).engagement;
});

final isMasonryOpenProvider = Provider<bool>((ref) {
  return ref.watch(shellProvider).isMasonryOpen;
});

final screenOrderProvider = Provider<List<DribaScreen>>((ref) {
  return ref.watch(shellProvider).screenOrder;
});
