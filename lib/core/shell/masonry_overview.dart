import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/driba_colors.dart';
import 'shell_state.dart';

// ============================================
// MASONRY OVERVIEW
// Long-press from ANY screen opens this.
// Pinterest / Instagram-Explore style grid
// showing all enabled screens with content.
//
// - Staggered tile heights per screen type
// - Tap tile → dismiss + navigate to that screen
// - Long-press tile → enter reorder mode
// - Drag to reorder in reorder mode
// - Swipe down or tap scrim to dismiss
// - Scale-in entrance, scale-out exit
// ============================================

class MasonryOverview extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;
  final Function(DribaScreen) onScreenTap;

  const MasonryOverview({
    super.key,
    required this.onDismiss,
    required this.onScreenTap,
  });

  @override
  ConsumerState<MasonryOverview> createState() => _MasonryOverviewState();
}

class _MasonryOverviewState extends ConsumerState<MasonryOverview>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _blurAnim;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0, 0.6)),
    );
    _blurAnim = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceController.forward();
  }

  Future<void> _dismiss({DribaScreen? navigateTo}) async {
    HapticFeedback.lightImpact();
    await _entranceController.reverse();
    if (navigateTo != null) {
      widget.onScreenTap(navigateTo);
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenOrder = ref.watch(screenOrderProvider);
    final currentScreen = ref.watch(currentScreenProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (_, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Blurred scrim
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurAnim.value,
                sigmaY: _blurAnim.value,
              ),
              child: GestureDetector(
                onTap: () => _dismiss(),
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                    _dismiss();
                  }
                },
                child: Container(
                  color: Colors.black.withOpacity(0.6 * _opacityAnim.value),
                ),
              ),
            ),
            // Content
            Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
            ),
          ],
        );
      },
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Screens',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${screenOrder.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_isReorderMode)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _isReorderMode = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: DribaColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DribaColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: DribaColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _dismiss(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 18),
                      ),
                    ),
                ],
              ),
            ),

            if (_isReorderMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Drag to reorder · Standard screens cannot be removed',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                ),
              ),

            // ── Grid ──
            Expanded(
              child: _isReorderMode
                  ? _buildReorderableList(screenOrder, currentScreen)
                  : _buildMasonryGrid(screenOrder, currentScreen, width),
            ),

            // ── Bottom hint ──
            Padding(
              padding: EdgeInsets.only(bottom: bottomPad > 0 ? 4 : 12),
              child: Text(
                _isReorderMode ? 'Hold and drag to reorder' : 'Hold a tile to reorder',
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Masonry Grid ────────────────────────────
  Widget _buildMasonryGrid(List<DribaScreen> screens, DribaScreen current, double width) {
    // Build two columns with staggered heights
    final List<DribaScreen> leftCol = [];
    final List<DribaScreen> rightCol = [];
    double leftHeight = 0;
    double rightHeight = 0;

    for (final screen in screens) {
      final h = _tileHeight(screen);
      if (leftHeight <= rightHeight) {
        leftCol.add(screen);
        leftHeight += h + 10;
      } else {
        rightCol.add(screen);
        rightHeight += h + 10;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: leftCol.asMap().entries.map((e) =>
                _buildTile(e.value, current, e.key, true)).toList(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: rightCol.asMap().entries.map((e) =>
                _buildTile(e.value, current, e.key, false)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _tileHeight(DribaScreen screen) {
    switch (screen) {
      case DribaScreen.feed: return 220;
      case DribaScreen.travel: return 240;
      case DribaScreen.health: return 210;
      case DribaScreen.food: return 200;
      case DribaScreen.commerce: return 190;
      case DribaScreen.chat: return 185;
      case DribaScreen.news: return 180;
      case DribaScreen.utility: return 170;
      default: return 180;
    }
  }

  Widget _buildTile(DribaScreen screen, DribaScreen current, int index, bool isLeft) {
    final isCurrent = screen == current;
    final accent = screen.accent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => _dismiss(navigateTo: screen),
          onLongPress: () {
            HapticFeedback.heavyImpact();
            setState(() => _isReorderMode = true);
          },
          child: Container(
            height: _tileHeight(screen),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent ? accent.withOpacity(0.5) : Colors.white.withOpacity(0.06),
                width: isCurrent ? 1.5 : 1,
              ),
              boxShadow: isCurrent
                  ? [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 20)]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Content preview
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.12),
                          accent.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 50),
                      child: _previewContent(screen, accent),
                    ),
                  ),
                  // Bottom label
                  Positioned(
                    left: 10, right: 10, bottom: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Text(screen.emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  screen.label,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: accent,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 4)],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _previewContent(DribaScreen screen, Color accent) {
    switch (screen) {
      case DribaScreen.feed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(accent, 0.7),
            const Spacer(),
            _bar(accent, 0.5), const SizedBox(height: 4),
            _bar(accent, 0.35), const SizedBox(height: 8),
            Row(children: [_dot(accent, 8), const SizedBox(width: 8), _dot(accent, 8), const SizedBox(width: 8), _dot(accent, 8)]),
          ],
        );
      case DribaScreen.chat:
        return Column(
          children: List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(bottom: 6, left: i.isEven ? 0 : 30, right: i.isEven ? 30 : 0),
            child: Container(height: 20, decoration: BoxDecoration(color: accent.withOpacity(i.isEven ? 0.1 : 0.06), borderRadius: BorderRadius.circular(10))),
          )),
        );
      case DribaScreen.news:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 60, decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 6),
          _bar(accent, 0.8), const SizedBox(height: 3), _bar(accent, 0.5),
        ]);
      case DribaScreen.food:
        return Column(children: [
          Expanded(child: Container(decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 6),
          Row(children: List.generate(3, (i) => Expanded(
            child: Container(
              height: 24, margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              decoration: BoxDecoration(color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
            ),
          ))),
        ]);
      case DribaScreen.travel:
        return Stack(children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(12)))),
          Positioned(left: 8, top: 8, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Text('✈️', style: TextStyle(fontSize: 12)),
          )),
          Positioned(bottom: 8, left: 8, right: 8, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_bar(accent, 0.6), const SizedBox(height: 3), _bar(accent, 0.4)],
          )),
        ]);
      case DribaScreen.health:
        return Center(child: SizedBox(width: 80, height: 80, child: CustomPaint(painter: _MiniRingsPainter(accent))));
      case DribaScreen.commerce:
        return GridView.count(
          crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4, crossAxisSpacing: 4,
          children: List.generate(4, (i) => Container(decoration: BoxDecoration(
            color: accent.withOpacity(0.06 + i * 0.015), borderRadius: BorderRadius.circular(8),
          ))),
        );
      case DribaScreen.utility:
        return GridView.count(
          crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1.3,
          children: List.generate(4, (i) => Container(decoration: BoxDecoration(
            color: accent.withOpacity(0.06 + i * 0.02), borderRadius: BorderRadius.circular(8),
          ))),
        );
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(screen.icon, color: accent.withOpacity(0.3), size: 28),
          const Spacer(),
          _bar(accent, 0.6), const SizedBox(height: 4), _bar(accent, 0.4),
        ]);
    }
  }

  Widget _bar(Color c, double w) => FractionallySizedBox(
    widthFactor: w,
    child: Container(height: 8, decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4))),
  );

  Widget _dot(Color c, double s) => Container(
    width: s, height: s,
    decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
  );

  // ── Reorderable List ────────────────────────
  Widget _buildReorderableList(List<DribaScreen> screens, DribaScreen current) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (_, child) => Material(color: Colors.transparent, child: Transform.scale(scale: 1.05, child: child)),
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        ref.read(shellProvider.notifier).reorderScreens(oldIndex, newIndex);
      },
      itemCount: screens.length,
      itemBuilder: (context, index) {
        final screen = screens[index];
        final isCurrent = screen == current;
        final accent = screen.accent;

        return Container(
          key: ValueKey(screen),
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isCurrent ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, color: Colors.white.withOpacity(0.2), size: 20),
                    const SizedBox(width: 10),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(screen.emoji, style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(screen.label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(screen.isStandard ? 'Standard' : 'Add-on', style: TextStyle(
                          color: screen.isStandard ? accent.withOpacity(0.5) : Colors.white.withOpacity(0.25),
                          fontSize: 11, fontWeight: FontWeight.w500,
                        )),
                      ],
                    )),
                    Container(width: 12, height: 12, decoration: BoxDecoration(
                      color: accent, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6)],
                    )),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mini activity rings for Health preview
class _MiniRingsPainter extends CustomPainter {
  final Color accent;
  _MiniRingsPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round;
    final colors = [const Color(0xFFFF3D71), const Color(0xFF00B4D8), accent];
    final radii = [32.0, 24.0, 16.0];
    final progresses = [0.78, 0.62, 0.90];

    for (int i = 0; i < 3; i++) {
      paint.color = colors[i].withOpacity(0.12);
      canvas.drawCircle(center, radii[i], paint);
      paint.color = colors[i].withOpacity(0.6);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radii[i]), -math.pi / 2, 2 * math.pi * progresses[i], false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
