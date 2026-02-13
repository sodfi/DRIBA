import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_models.dart';

// ============================================
// USER MODEL
// Firestore: /users/{userId}
//
// The user profile IS their website + LinkedIn.
// Every person is both a consumer AND a potential seller.
// ============================================

class DribaUser {
  final String id; // Firebase Auth UID
  final String username; // unique handle: @username
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl; // profile cover/banner
  final String? tagline; // one-liner under name (like LinkedIn headline)

  // Contact
  final String? email;
  final String? phone;
  final Address? address;

  // Social / Web
  final List<SocialLink> socialLinks;
  final String? websiteUrl; // driba.app/@username

  // Verification & Trust
  final VerificationStatus verificationStatus;
  final double trustScore; // 0-100, calculated by engagement + reviews
  final bool isCreator; // monetizing content
  final bool isBusiness; // has business tools active

  // Screens
  final List<String> enabledScreens; // which screens they've selected
  final List<String> interests; // topic tags for feed personalization

  // Stats (denormalized for fast reads)
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int totalLikes;
  final double totalEarnings;

  // Business profile (inline for quick access, full data in subcollection)
  final BusinessMini? business;

  // Settings
  final UserSettings settings;

  // Stripe
  final String? stripeCustomerId;
  final String? stripeConnectId; // for receiving payouts

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;

