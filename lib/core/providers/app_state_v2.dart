import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/models.dart';
import '../../shared/models/firestore_refs.dart';

// ============================================
// AUTH PROVIDERS
// ============================================

/// Current Firebase Auth user stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current auth UID (convenience)
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// ============================================
// USER PROVIDERS (typed with DribaUser)
// ============================================

/// Current user profile (full typed model)
final currentUserProvider = StreamProvider<DribaUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);

  return Db.user(uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    return DribaUser.fromDoc(doc);
  });
});

/// Any user by ID
final userByIdProvider =
    StreamProvider.family<DribaUser?, String>((ref, userId) {
  return Db.user(userId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return DribaUser.fromDoc(doc);
  });
});

/// User's enabled screens
final enabledScreensProvider = Provider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.enabledScreens ?? defaultScreens;
});

/// Default screens for new users
const List<String> defaultScreens = [
  'feed',
  'food',
  'commerce',
  'learn',
];

// ============================================
// POST PROVIDERS (typed with Post)
// ============================================

/// Posts for a specific screen/category
final screenPostsProvider =
    StreamProvider.family<List<Post>, String>((ref, screenId) {
  return Db.posts
      .where('categories', arrayContains: screenId)
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(Post.fromDoc).toList());
});

/// Trending posts across all screens
final trendingPostsProvider = StreamProvider<List<Post>>((ref) {
  return Db.posts
      .where('status', isEqualTo: 'published')
      .orderBy('engagementScore', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(Post.fromDoc).toList());
});

/// Posts by a specific user
final userPostsProvider =
    StreamProvider.family<List<Post>, String>((ref, userId) {
  return Db.posts
      .where('author.id', isEqualTo: userId)
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs.map(Post.fromDoc).toList());
});

/// Single post by ID
final postByIdProvider =
    StreamProvider.family<Post?, String>((ref, postId) {
  return Db.post(postId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return Post.fromDoc(doc);
  });
});

/// Food posts (for Food screen)
final foodPostsProvider = StreamProvider<List<Post>>((ref) {
  return Db.posts
      .where('type', isEqualTo: 'food')
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(Post.fromDoc).toList());
});

/// Product posts (for Commerce screen)
final productPostsProvider = StreamProvider<List<Post>>((ref) {
  return Db.posts
      .where('type', isEqualTo: 'product')
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(Post.fromDoc).toList());
});

// ============================================
// CHAT PROVIDERS (typed with Chat/Message)
// ============================================

/// Current selected chat ID
final selectedChatIdProvider = StateProvider<String?>((ref) => null);

/// Chat list for current user
final chatsProvider = StreamProvider<List<Chat>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);

  return Db.chats
      .where('participantIds', arrayContains: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Chat.fromDoc).toList());
});

/// Messages for a specific chat
final messagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  return Db.messages(chatId)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map(Message.fromDoc).toList());
});

/// Total unread count across all chats
final totalUnreadProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUidProvider);
  final chats = ref.watch(chatsProvider).valueOrNull ?? [];
  if (uid == null) return 0;
  return chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount(uid));
});

// ============================================
// ORDER PROVIDERS (typed with Order)
// ============================================

/// Orders as buyer
final buyerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);

  return Db.orders
      .where('buyer.id', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs.map(Order.fromDoc).toList());
});

/// Orders as seller
final sellerOrdersProvider = StreamProvider<List<Order>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);

  return Db.orders
      .where('seller.id', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs.map(Order.fromDoc).toList());
});

/// Active orders (for delivery tracking)
final activeOrdersProvider = Provider<List<Order>>((ref) {
  final buyerOrders = ref.watch(buyerOrdersProvider).valueOrNull ?? [];
  return buyerOrders.where((o) => o.isActive).toList();
});

// ============================================
// ACTIVITY PROVIDERS
// ============================================

/// User's activity feed / notifications
final activitiesProvider = StreamProvider<List<Activity>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);

  return Db.activities
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(Activity.fromDoc).toList());
});

/// Unread activity count
final unreadActivityCountProvider = Provider<int>((ref) {
  final activities = ref.watch(activitiesProvider).valueOrNull ?? [];
  return activities.where((a) => !a.isRead).length;
});

