import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================
// FIRESTORE COLLECTION PATHS
//
// This file documents the entire Driba OS
// database architecture. Use [Db] for typed
// collection/document references.
//
// SCHEMA OVERVIEW:
//
// /users/{userId}                          → DribaUser
//   /users/{userId}/followers/{followerId} → FollowRelation
//   /users/{userId}/following/{followedId} → FollowRelation
//   /users/{userId}/private/settings       → (private user data)
//   /users/{userId}/private/saved          → (saved post IDs)
//   /users/{userId}/private/liked          → (liked post IDs)
//   /users/{userId}/business/info          → BusinessProfile
//   /users/{userId}/business/contacts/{id} → CrmContact
//   /users/{userId}/business/inventory/{id}→ InventoryItem
//   /users/{userId}/business/invoices/{id} → Invoice
//
// /posts/{postId}                          → Post
//   /posts/{postId}/comments/{commentId}   → Comment
//
// /chats/{chatId}                          → Chat
//   /chats/{chatId}/messages/{messageId}   → Message
//
// /orders/{orderId}                        → Order
//
// /reviews/{reviewId}                      → Review
//
// /activities/{activityId}                 → Activity
//
// /campaigns/{campaignId}                  → Campaign
//
// /screens/{screenId}                      → (global screen config)
//
// /ai_creators/{creatorId}                 → (AI agent profiles)
//   /ai_creators/{creatorId}/content/{id}  → (generated content queue)
//
// /global/stats                            → (platform-wide metrics)
// /global/config                           → (feature flags, settings)
//
// /admins/{adminId}                        → (admin users)
//
// ============================================

/// Type-safe Firestore collection & document references
class Db {
  static final _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      users.doc(uid);

  static CollectionReference<Map<String, dynamic>> followers(String uid) =>
      user(uid).collection('followers');

  static CollectionReference<Map<String, dynamic>> following(String uid) =>
      user(uid).collection('following');

  static DocumentReference<Map<String, dynamic>> userPrivate(
          String uid, String docId) =>
      user(uid).collection('private').doc(docId);

  static DocumentReference<Map<String, dynamic>> businessInfo(String uid) =>
      user(uid).collection('business').doc('info');

  static CollectionReference<Map<String, dynamic>> crmContacts(String uid) =>
      user(uid).collection('business').doc('data').collection('contacts');

  static CollectionReference<Map<String, dynamic>> inventory(String uid) =>
      user(uid).collection('business').doc('data').collection('inventory');

  static CollectionReference<Map<String, dynamic>> invoices(String uid) =>
      user(uid).collection('business').doc('data').collection('invoices');

  // ── Posts ──────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get posts =>
      _db.collection('posts');

  static DocumentReference<Map<String, dynamic>> post(String postId) =>
      posts.doc(postId);

  static CollectionReference<Map<String, dynamic>> comments(String postId) =>
      post(postId).collection('comments');

  // ── Chats ──────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get chats =>
      _db.collection('chats');

  static DocumentReference<Map<String, dynamic>> chat(String chatId) =>
      chats.doc(chatId);

  static CollectionReference<Map<String, dynamic>> messages(String chatId) =>
      chat(chatId).collection('messages');

  // ── Orders ─────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get orders =>
      _db.collection('orders');

  static DocumentReference<Map<String, dynamic>> order(String orderId) =>
      orders.doc(orderId);

  // ── Reviews ────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get reviews =>
      _db.collection('reviews');

  // ── Activities ─────────────────────────────
  static CollectionReference<Map<String, dynamic>> get activities =>
      _db.collection('activities');

  // ── Campaigns ──────────────────────────────
  static CollectionReference<Map<String, dynamic>> get campaigns =>
      _db.collection('campaigns');

  // ── AI Creators ────────────────────────────
  static CollectionReference<Map<String, dynamic>> get aiCreators =>
      _db.collection('ai_creators');

  static CollectionReference<Map<String, dynamic>> aiContent(
          String creatorId) =>
      aiCreators.doc(creatorId).collection('content');

  // ── Global Config ──────────────────────────
  static DocumentReference<Map<String, dynamic>> get globalStats =>
      _db.collection('global').doc('stats');

  static DocumentReference<Map<String, dynamic>> get globalConfig =>
      _db.collection('global').doc('config');

  // ── Screens Config ─────────────────────────
  static CollectionReference<Map<String, dynamic>> get screens =>
      _db.collection('screens');

  // ── Composite Indexes Needed ───────────────
  // These indexes must be created in Firebase Console
  // or via firebase.indexes.json:
  //
  // posts: (categories ASC, status ASC, createdAt DESC)
  // posts: (categories ASC, status ASC, engagementScore DESC)
  // posts: (author.id ASC, status ASC, createdAt DESC)
  // posts: (type ASC, categories ASC, status ASC, createdAt DESC)
  // chats: (participantIds ARRAY, updatedAt DESC)
  // orders: (buyer.id ASC, status ASC, createdAt DESC)
  // orders: (seller.id ASC, status ASC, createdAt DESC)
  // activities: (userId ASC, isRead ASC, createdAt DESC)
  // reviews: (reviewee.id ASC, createdAt DESC)
}
