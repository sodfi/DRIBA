import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import '../../shared/models/models.dart';
import 'profile_demo_data.dart';
import 'profile_edit_sheet.dart';
import 'profile_widgets.dart';

/// Profile Screen — LinkedIn meets Instagram
/// Cyan accent (#00E1FF), glass sections, AI-powered bio
class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId; // null = current user
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _entranceController;
  late TabController _tabController;

  double _scrollOffset = 0;
  bool _isFollowing = false;
  String _selectedTab = 'posts'; // posts, products, about

  static const Color _accent = DribaColors.primary; // cyan
  static const String _myId = 'current_user';

  late final DribaUser _user;
  late final bool _isOwnProfile;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _entranceController = AnimationController(
      vsync: this,
      duration: DribaDurations.slow,
    )..forward();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = ['posts', 'products', 'about'][_tabController.index];
      });
    });

    _user = ProfileDemoData.currentUser;
    _isOwnProfile = widget.userId == null || widget.userId == _myId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() => _scrollOffset = _scrollController.offset);
  }

  void _openEditProfile() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileEditSheet(user: _user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final coverHeight = 220.0;
    final collapseProgress = (_scrollOffset / coverHeight).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Cover image
              SliverToBoxAdapter(
                child: _buildCover(coverHeight),
              ),

              // Profile header (avatar, name, stats)
              SliverToBoxAdapter(
                child: _buildProfileHeader(),
              ),

              // Highlights row
              SliverToBoxAdapter(
                child: _buildHighlights(),
              ),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabController: _tabController,
                  accent: _accent,
                ),
              ),

              // Tab content
              if (_selectedTab == 'posts')
                _buildPostsGrid()
              else if (_selectedTab == 'products')
                _buildProductsGrid()
              else
                SliverToBoxAdapter(child: _buildAboutSection()),

              // Bottom space
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // Collapsing header
          _buildCollapsingHeader(topPad, collapseProgress),
        ],
      ),
    );
  }

  // ── Cover Image ─────────────────────────────
  Widget _buildCover(double height) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image with parallax
          Transform.translate(
            offset: Offset(0, _scrollOffset * 0.4),
            child: CachedNetworkImage(
              imageUrl: _user.coverUrl ?? 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=800',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  DribaColors.background.withOpacity(0.3),
                  DribaColors.background,
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Header ──────────────────────────
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + action buttons row
          Transform.translate(
            offset: const Offset(0, -40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DribaColors.background, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundImage: CachedNetworkImageProvider(
                      _user.avatarUrl ?? 'https://i.pravatar.cc/300',
                    ),
                  ),
                ),
                const Spacer(),
                // Action buttons
                if (_isOwnProfile) ...[
                  _ActionButton(
                    label: 'Edit Profile',
                    icon: Icons.edit_outlined,
                    accent: _accent,
                    onTap: _openEditProfile,
                  ),
                  const SizedBox(width: DribaSpacing.sm),
                  _ActionButton(
                    icon: Icons.settings_outlined,
                    accent: _accent,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                ] else ...[
                  _FollowButton(
                    isFollowing: _isFollowing,
                    accent: _accent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isFollowing = !_isFollowing);
                    },
                  ),
                  const SizedBox(width: DribaSpacing.sm),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    accent: _accent,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                  const SizedBox(width: DribaSpacing.sm),
                  _ActionButton(
                    icon: Icons.more_horiz,
                    accent: _accent,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                ],
              ],
            ),
          ),

          // Name + verification
          Transform.translate(
            offset: const Offset(0, -24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _user.displayName,
                        style: const TextStyle(
                          color: DribaColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (_user.verificationStatus == VerificationStatus.verified) ...[
                      const SizedBox(width: DribaSpacing.sm),
                      Icon(Icons.verified, color: _accent, size: 22),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${_user.username}',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_user.tagline != null) ...[
                  const SizedBox(height: DribaSpacing.sm),
                  Text(
                    _user.tagline!,
                    style: TextStyle(
                      color: DribaColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                if (_user.bio != null) ...[
                  const SizedBox(height: DribaSpacing.md),
                  Text(
                    _user.bio!,
                    style: TextStyle(
                      color: DribaColors.textTertiary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: DribaSpacing.lg),

                // Stats row
                _buildStats(),

                const SizedBox(height: DribaSpacing.lg),

                // Trust score + badges
                _buildBadges(),

                // Social links
                if (_user.socialLinks.isNotEmpty) ...[
                  const SizedBox(height: DribaSpacing.lg),
                  _buildSocialLinks(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatItem(
          count: _user.postsCount,
          label: 'Posts',
          accent: _accent,
        ),
        const SizedBox(width: DribaSpacing.xl),
        _StatItem(
          count: _user.followersCount,
          label: 'Followers',
          accent: _accent,
        ),
        const SizedBox(width: DribaSpacing.xl),
        _StatItem(
          count: _user.followingCount,
          label: 'Following',
          accent: _accent,
        ),
        if (_user.isCreator) ...[
          const SizedBox(width: DribaSpacing.xl),
          _StatItem(
            count: _user.totalLikes,
            label: 'Likes',
            accent: _accent,
          ),
        ],
      ],
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: DribaSpacing.sm,
      runSpacing: DribaSpacing.sm,
      children: [
        if (_user.trustScore > 0)
          _ProfileBadge(
            icon: Icons.shield_outlined,
            label: 'Trust ${_user.trustScore.toInt()}%',
            color: DribaColors.success,
          ),
        if (_user.isCreator)
          _ProfileBadge(
            icon: Icons.auto_awesome,
            label: 'Creator',
            color: DribaColors.tertiary,
          ),
        if (_user.isBusiness)
          _ProfileBadge(
            icon: Icons.store_outlined,
            label: _user.business?.name ?? 'Business',
            color: Color(0xFFFFD700),
          ),
        if (_user.business?.rating != null && _user.business!.rating.count > 0)
          _ProfileBadge(
            icon: Icons.star,
            label: '${_user.business!.rating.average} (${_user.business!.rating.count})',
            color: Color(0xFFFF6B35),
          ),
      ],
    );
  }

  Widget _buildSocialLinks() {
    final iconMap = {
      'twitter': Icons.alternate_email,
      'instagram': Icons.camera_alt_outlined,
      'linkedin': Icons.work_outline,
      'dribbble': Icons.sports_basketball_outlined,
      'github': Icons.code,
      'youtube': Icons.play_circle_outline,
    };

    return Row(
      children: _user.socialLinks.map((link) {
        return Padding(
          padding: const EdgeInsets.only(right: DribaSpacing.md),
          child: GlassCircleButton(
            size: 36,
            onTap: () => HapticFeedback.lightImpact(),
            child: Icon(
              iconMap[link.platform] ?? Icons.link,
              color: DribaColors.textSecondary,
              size: 18,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Highlights ──────────────────────────────
  Widget _buildHighlights() {
    final highlights = ProfileDemoData.highlights;
    return Transform.translate(
      offset: const Offset(0, -16),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
          itemCount: highlights.length + (_isOwnProfile ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(width: DribaSpacing.md),
          itemBuilder: (context, index) {
            if (_isOwnProfile && index == 0) {
              // Add highlight button
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassContainer(
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    borderColor: _accent.withOpacity(0.3),
                    child: Icon(Icons.add, color: _accent, size: 24),
                  ),
                  const SizedBox(height: DribaSpacing.xs),
                  Text(
                    'New',
                    style: TextStyle(
                      color: DribaColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }
            final h = highlights[_isOwnProfile ? index - 1 : index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent.withOpacity(0.5), width: 2),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: h.coverUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: DribaSpacing.xs),
                Text(
                  h.emoji != null ? '${h.emoji} ${h.title}' : h.title,
                  style: const TextStyle(
                    color: DribaColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Posts Grid ──────────────────────────────
  SliverPadding _buildPostsGrid() {
    final posts = ProfileDemoData.recentPosts;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = posts[index % posts.length];
            return AnimatedBuilder(
              animation: _entranceController,
              builder: (_, child) {
                final delay = (index * 0.05).clamp(0.0, 0.5);
                final progress =
                    ((_entranceController.value - delay) / (1 - delay))
                        .clamp(0.0, 1.0);
                return Opacity(
                  opacity: Curves.easeOut.transform(progress),
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * Curves.easeOut.transform(progress),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    // Overlay on hover/tap
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Stats
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            _formatCount(post.likesCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (post.type == 'product')
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.shopping_bag, color: Colors.white, size: 10),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          childCount: posts.length,
        ),
      ),
    );
  }

  SliverPadding _buildProductsGrid() {
    final products = ProfileDemoData.recentPosts
        .where((p) => p.type == 'product')
        .toList();
    if (products.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(DribaSpacing.xxxl),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: DribaColors.textDisabled, size: 48),
                const SizedBox(height: DribaSpacing.md),
                Text(
                  'No products yet',
                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _buildPostsGrid(); // Reuse grid with filtered products
  }

  // ── About Section ───────────────────────────
  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(DribaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio (full)
          if (_user.bio != null) ...[
            _SectionTitle(title: 'About', icon: Icons.person_outline),
            const SizedBox(height: DribaSpacing.md),
            GlassContainer(
              padding: const EdgeInsets.all(DribaSpacing.lg),
              borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
              child: Text(
                _user.bio!,
                style: TextStyle(
                  color: DribaColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: DribaSpacing.xxl),
          ],

          // Experience
          _SectionTitle(title: 'Experience', icon: Icons.work_outline),
          const SizedBox(height: DribaSpacing.md),
          ...ProfileDemoData.experience.map((exp) => _ExperienceCard(
                experience: exp,
                accent: _accent,
              )),

          const SizedBox(height: DribaSpacing.xxl),

          // Interests
          _SectionTitle(title: 'Interests', icon: Icons.interests_outlined),
          const SizedBox(height: DribaSpacing.md),
          Wrap(
            spacing: DribaSpacing.sm,
            runSpacing: DribaSpacing.sm,
            children: _user.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DribaSpacing.lg,
                  vertical: DribaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: DribaSpacing.xxl),

          // Screens / Worlds
          _SectionTitle(title: 'Active Worlds', icon: Icons.grid_view_rounded),
          const SizedBox(height: DribaSpacing.md),
          Wrap(
            spacing: DribaSpacing.sm,
            runSpacing: DribaSpacing.sm,
            children: _user.enabledScreens.map((screenId) {
              final config = allScreens.firstWhere(
                (s) => s.id == screenId,
                orElse: () => ScreenConfig(id: screenId, name: screenId, icon: 'grid_view', color: 0xFF00E1FF),
              );
              final color = Color(config.color);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DribaSpacing.md,
                  vertical: DribaSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  config.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: DribaSpacing.xxl),

          // Member since
          Center(
            child: Text(
              'Member since ${_user.createdAt.month}/${_user.createdAt.year}',
              style: TextStyle(
                color: DribaColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Collapsing Header ───────────────────────
  Widget _buildCollapsingHeader(double topPad, double progress) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: progress < 0.5,
        child: AnimatedOpacity(
          opacity: progress > 0.6 ? 1.0 : 0.0,
          duration: DribaDurations.fast,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  DribaSpacing.lg,
                  topPad + DribaSpacing.sm,
                  DribaSpacing.lg,
                  DribaSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: DribaColors.glassFill,
                  border: Border(
                    bottom: BorderSide(color: DribaColors.glassBorder),
                  ),
                ),
                child: Row(
                  children: [
                    if (!_isOwnProfile)
                      GlassCircleButton(
                        size: 36,
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: DribaColors.textPrimary, size: 16),
                      ),
                    if (!_isOwnProfile) const SizedBox(width: DribaSpacing.md),
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: CachedNetworkImageProvider(
                        _user.avatarUrl ?? '',
                      ),
                    ),
                    const SizedBox(width: DribaSpacing.md),
                    Expanded(
                      child: Text(
                        _user.displayName,
                        style: const TextStyle(
                          color: DribaColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_user.verificationStatus == VerificationStatus.verified)
                      Icon(Icons.verified, color: _accent, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ============================================
// TAB BAR DELEGATE (Sticky)
// ============================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color accent;

  _TabBarDelegate({required this.tabController, required this.accent});

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: DribaColors.background.withOpacity(0.85),
          child: TabBar(
            controller: tabController,
            indicatorColor: accent,
            indicatorWeight: 2.5,
            labelColor: accent,
            unselectedLabelColor: DribaColors.textTertiary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Products'),
              Tab(text: 'About'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ============================================
// SUB-WIDGETS
// ============================================

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color accent;

  const _StatItem({required this.count, required this.label, required this.accent});

  String get _formatted {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatted,
          style: const TextStyle(
            color: DribaColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DribaColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String? label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionButton({
    this.label,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: DribaSpacing.lg,
          vertical: DribaSpacing.sm,
        ),
        borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DribaColors.textSecondary, size: 16),
            const SizedBox(width: DribaSpacing.xs),
            Text(
              label!,
              style: const TextStyle(
                color: DribaColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return GlassCircleButton(
      size: 36,
      onTap: onTap,
      child: Icon(icon, color: DribaColors.textSecondary, size: 18),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final Color accent;
  final VoidCallback? onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DribaDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: DribaSpacing.xl,
          vertical: DribaSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isFollowing ? null : DribaColors.primaryGradient,
          color: isFollowing ? DribaColors.glassFillActive : null,
          borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
          border: isFollowing
              ? Border.all(color: DribaColors.glassBorder)
              : null,
          boxShadow: isFollowing ? null : DribaShadows.primaryGlow,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? DribaColors.textSecondary : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DribaSpacing.md,
        vertical: DribaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: DribaSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: DribaColors.textSecondary, size: 18),
        const SizedBox(width: DribaSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            color: DribaColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final ProfileExperience experience;
  final Color accent;

  const _ExperienceCard({required this.experience, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DribaSpacing.md),
      child: GlassContainer(
        padding: const EdgeInsets.all(DribaSpacing.lg),
        borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
        borderColor: experience.isCurrent ? accent.withOpacity(0.2) : null,
        child: Row(
          children: [
            // Logo placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DribaBorderRadius.md),
              ),
              child: Center(
                child: Text(
                  experience.company[0],
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DribaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        experience.title,
                        style: const TextStyle(
                          color: DribaColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (experience.isCurrent) ...[
                        const SizedBox(width: DribaSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    experience.company,
                    style: TextStyle(
                      color: DribaColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    experience.period,
                    style: TextStyle(
                      color: DribaColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Re-export from app_state for screen configs
const allScreens = [
  ScreenConfig(id: 'feed', name: 'Feed', icon: 'home', color: 0xFF00E1FF),
  ScreenConfig(id: 'food', name: 'Food', icon: 'restaurant', color: 0xFFFF6B35),
  ScreenConfig(id: 'commerce', name: 'Commerce', icon: 'shopping_bag', color: 0xFFFFD700),
  ScreenConfig(id: 'travel', name: 'Travel', icon: 'flight', color: 0xFF00B4D8),
  ScreenConfig(id: 'health', name: 'Health', icon: 'favorite', color: 0xFF00D68F),
  ScreenConfig(id: 'news', name: 'News', icon: 'newspaper', color: 0xFFFF3D71),
  ScreenConfig(id: 'learn', name: 'Learn', icon: 'school', color: 0xFF8B5CF6),
  ScreenConfig(id: 'art', name: 'Art', icon: 'brush', color: 0xFFFFAA00),
];

class ScreenConfig {
  final String id;
  final String name;
  final String icon;
  final int color;
  const ScreenConfig({required this.id, required this.name, required this.icon, required this.color});
}
