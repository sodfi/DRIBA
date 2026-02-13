import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/driba_colors.dart';
import '../providers/content_providers.dart';

// ============================================================
// RESPONSIVE POST CARD (v2)
//
// Key feature: dual aspect ratio rendering.
//
// MOBILE PORTRAIT  → 9:16 fullscreen card (mediaUrlPortrait)
// DESKTOP/TABLET   → 16:9 card in grid    (mediaUrlLandscape)
// LANDSCAPE PHONE  → 16:9 card            (mediaUrlLandscape)
//
// The card auto-detects via LayoutBuilder + MediaQuery.
// If a specific ratio URL isn't available, falls back to mediaUrl.
//
// Also includes:
//   • Audio play button (for voiceover posts)
//   • AI-generated badge
//   • AI-enhanced badge
//   • Engagement overlay (likes/comments/share/save)
//   • Commerce price badge
// ============================================================

/// Fullscreen vertical card for mobile PageView swipe
class DribaPostCard extends StatefulWidget {
  final DribaPost post;
  final Color accent;

  const DribaPostCard({
    super.key,
    required this.post,
    required this.accent,
  });

  @override
  State<DribaPostCard> createState() => _DribaPostCardState();
}

class _DribaPostCardState extends State<DribaPostCard> {
  bool _isAudioPlaying = false;

  DribaPost get post => widget.post;
  Color get accent => widget.accent;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isPortrait = mq.orientation == Orientation.portrait;
    final isNarrow = mq.size.width < 700;
    final usePortraitMedia = isPortrait && isNarrow;
    final bottomPad = mq.padding.bottom;

    // Select the correct media URL for this layout
    final imageUrl = post.getMediaUrl(isPortrait: usePortraitMedia);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background media ──
        _buildMedia(imageUrl),

        // ── Gradient overlay ──
        _buildGradient(),

        // ── Content overlay (bottom) ──
        Positioned(
          left: 20,
          right: 80, // room for engagement rail
          bottom: bottomPad + 24,
          child: _buildContent(),
        ),

        // ── Engagement rail (right side) ──
        Positioned(
          right: 12,
          bottom: bottomPad + 80,
          child: _buildEngagementRail(),
        ),

        // ── Audio play button (top right) ──
        if (post.hasVoiceover && post.audioUrl.isNotEmpty)
          Positioned(
            top: mq.padding.top + 60,
            right: 16,
            child: _buildAudioButton(),
          ),

