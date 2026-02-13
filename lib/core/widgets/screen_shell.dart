import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/driba_colors.dart';
import '../shell/shell_state.dart';
import '../providers/content_providers.dart';

// ============================================
// SCREEN SHELL v3
// 
// Fixes:
// - Shuffled post order (dynamic, not static)
// - Pull-to-refresh
// - Persistent TikTok-style action buttons (right side)
// - Double-tap to like with heart animation
// - Single tap toggles chrome
// ============================================

class DribaFilter {
  final String label;
  final String emoji;
  const DribaFilter(this.label, this.emoji);
}

class DribaScreenShell extends ConsumerStatefulWidget {
  final String screenId;
  final String screenLabel;
  final Color accent;
  final List<DribaFilter> filters;
  final int personalFilterIndex;
  final Widget? personalView;

  const DribaScreenShell({
    super.key,
    required this.screenId,
    required this.screenLabel,
    required this.accent,
    required this.filters,
    this.personalFilterIndex = -1,
    this.personalView,
  });

  @override
  ConsumerState<DribaScreenShell> createState() => _DribaScreenShellState();
}

class _DribaScreenShellState extends ConsumerState<DribaScreenShell> {
  int _filterIndex = 0;
  late PageController _postController;
  int _shuffleSeed = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _postController = PageController();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  bool get _isPersonalView =>
      widget.personalFilterIndex >= 0 && _filterIndex == widget.personalFilterIndex;

  void _onFilterSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() => _filterIndex = index);
  }

  void _refresh() {
    setState(() => _shuffleSeed = DateTime.now().millisecondsSinceEpoch);
    ref.invalidate(screenPostsProvider(widget.screenId));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Column(
        children: [
          SizedBox(height: topPad + 8),
          // Filter bar
          if (widget.filters.length > 1)
            _DribaFilterBar(
              filters: widget.filters,
              selectedIndex: _filterIndex,
              accent: widget.accent,
              onSelected: _onFilterSelected,
            ),
          if (widget.filters.length > 1) const SizedBox(height: 6),
          // Content area
          Expanded(
            child: _isPersonalView
                ? (widget.personalView ?? const SizedBox())
                : _buildPostsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsView() {
    final postsAsync = ref.watch(screenPostsProvider(widget.screenId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(accent: widget.accent, screenLabel: widget.screenLabel);
        }
        // Shuffle posts for dynamic feel
        final shuffled = List<DribaPost>.from(posts);
        shuffled.shuffle(math.Random(_shuffleSeed));

        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: widget.accent,
          backgroundColor: DribaColors.surface,
          child: PageView.builder(
            controller: _postController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              final postId = shuffled[index].id;
              ref.read(shellProvider.notifier).onContentChanged(postId: postId);
            },
            itemCount: shuffled.length,
            itemBuilder: (_, index) {
              if (index == 0 && !ref.read(shellProvider).isViewingPost) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(shellProvider.notifier).onContentChanged(postId: shuffled[0].id);
                });
              }
              return DribaPostCard(
                post: shuffled[index],
                accent: widget.accent,
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2),
      ),
      error: (err, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: widget.accent.withOpacity(0.5), size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading content',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString().length > 120 ? '${err.toString().substring(0, 120)}...' : err.toString(),
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _refresh,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.accent.withOpacity(0.3)),
                  ),
                  child: Text('Retry', style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Bar ──

class _DribaFilterBar extends StatelessWidget {
  final List<DribaFilter> filters;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onSelected;

  const _DribaFilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.accent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isSelected = selectedIndex == index;
          final f = filters[index];
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? accent.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f.emoji.isNotEmpty) ...[
                    Text(f.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    f.label,
                    style: TextStyle(
                      color: isSelected ? accent : Colors.white.withOpacity(0.6),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// FULLSCREEN POST CARD
// Now with:
// - Persistent right-side action buttons (TikTok-style)
// - Double-tap to like with heart animation
// - Auth gating for anonymous users
// ============================================

class DribaPostCard extends StatefulWidget {
  final DribaPost post;
  final Color accent;

  const DribaPostCard({super.key, required this.post, required this.accent});

  @override
  State<DribaPostCard> createState() => _DribaPostCardState();
}

class _DribaPostCardState extends State<DribaPostCard> with TickerProviderStateMixin {
  bool _liked = false;
  bool _saved = false;
  bool _showHeart = false;
  late AnimationController _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _heartAnim.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
        _heartAnim.reset();
      }
    });
  }

  @override
  void dispose() {
    _heartAnim.dispose();
    super.dispose();
  }

  bool _isAnonymous() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous;
  }

  void _doubleTapLike() {
    HapticFeedback.mediumImpact();
    setState(() { _liked = true; _showHeart = true; });
    _heartAnim.forward();
    _updatePost('likes');
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() => _liked = !_liked);
    if (_liked) _updatePost('likes');
  }

  void _toggleSave() {
    HapticFeedback.lightImpact();
    setState(() => _saved = !_saved);
    if (_saved) _updatePost('saves');
  }

  void _onShare() {
    HapticFeedback.lightImpact();
    _updatePost('shares');
  }

  void _onComment() {
    HapticFeedback.lightImpact();
    // Could open comment sheet here
  }

  void _updatePost(String field) {
    if (_isAnonymous()) return;
    try {
      FirebaseFirestore.instance.collection('posts').doc(widget.post.id)
          .update({field: FieldValue.increment(1)});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final post = widget.post;
    final accent = widget.accent;

    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ──
          if (post.mediaUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: post.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: DribaColors.surface),
              errorWidget: (_, __, ___) => Container(
                color: DribaColors.surface,
                child: Center(child: Icon(Icons.image, color: accent.withOpacity(0.2), size: 48)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [accent.withOpacity(0.25), DribaColors.background],
                ),
              ),
            ),

          // ── Gradient overlay ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // ── Right side action buttons (always visible) ──
          Positioned(
            right: 12,
            bottom: bottomPad + 120,
            child: _ActionButtons(
              post: post,
              accent: accent,
              liked: _liked,
              saved: _saved,
              onLike: _toggleLike,
              onComment: _onComment,
              onSave: _toggleSave,
              onShare: _onShare,
            ),
          ),

          // ── Content overlay (left side) ──
          Positioned(
            left: 20,
            right: 70,
            bottom: bottomPad + 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Author
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
                                  child: Text(post.authorName,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                if (post.isAIGenerated) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.auto_awesome, color: accent, size: 14),
                                ],
                              ],
                            ),
                            if (post.createdAt != null)
                              Text(_timeAgo(post.createdAt!),
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Description
                Text(post.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, height: 1.4, fontWeight: FontWeight.w500),
                  maxLines: 4, overflow: TextOverflow.ellipsis),

                // Price
                if (post.price != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                    child: Text('\$${post.price}',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],

                // Hashtags
                if (post.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.hashtags.map((h) => '#$h').join(' '),
                    style: TextStyle(color: accent.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),

          // ── Double-tap heart animation ──
          if (_showHeart)
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.4).animate(
                  CurvedAnimation(parent: _heartAnim, curve: Curves.elasticOut),
                ),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                    CurvedAnimation(parent: _heartAnim, curve: const Interval(0.5, 1.0)),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 100),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