  const DribaUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.tagline,
    this.email,
    this.phone,
    this.address,
    this.socialLinks = const [],
    this.websiteUrl,
    this.verificationStatus = VerificationStatus.none,
    this.trustScore = 0,
    this.isCreator = false,
    this.isBusiness = false,
    this.enabledScreens = const [],
    this.interests = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.totalLikes = 0,
    this.totalEarnings = 0,
    this.business,
    this.settings = const UserSettings(),
    this.stripeCustomerId,
    this.stripeConnectId,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
  });

  /// Create from Firestore document
  factory DribaUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DribaUser.fromMap(data, doc.id);
  }

  factory DribaUser.fromMap(Map<String, dynamic> map, [String? docId]) {
    return DribaUser(
      id: docId ?? map['id'] as String,
      username: map['username'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      bio: map['bio'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      coverUrl: map['coverUrl'] as String?,
      tagline: map['tagline'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] != null
          ? Address.fromMap(Map<String, dynamic>.from(map['address'] as Map))
          : null,
      socialLinks: toModelList(map['socialLinks'], SocialLink.fromMap),
      websiteUrl: map['websiteUrl'] as String?,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == (map['verificationStatus'] as String? ?? 'none'),
        orElse: () => VerificationStatus.none,
      ),
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0,
      isCreator: map['isCreator'] as bool? ?? false,
      isBusiness: map['isBusiness'] as bool? ?? false,
      enabledScreens: toStringList(map['enabledScreens']),
      interests: toStringList(map['interests']),
      followersCount: map['followersCount'] as int? ?? 0,
      followingCount: map['followingCount'] as int? ?? 0,
      postsCount: map['postsCount'] as int? ?? 0,
      totalLikes: map['totalLikes'] as int? ?? 0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0,
      business: map['business'] != null
          ? BusinessMini.fromMap(Map<String, dynamic>.from(map['business'] as Map))
          : null,
      settings: map['settings'] != null
          ? UserSettings.fromMap(Map<String, dynamic>.from(map['settings'] as Map))
          : const UserSettings(),
      stripeCustomerId: map['stripeCustomerId'] as String?,
      stripeConnectId: map['stripeConnectId'] as String?,
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: timestampToDateTime(map['updatedAt']) ?? DateTime.now(),
      lastActiveAt: timestampToDateTime(map['lastActiveAt']),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
        'username': username,
        'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (coverUrl != null) 'coverUrl': coverUrl,
        if (tagline != null) 'tagline': tagline,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address!.toMap(),
        'socialLinks': socialLinks.map((e) => e.toMap()).toList(),
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        'verificationStatus': verificationStatus.name,
        'trustScore': trustScore,
        'isCreator': isCreator,
        'isBusiness': isBusiness,
        'enabledScreens': enabledScreens,
        'interests': interests,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'totalLikes': totalLikes,
        'totalEarnings': totalEarnings,
        if (business != null) 'business': business!.toMap(),
        'settings': settings.toMap(),
        if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
        if (stripeConnectId != null) 'stripeConnectId': stripeConnectId,
        'createdAt': dateTimeToTimestamp(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        if (lastActiveAt != null) 'lastActiveAt': dateTimeToTimestamp(lastActiveAt),
      };

  /// Quick reference for use in posts, chats, orders
  UserRef toRef() => UserRef(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        isVerified: verificationStatus == VerificationStatus.verified,
      );

  /// Create a new user for registration
  factory DribaUser.create({
    required String id,
    required String username,
    required String displayName,
    String? email,
    String? phone,
    String? avatarUrl,
    List<String> enabledScreens = const [],
  }) {
    final now = DateTime.now();
    return DribaUser(
      id: id,
      username: username,
      displayName: displayName,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      enabledScreens: enabledScreens,
      createdAt: now,
      updatedAt: now,
      lastActiveAt: now,
    );
  }

  DribaUser copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? tagline,
    String? email,
    String? phone,
    Address? address,
    List<SocialLink>? socialLinks,
    String? websiteUrl,
    VerificationStatus? verificationStatus,
    double? trustScore,
    bool? isCreator,
    bool? isBusiness,
    List<String>? enabledScreens,
    List<String>? interests,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    int? totalLikes,
    double? totalEarnings,
    BusinessMini? business,
    UserSettings? settings,
    String? stripeCustomerId,
    String? stripeConnectId,
    DateTime? lastActiveAt,
  }) {
    return DribaUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      tagline: tagline ?? this.tagline,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      socialLinks: socialLinks ?? this.socialLinks,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      trustScore: trustScore ?? this.trustScore,
      isCreator: isCreator ?? this.isCreator,
      isBusiness: isBusiness ?? this.isBusiness,
      enabledScreens: enabledScreens ?? this.enabledScreens,
      interests: interests ?? this.interests,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      totalLikes: totalLikes ?? this.totalLikes,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      business: business ?? this.business,
      settings: settings ?? this.settings,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeConnectId: stripeConnectId ?? this.stripeConnectId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

// ============================================
// USER REF - Lightweight reference embedded in
// posts, comments, orders, chats, etc.
// ============================================

class UserRef {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;

  const UserRef({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory UserRef.fromMap(Map<String, dynamic> map) => UserRef(
        id: map['id'] as String,
        username: map['username'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String?,
        isVerified: map['isVerified'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'isVerified': isVerified,
      };
}

// ============================================
// BUSINESS MINI - Inline summary on user profile
// Full business data in /users/{id}/business/info
// ============================================

class BusinessMini {
  final String name;
  final String? category; // restaurant, freelancer, shop, service, etc.
  final String? logoUrl;
  final RatingInfo rating;
  final bool isOpen;

  const BusinessMini({
    required this.name,
    this.category,
    this.logoUrl,
    this.rating = const RatingInfo(),
    this.isOpen = true,
  });

  factory BusinessMini.fromMap(Map<String, dynamic> map) => BusinessMini(
        name: map['name'] as String,
        category: map['category'] as String?,
        logoUrl: map['logoUrl'] as String?,
        rating: map['rating'] != null
            ? RatingInfo.fromMap(Map<String, dynamic>.from(map['rating'] as Map))
            : const RatingInfo(),
        isOpen: map['isOpen'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (category != null) 'category': category,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'rating': rating.toMap(),
        'isOpen': isOpen,
      };
}

// ============================================
// USER SETTINGS
// Stored inline on user doc for quick access
// ============================================

class UserSettings {
  final String theme; // dark, light, auto
  final String language; // en, fr, ar, es
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final String currency; // USD, EUR, MAD
  final bool showOnlineStatus;
  final bool showReadReceipts;
  final String feedPreference; // forYou, following, trending

  const UserSettings({
    this.theme = 'dark',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.currency = 'USD',
    this.showOnlineStatus = true,
    this.showReadReceipts = true,
    this.feedPreference = 'forYou',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
        theme: map['theme'] as String? ?? 'dark',
        language: map['language'] as String? ?? 'en',
        notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
        soundEnabled: map['soundEnabled'] as bool? ?? true,
        hapticEnabled: map['hapticEnabled'] as bool? ?? true,
        currency: map['currency'] as String? ?? 'USD',
        showOnlineStatus: map['showOnlineStatus'] as bool? ?? true,
        showReadReceipts: map['showReadReceipts'] as bool? ?? true,
        feedPreference: map['feedPreference'] as String? ?? 'forYou',
      );

  Map<String, dynamic> toMap() => {
        'theme': theme,
        'language': language,
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'hapticEnabled': hapticEnabled,
        'currency': currency,
        'showOnlineStatus': showOnlineStatus,
        'showReadReceipts': showReadReceipts,
        'feedPreference': feedPreference,
      };
}

// ============================================
// FOLLOW RELATIONSHIP
// Firestore: /users/{userId}/followers/{followerId}
//            /users/{userId}/following/{followedId}
// ============================================

class FollowRelation {
  final String userId;
  final String targetUserId;
  final DateTime createdAt;

  const FollowRelation({
    required this.userId,
    required this.targetUserId,
    required this.createdAt,
  });

  factory FollowRelation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowRelation(
      userId: data['userId'] as String,
      targetUserId: data['targetUserId'] as String,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'targetUserId': targetUserId,
        'createdAt': dateTimeToTimestamp(createdAt),
      };
}
