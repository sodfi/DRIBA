import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================
// APP STATE — Backward-compatible providers
// Navigation now handled by shell_state.dart
// ============================================

// ── Legacy nav providers (kept for screen compat) ──
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
final currentDockIndexProvider = StateProvider<int>((ref) => 0);
final selectedScreenProvider = StateProvider<String?>((ref) => null);

// ── Auth ──
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .snapshots()
          .map((doc) => doc.data());
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// User's enabled screens (standard + user-selected optional)
final enabledScreensProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (data) {
      if (data == null) return defaultScreens;
      final extra = (data['enabledScreens'] as List<dynamic>?)?.cast<String>() ?? [];
      // Standard screens always included + user's optional selections
      return [...standardScreenIds, ...extra.where((s) => !standardScreenIds.contains(s))];
    },
    loading: () => defaultScreens,
    error: (_, __) => defaultScreens,
  );
});

/// 8 standard screen IDs (non-negotiable verticals)
const List<String> standardScreenIds = [
  'chat', 'feed', 'news', 'food', 'travel', 'commerce', 'health', 'utility',
];

/// Default screens = standard only (before user adds optional)
const List<String> defaultScreens = standardScreenIds;

/// All available screens (standard + optional)
const List<ScreenConfig> allScreens = [
  // Standard (non-negotiable)
  ScreenConfig(id: 'chat', name: 'Chat', icon: 'chat_bubble', color: 0xFF00E1FF, isStandard: true),
  ScreenConfig(id: 'feed', name: 'Feed', icon: 'home', color: 0xFF00E1FF, isStandard: true),
  ScreenConfig(id: 'news', name: 'News', icon: 'newspaper', color: 0xFFFF3D71, isStandard: true),
  ScreenConfig(id: 'food', name: 'Food', icon: 'restaurant', color: 0xFFFF6B35, isStandard: true),
  ScreenConfig(id: 'travel', name: 'Travel', icon: 'flight', color: 0xFF00B4D8, isStandard: true),
  ScreenConfig(id: 'commerce', name: 'Commerce', icon: 'shopping_bag', color: 0xFFFFD700, isStandard: true),
  ScreenConfig(id: 'health', name: 'Health', icon: 'favorite', color: 0xFF00D68F, isStandard: true),
  ScreenConfig(id: 'utility', name: 'Utility', icon: 'bolt', color: 0xFF8B5CF6, isStandard: true),
  // Optional (added via onboarding)
  ScreenConfig(id: 'learn', name: 'Learn', icon: 'school', color: 0xFF8B5CF6),
  ScreenConfig(id: 'art', name: 'Art', icon: 'brush', color: 0xFFFFAA00),
  ScreenConfig(id: 'music', name: 'Music', icon: 'music_note', color: 0xFF1DB954),
  ScreenConfig(id: 'gaming', name: 'Gaming', icon: 'sports_esports', color: 0xFF9146FF),
  ScreenConfig(id: 'fitness', name: 'Fitness', icon: 'fitness_center', color: 0xFF2DD4BF),
  ScreenConfig(id: 'finance', name: 'Finance', icon: 'account_balance', color: 0xFF10B981),
  ScreenConfig(id: 'dating', name: 'Dating', icon: 'favorite', color: 0xFFFF2E93),
];

// ── Chat ──
final selectedChatIdProvider = StateProvider<String?>((ref) => null);

final chatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ── Content ──
final screenPostsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, screenId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('categories', arrayContains: screenId)
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

final trendingPostsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('status', isEqualTo: 'published')
      .orderBy('engagementScore', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// ── UI State ──
final dockVisibilityProvider = StateProvider<bool>((ref) => true);
final bottomSheetContentProvider = StateProvider<BottomSheetContent?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final currentFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// ── Utility ──
final currentUtilityModuleProvider = StateProvider<String>((ref) => 'pos');

const List<UtilityModule> utilityModules = [
  UtilityModule(id: 'pos', name: 'POS', icon: 'point_of_sale'),
  UtilityModule(id: 'crm', name: 'CRM', icon: 'people'),
  UtilityModule(id: 'invoicing', name: 'Invoicing', icon: 'receipt'),
  UtilityModule(id: 'marketing', name: 'Marketing', icon: 'campaign'),
  UtilityModule(id: 'analytics', name: 'Analytics', icon: 'analytics'),
  UtilityModule(id: 'inventory', name: 'Inventory', icon: 'inventory'),
  UtilityModule(id: 'booking', name: 'Booking', icon: 'calendar_today'),
  UtilityModule(id: 'projects', name: 'Projects', icon: 'task_alt'),
  UtilityModule(id: 'team', name: 'Team', icon: 'groups'),
  UtilityModule(id: 'reports', name: 'Reports', icon: 'assessment'),
];

// ── Models ──
class ScreenConfig {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool isStandard;

  const ScreenConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isStandard = false,
  });
}

class UtilityModule {
  final String id;
  final String name;
  final String icon;
  const UtilityModule({required this.id, required this.name, required this.icon});
}

enum BottomSheetContent { search, filters, profile, settings, create, comments, share }
