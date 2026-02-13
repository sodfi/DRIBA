import '../../shared/models/models.dart';

// ============================================
// PROFILE DEMO DATA
// Rich demo profile for development
// ============================================

class ProfileDemoData {
  ProfileDemoData._();

  static final DribaUser currentUser = DribaUser(
    id: 'current_user',
    username: 'saradesigns',
    displayName: 'Sara El Amrani',
    bio:
        'Product designer & creative technologist based in Casablanca. Building the future of social commerce. Passionate about bridging Moroccan craft with global design.',
    avatarUrl: 'https://i.pravatar.cc/300?img=5',
    coverUrl: 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=800',
    tagline: 'Design Lead @Driba · Ex-Google · Casablanca 🇲🇦',
    email: 'sara@driba.app',
    phone: '+212 6 12 34 56 78',
    websiteUrl: 'driba.app/@saradesigns',
    socialLinks: const [
      SocialLink(platform: 'twitter', url: 'https://twitter.com/saradesigns', username: '@saradesigns'),
      SocialLink(platform: 'instagram', url: 'https://instagram.com/saradesigns', username: '@saradesigns'),
      SocialLink(platform: 'linkedin', url: 'https://linkedin.com/in/saradesigns', username: 'saradesigns'),
      SocialLink(platform: 'dribbble', url: 'https://dribbble.com/saradesigns', username: 'saradesigns'),
    ],
    verificationStatus: VerificationStatus.verified,
    trustScore: 94,
    isCreator: true,
    isBusiness: true,
    enabledScreens: ['feed', 'food', 'commerce', 'learn', 'travel', 'art'],
    interests: ['Design', 'Technology', 'Fashion', 'Travel', 'Photography', 'Startups'],
    followersCount: 12480,
    followingCount: 892,
    postsCount: 347,
    totalLikes: 89200,
    totalEarnings: 15420.00,
    business: const BusinessMini(
      name: 'Atelier Sara',
      category: 'Design Studio',
      rating: RatingInfo(average: 4.9, count: 127),
      isOpen: true,
    ),
    createdAt: DateTime(2024, 3, 15),
    updatedAt: DateTime.now(),
    lastActiveAt: DateTime.now(),
  );

  static final List<ProfilePost> recentPosts = [
    ProfilePost(
      id: 'pp1',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400',
      type: 'image',
      likesCount: 234,
      commentsCount: 18,
    ),
    ProfilePost(
      id: 'pp2',
      imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400',
      type: 'image',
      likesCount: 189,
      commentsCount: 12,
    ),
    ProfilePost(
      id: 'pp3',
      imageUrl: 'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=400',
      type: 'image',
      likesCount: 567,
      commentsCount: 45,
    ),
    ProfilePost(
      id: 'pp4',
      imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400',
      type: 'image',
      likesCount: 412,
      commentsCount: 31,
    ),
    ProfilePost(
      id: 'pp5',
      imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400',
      type: 'product',
      likesCount: 321,
      commentsCount: 22,
    ),
    ProfilePost(
      id: 'pp6',
      imageUrl: 'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400',
      type: 'product',
      likesCount: 456,
      commentsCount: 38,
    ),
  ];

  static final List<ProfileHighlight> highlights = [
    const ProfileHighlight(
      id: 'h1', title: 'Morocco', emoji: '🇲🇦',
      coverUrl: 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=200',
    ),
    const ProfileHighlight(
      id: 'h2', title: 'Design', emoji: '🎨',
      coverUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=200',
    ),
    const ProfileHighlight(
      id: 'h3', title: 'Travel', emoji: '✈️',
      coverUrl: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=200',
    ),
    const ProfileHighlight(
      id: 'h4', title: 'Studio', emoji: '💼',
      coverUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=200',
    ),
    const ProfileHighlight(
      id: 'h5', title: 'Food', emoji: '🍽️',
      coverUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=200',
    ),
  ];

  static final List<ProfileExperience> experience = [
    const ProfileExperience(
      title: 'Design Lead',
      company: 'Driba',
      logoUrl: null,
      period: 'Jan 2025 – Present',
      isCurrent: true,
    ),
    const ProfileExperience(
      title: 'Senior UX Designer',
      company: 'Google',
      logoUrl: null,
      period: 'Mar 2022 – Dec 2024',
    ),
    const ProfileExperience(
      title: 'Product Designer',
      company: 'Jumia',
      logoUrl: null,
      period: 'Jun 2020 – Feb 2022',
    ),
  ];
}

// ── Supporting Models ────────────────────────

class ProfilePost {
  final String id;
  final String imageUrl;
  final String type; // image, video, product, article
  final int likesCount;
  final int commentsCount;

  const ProfilePost({
    required this.id,
    required this.imageUrl,
    required this.type,
    this.likesCount = 0,
    this.commentsCount = 0,
  });
}

class ProfileHighlight {
  final String id;
  final String title;
  final String? emoji;
  final String coverUrl;

  const ProfileHighlight({
    required this.id,
    required this.title,
    this.emoji,
    required this.coverUrl,
  });
}

class ProfileExperience {
  final String title;
  final String company;
  final String? logoUrl;
  final String period;
  final bool isCurrent;

  const ProfileExperience({
    required this.title,
    required this.company,
    this.logoUrl,
    required this.period,
    this.isCurrent = false,
  });
}
