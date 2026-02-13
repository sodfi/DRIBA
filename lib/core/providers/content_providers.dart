import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// CONTENT PROVIDERS (v2 — Dual Ratio + Audio + AI Studio)
//
// DribaPost now carries:
//   • mediaUrlPortrait  (9:16) — mobile fullscreen
//   • mediaUrlLandscape (16:9) — desktop/tablet/landscape
//   • audioUrl          — voiceover MP3
//   • aiEnhancement     — if user used AI Studio
//
// Posts with categories: ["food","feed","health"]
// appear on ALL three screens automatically.
// ============================================================

final _db = FirebaseFirestore.instance;

/// Post model — dual-ratio aware
class DribaPost {
  final String id;
  final String author;
  final String authorName;
  final String authorAvatar;
  final String description;

  // ── Media: Dual Ratio ──────────────────────────────────
  // Legacy field — used as fallback if portrait/landscape not set
  final String mediaUrl;
  // 9:16 portrait — mobile vertical swipe view
  final String mediaUrlPortrait;
  // 16:9 landscape — desktop, tablet, landscape orientation
  final String mediaUrlLandscape;
  final String mediaType; // 'image' or 'video'

  // ── Audio voiceover ────────────────────────────────────
  final String audioUrl;
  final bool hasVoiceover;

  // ── Metadata ───────────────────────────────────────────
  final List<String> categories;
  final List<String> hashtags;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int views;
  final double engagementScore;
  final bool isAIGenerated;
  final bool isAIEnhanced;
  final String? engagementHook;
  final String? price;
  final DateTime? createdAt;
  final String status;

  DribaPost({
    required this.id,
    required this.author,
    required this.authorName,
    required this.authorAvatar,
    required this.description,
    required this.mediaUrl,
    this.mediaUrlPortrait = '',
    this.mediaUrlLandscape = '',
    this.mediaType = 'image',
    this.audioUrl = '',
    this.hasVoiceover = false,
    required this.categories,
    this.hashtags = const [],
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.views = 0,
    this.engagementScore = 0,
    this.isAIGenerated = false,
    this.isAIEnhanced = false,
    this.engagementHook,
    this.price,
    this.createdAt,
    this.status = 'published',
  });

  /// Get the best media URL for the current layout.
  /// Portrait mode on mobile → 9:16 image.
  /// Landscape/desktop → 16:9 image.
  /// Falls back to mediaUrl if specific ratio isn't available.
  String getMediaUrl({required bool isPortrait}) {
    if (isPortrait) {
      return mediaUrlPortrait.isNotEmpty ? mediaUrlPortrait : mediaUrl;
    } else {
      return mediaUrlLandscape.isNotEmpty ? mediaUrlLandscape : mediaUrl;
    }
  }

  factory DribaPost.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return DribaPost(
      id: doc.id,
      author: d['author'] as String? ?? '',
      authorName: d['authorName'] as String? ?? 'Unknown',
      authorAvatar: d['authorAvatar'] as String? ?? '',
      description: d['description'] as String? ?? '',
      // Media — dual ratio
      mediaUrl: d['mediaUrl'] as String? ?? '',
      mediaUrlPortrait: d['mediaUrlPortrait'] as String? ?? '',
      mediaUrlLandscape: d['mediaUrlLandscape'] as String? ?? '',
      mediaType: d['mediaType'] as String? ?? 'image',
      // Audio
      audioUrl: d['audioUrl'] as String? ?? '',
      hasVoiceover: d['hasVoiceover'] as bool? ?? false,
      // Standard
      categories: (d['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      hashtags: (d['hashtags'] as List<dynamic>?)?.cast<String>() ?? [],
      likes: d['likes'] as int? ?? 0,
      comments: d['comments'] as int? ?? 0,
      shares: d['shares'] as int? ?? 0,
      saves: d['saves'] as int? ?? 0,
      views: d['views'] as int? ?? 0,
      engagementScore: (d['engagementScore'] as num?)?.toDouble() ?? 0,
      isAIGenerated: d['isAIGenerated'] as bool? ?? false,
      isAIEnhanced: d['isAIEnhanced'] as bool? ?? false,
      engagementHook: d['engagementHook'] as String?,
      price: d['price']?.toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      status: d['status'] as String? ?? 'published',
    );
  }
}

// ============================================================
// PROVIDERS — Firestore streams
// ============================================================

/// Posts for a specific screen (category)
final screenPostsProvider =
    StreamProvider.family<List<DribaPost>, String>((ref, screenId) {
  return _db
      .collection('posts')
      .where('status', isEqualTo: 'published')
      .where('categories', arrayContains: screenId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(DribaPost.fromFirestore).toList());
});

/// Trending posts for a screen
final trendingPostsProvider =
    StreamProvider.family<List<DribaPost>, String>((ref, screenId) {
  return _db
      .collection('posts')
      .where('status', isEqualTo: 'published')
      .where('categories', arrayContains: screenId)
      .orderBy('engagementScore', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs.map(DribaPost.fromFirestore).toList());
});

/// All feed posts (For You)
final feedPostsProvider = StreamProvider<List<DribaPost>>((ref) {
  return _db
      .collection('posts')
      .where('status', isEqualTo: 'published')
      .where('categories', arrayContains: 'feed')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map(DribaPost.fromFirestore).toList());
});

/// Posts by a specific author
final authorPostsProvider =
    StreamProvider.family<List<DribaPost>, String>((ref, authorId) {
  return _db
      .collection('posts')
      .where('author', isEqualTo: authorId)
      .where('status', isEqualTo: 'published')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(DribaPost.fromFirestore).toList());
});