// ── TikTok-style action buttons (always visible) ──

class _ActionButtons extends StatelessWidget {
  final DribaPost post;
  final Color accent;
  final bool liked;
  final bool saved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _ActionButtons({
    required this.post, required this.accent,
    required this.liked, required this.saved,
    required this.onLike, required this.onComment,
    required this.onSave, required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: _formatCount(post.likes + (liked ? 1 : 0)),
          color: liked ? Colors.red : Colors.white,
          onTap: onLike,
        ),
        const SizedBox(height: 20),
        _ActionBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: _formatCount(post.comments),
          color: Colors.white,
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        _ActionBtn(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          label: _formatCount(post.saves + (saved ? 1 : 0)),
          color: saved ? const Color(0xFFFFD700) : Colors.white,
          onTap: onSave,
        ),
        const SizedBox(height: 20),
        _ActionBtn(
          icon: Icons.send_rounded,
          label: _formatCount(post.shares),
          color: Colors.white,
          onTap: onShare,
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Avatar ──

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
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fb())
            : _fb(),
      ),
    );
  }
  Widget _fb() => Container(color: accent.withOpacity(0.2),
    child: Center(child: Text(name.isNotEmpty ? name[0] : '?',
      style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14))));
}

// ── Empty state ──

class _EmptyState extends StatelessWidget {
  final Color accent;
  final String screenLabel;
  const _EmptyState({required this.accent, required this.screenLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore, color: accent.withOpacity(0.4), size: 56),
          const SizedBox(height: 16),
          Text('$screenLabel content loading...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Pull to refresh or check back soon', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ],
      ),
    );
  }
}
