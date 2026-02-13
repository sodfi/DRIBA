import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/driba_colors.dart';
import '../shell/shell_state.dart';
import '../providers/content_providers.dart';

// ============================================
// SCREEN SHELL
// The shared foundation for ALL content screens.
// Guarantees consistent header, filters, and
// fullscreen post layout across every vertical.
//
// Usage in any screen:
//   DribaScreenShell(
//     screenId: 'food',
//     screenLabel: 'Food',
//     accent: Color(0xFFFF6B35),
//     filters: [...],
//     personalFilterIndex: 2,   // which chip opens personal view
//     personalView: MyOrdersWidget(),
//   )
// ============================================

/// Filter definition
class DribaFilter {
  final String label;
  final String emoji;
  const DribaFilter(this.label, this.emoji);
}

/// The shared screen scaffold. Every content screen wraps this.
class DribaScreenShell extends ConsumerStatefulWidget {
  final String screenId;
  final String screenLabel;
  final Color accent;
  final List<DribaFilter> filters;
  final int personalFilterIndex; // -1 = no personal view
  final Widget? personalView;   // the widget shown for the personal filter

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
  late PageController _postController;
  int _selectedFilter = 0;

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
      widget.personalFilterIndex >= 0 &&
      _selectedFilter == widget.personalFilterIndex;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content area (below header + filters)
          _isPersonalView
              ? Padding(
                  padding: EdgeInsets.only(top: topPad + 100),
                  child: widget.personalView ?? const SizedBox(),
                )
              : _buildPostsView(topPad),

          // Header (always on top)
          _DribaHeader(
            label: widget.screenLabel,
            accent: widget.accent,
            topPad: topPad,
          ),

          // Filter bar
          Positioned(
            top: topPad + 56,
            left: 0,
            right: 0,
            child: _DribaFilterBar(
              filters: widget.filters,
              selectedIndex: _selectedFilter,
              accent: widget.accent,
              onSelected: (i) {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = i);
                // Reset post page on filter change
                if (!_isPersonalView && _postController.hasClients) {
                  _postController.jumpToPage(0);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsView(double topPad) {
    final postsAsync = ref.watch(screenPostsProvider(widget.screenId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyState(accent: widget.accent, screenLabel: widget.screenLabel);
        }
        return PageView.builder(
          controller: _postController,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) {
            final postId = posts[index].id;
            ref.read(shellProvider.notifier).onContentChanged(postId: postId);
          },
          itemCount: posts.length,
          itemBuilder: (_, index) {
            // Set initial post on first build
            if (index == 0 && !ref.read(shellProvider).isViewingPost) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(shellProvider.notifier).onContentChanged(postId: posts[0].id);
              });
            }
            return DribaPostCard(
              post: posts[index],
              accent: widget.accent,
            );
          },
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
                'Content loading issue',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// HEADER — Driba logo + screen name + search
// Identical on every screen. Only accent color changes.
// ============================================

class _DribaHeader extends StatelessWidget {
  final String label;
  final Color accent;
  final double topPad;

  const _DribaHeader({
    required this.label,
    required this.accent,
    required this.topPad,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: topPad + 56,
              padding: EdgeInsets.only(top: topPad, left: 16, right: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DribaColors.background.withOpacity(0.75),
                    DribaColors.background.withOpacity(0.0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Driba "D" logo
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Screen name
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  // Search button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// FILTER BAR — Horizontal scrollable chips
// Identical sizing and style on every screen.
// ============================================

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
                color: isSelected
                    ? accent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected
                      ? accent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.08),
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
                      color: isSelected
                          ? accent
                          : Colors.white.withOpacity(0.6),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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
// One post = one full screen.
// Background image + gradient + content overlay.
// Used identically across every screen.
// ============================================

class DribaPostCard extends StatelessWidget {
  final DribaPost post;
  final Color accent;

  const DribaPostCard({
    super.key,
    required this.post,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
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
              child: Center(
                child: Icon(Icons.image,
                    color: accent.withOpacity(0.2), size: 48),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withOpacity(0.25), DribaColors.background],
              ),
            ),
          ),

        // ── Gradient overlay ──
        Container(
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
        ),

        // ── Content overlay ──
        Positioned(
          left: 20,
          right: 80, // room for engagement overlay icons
          bottom: bottomPad + 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author row
              if (post.authorName.isNotEmpty) ...[
                Row(
                  children: [
                    _Avatar(
                      url: post.authorAvatar,
                      name: post.authorName,
                      accent: accent,
                    ),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.isAIGenerated) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.auto_awesome,
                                    color: accent, size: 14),
                              ],
                            ],
                          ),
                          if (post.createdAt != null)
                            Text(
                              _timeAgo(post.createdAt!),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
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
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),

              // Price badge (commerce)
              if (post.price != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${post.price}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Hashtags
              if (post.hashtags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.hashtags.map((h) => '#$h').join(' '),
                  style: TextStyle(
                    color: accent.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Engagement hook
              if (post.engagementHook != null &&
                  post.engagementHook!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withOpacity(0.2)),
                  ),
                  child: Text(
                    post.engagementHook!,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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

// ── Small avatar ──

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final Color accent;

  const _Avatar({
    required this.url,
    required this.name,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: accent.withOpacity(0.2),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      );
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
          Text(
            '$screenLabel content loading...',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or check back soon',
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