// ============================================
// NAVIGATION STATE
// ============================================

/// Current main navigation index
/// -1: Chat, 0: Feed, 1: Screens View, 2: Utility
final currentPageIndexProvider = StateProvider<int>((ref) => 0);

/// Current dock selection (synced with page index)
final currentDockIndexProvider = StateProvider<int>((ref) => 0);

/// Currently selected screen within Screens View
final selectedScreenProvider = StateProvider<String?>((ref) => null);

// ============================================
// UI STATE
// ============================================

/// Whether the dock should be visible
final dockVisibilityProvider = StateProvider<bool>((ref) => true);

/// Current bottom sheet content
final bottomSheetContentProvider = StateProvider<BottomSheetContent?>((ref) => null);

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filter state for current screen
final currentFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

// ============================================
// UTILITY STATE
// ============================================

/// Current utility module
final currentUtilityModuleProvider = StateProvider<String>((ref) => 'pos');

/// Available utility modules
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

// ============================================
// SCREEN CONFIGS (unchanged from original)
// ============================================

const List<ScreenConfig> allScreens = [
  ScreenConfig(id: 'feed', name: 'Feed', icon: 'home', color: 0xFF00E1FF),
  ScreenConfig(id: 'food', name: 'Food', icon: 'restaurant', color: 0xFFFF6B35),
  ScreenConfig(id: 'commerce', name: 'Commerce', icon: 'shopping_bag', color: 0xFFFFD700),
  ScreenConfig(id: 'travel', name: 'Travel', icon: 'flight', color: 0xFF00B4D8),
  ScreenConfig(id: 'health', name: 'Health', icon: 'favorite', color: 0xFF00D68F),
  ScreenConfig(id: 'news', name: 'News', icon: 'newspaper', color: 0xFFFF3D71),
  ScreenConfig(id: 'learn', name: 'Learn', icon: 'school', color: 0xFF8B5CF6),
  ScreenConfig(id: 'movies', name: 'Movies', icon: 'movie', color: 0xFFFF2E93),
  ScreenConfig(id: 'local', name: 'Local', icon: 'place', color: 0xFFFFAA00),
  ScreenConfig(id: 'music', name: 'Music', icon: 'music_note', color: 0xFF1DB954),
  ScreenConfig(id: 'gaming', name: 'Gaming', icon: 'sports_esports', color: 0xFF9146FF),
  ScreenConfig(id: 'sports', name: 'Sports', icon: 'sports_soccer', color: 0xFF00D68F),
  ScreenConfig(id: 'finance', name: 'Finance', icon: 'account_balance', color: 0xFF00E1FF),
  ScreenConfig(id: 'auto', name: 'Auto', icon: 'directions_car', color: 0xFFFF6B35),
  ScreenConfig(id: 'pets', name: 'Pets', icon: 'pets', color: 0xFFFFAA00),
  ScreenConfig(id: 'realestate', name: 'Real Estate', icon: 'home_work', color: 0xFF00B4D8),
  ScreenConfig(id: 'fashion', name: 'Fashion', icon: 'checkroom', color: 0xFFFF2E93),
  ScreenConfig(id: 'beauty', name: 'Beauty', icon: 'face', color: 0xFFFF6B9D),
  ScreenConfig(id: 'home', name: 'Home', icon: 'weekend', color: 0xFF8B5CF6),
  ScreenConfig(id: 'events', name: 'Events', icon: 'event', color: 0xFFFFD700),
  ScreenConfig(id: 'kids', name: 'Kids', icon: 'child_care', color: 0xFF00D68F),
];

// ============================================
// DATA CLASSES (kept for compatibility)
// ============================================

class ScreenConfig {
  final String id;
  final String name;
  final String icon;
  final int color;

  const ScreenConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class UtilityModule {
  final String id;
  final String name;
  final String icon;

  const UtilityModule({
    required this.id,
    required this.name,
    required this.icon,
  });
}

enum BottomSheetContent {
  search,
  filters,
  profile,
  settings,
  create,
  comments,
  share,
}