        // ── AI badge (top left) ──
        if (post.isAIGenerated || post.isAIEnhanced)
          Positioned(
            top: mq.padding.top + 60,
            left: 16,
            child: _buildAiBadge(),
          ),
      ],
    );
  }

  // ── Media ─────────────────────────────────────────────

  Widget _buildMedia(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: DribaColors.surface),
        errorWidget: (_, __, ___) => Container(
          color: DribaColors.surface,
          child: Center(child: Icon(Icons.image, color: accent.withOpacity(0.2), size: 48)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.25), DribaColors.background],
        ),
      ),
    );
  }

  // ── Gradient ──────────────────────────────────────────

  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author row
        if (post.authorName.isNotEmpty) ...[
          Row(
            children: [
              _Avatar(url: post.authorAvatar, name: post.authorName, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isAIGenerated) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.auto_awesome, color: accent, size: 14),
                        ],
                      ],
                    ),
                    if (post.createdAt != null)
                      Text(
                        _timeAgo(post.createdAt!),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Description
        Text(
          post.description,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),

        // Price badge (commerce)
        if (post.price != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: Text('\$${post.price}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: const Text('Add to Cart',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ],

        // Hashtags
        if (post.hashtags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            post.hashtags.map((h) => '#$h').join(' '),
            style: TextStyle(color: accent.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Engagement hook
        if (post.engagementHook != null && post.engagementHook!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Text(
              post.engagementHook!,
              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
            ),
          ),
        ],
      ],
    );
  }

  // ── Engagement Rail (right side icons) ────────────────

  Widget _buildEngagementRail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EngagementButton(icon: Icons.favorite_border, label: _formatCount(post.likes), accent: accent),
        const SizedBox(height: 16),
        _EngagementButton(icon: Icons.chat_bubble_outline, label: _formatCount(post.comments), accent: accent),
        const SizedBox(height: 16),
        _EngagementButton(icon: Icons.share_outlined, label: _formatCount(post.shares), accent: accent),
        const SizedBox(height: 16),
        _EngagementButton(icon: Icons.bookmark_border, label: _formatCount(post.saves), accent: accent),
      ],
    );
  }

  // ── Audio Button ──────────────────────────────────────

  Widget _buildAudioButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _isAudioPlaying = !_isAudioPlaying);
        // TODO: actual audio player integration (just_audio package)
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAudioPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _isAudioPlaying ? accent : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _isAudioPlaying ? 'Playing' : 'Listen',
                  style: TextStyle(
                    color: _isAudioPlaying ? accent : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AI Badge ──────────────────────────────────────────

  Widget _buildAiBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: post.isAIEnhanced ? DribaColors.premiumGradient : null,
            color: post.isAIEnhanced ? null : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white70, size: 12),
              const SizedBox(width: 4),
              Text(
                post.isAIEnhanced ? 'AI Enhanced' : 'AI Created',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ============================================================
// Desktop/Landscape Grid Card
// Used when screen width > 700 or in landscape orientation.
// Shows 16:9 landscape media in a card-based grid layout.
// ============================================================

class DribaPostCardLandscape extends StatelessWidget {
  final DribaPost post;
  final Color accent;
  final VoidCallback? onTap;

  const DribaPostCardLandscape({
    super.key,
    required this.post,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.getMediaUrl(isPortrait: false);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DribaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 media
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: DribaColors.surface),
                      errorWidget: (_, __, ___) => Container(
                        color: DribaColors.surface,
                        child: Icon(Icons.image, color: accent.withOpacity(0.2)),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withOpacity(0.2), DribaColors.surface],
                        ),
                      ),
                    ),

                  // Video indicator
                  if (post.mediaType == 'video')
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 14),
                            SizedBox(width: 2),
                            Text('Video', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),

                  // Audio indicator
                  if (post.hasVoiceover)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.volume_up, color: accent, size: 14),
                      ),
                    ),

                  // AI badge
                  if (post.isAIGenerated || post.isAIEnhanced)
                    Positioned(
                      bottom: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: DribaColors.premiumGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              post.isAIEnhanced ? 'Enhanced' : 'AI',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Row(
                    children: [
                      _Avatar(url: post.authorAvatar, name: post.authorName, accent: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.authorName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.createdAt != null)
                        Text(
                          DribaPostCard._timeAgo(post.createdAt!),
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    post.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Hashtags
                  if (post.hashtags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.hashtags.map((h) => '#$h').join(' '),
                      style: TextStyle(color: accent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                    ),
                  ],

                  // Engagement row
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InlineEngagement(icon: Icons.favorite_border, count: post.likes, accent: accent),
                      const SizedBox(width: 16),
                      _InlineEngagement(icon: Icons.chat_bubble_outline, count: post.comments, accent: accent),
                      const SizedBox(width: 16),
                      _InlineEngagement(icon: Icons.share_outlined, count: post.shares, accent: accent),
                      const Spacer(),
                      Icon(Icons.bookmark_border, color: Colors.white24, size: 18),
                    ],
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

// ============================================================
// Adaptive Layout Wrapper
// Automatically switches between PageView (mobile portrait)
// and Grid (desktop / landscape).
// ============================================================

class AdaptivePostLayout extends StatelessWidget {
  final List<DribaPost> posts;
  final Color accent;
  final PageController? pageController;

  const AdaptivePostLayout({
    super.key,
    required this.posts,
    required this.accent,
    this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width < 700;
    final isPortrait = mq.orientation == Orientation.portrait;

    if (isNarrow && isPortrait) {
      // Mobile portrait → fullscreen vertical swipe (existing behavior)
      return PageView.builder(
        scrollDirection: Axis.vertical,
        controller: pageController ?? PageController(),
        itemCount: posts.length,
        itemBuilder: (ctx, i) => DribaPostCard(post: posts[i], accent: accent),
      );
    }

    // Desktop / tablet / landscape → grid of landscape cards
    final crossAxisCount = mq.size.width > 1200 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: posts.length,
      itemBuilder: (ctx, i) => DribaPostCardLandscape(
        post: posts[i],
        accent: accent,
        onTap: () => _openFullscreen(context, posts, i),
      ),
    );
  }

  void _openFullscreen(BuildContext context, List<DribaPost> posts, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullscreenPostViewer(posts: posts, initialIndex: index, accent: accent),
    ));
  }
}

/// Fullscreen viewer — opened when tapping a landscape grid card
class _FullscreenPostViewer extends StatelessWidget {
  final List<DribaPost> posts;
  final int initialIndex;
  final Color accent;

  const _FullscreenPostViewer({required this.posts, required this.initialIndex, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: PageController(initialPage: initialIndex),
            itemCount: posts.length,
            itemBuilder: (ctx, i) => DribaPostCard(post: posts[i], accent: accent),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Shared sub-widgets
// ============================================================

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final Color accent;

  const _Avatar({required this.url, required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 1.5)),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    color: accent.withOpacity(0.2),
    child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14))),
  );
}

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _EngagementButton({required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InlineEngagement extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color accent;

  const _InlineEngagement({required this.icon, required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 4),
        Text(DribaPostCard._formatCount(count), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ],
    );
  }
}
