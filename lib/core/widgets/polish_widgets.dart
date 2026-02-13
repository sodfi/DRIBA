import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/driba_colors.dart';
import '../widgets/glass_container.dart';

// ============================================
// POLISH WIDGETS
// Loading skeletons, empty/error states,
// animated counters, toasts, pull-to-refresh
// ============================================

// ── SHIMMER LOADING SKELETONS ─────────────────

/// Shimmer effect for loading placeholders
class DribaShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const DribaShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<DribaShimmerBox> createState() => _DribaShimmerBoxState();
}

class _DribaShimmerBoxState extends State<DribaShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                DribaColors.glassFill,
                DribaColors.glassFillHover,
                DribaColors.glassFill,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for article/news cards
class ArticleCardSkeleton extends StatelessWidget {
  const ArticleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.md),
      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DribaShimmerBox(width: 80, height: 10, borderRadius: 5),
                const SizedBox(height: DribaSpacing.sm),
                DribaShimmerBox(width: double.infinity, height: 14, borderRadius: 7),
                const SizedBox(height: 6),
                DribaShimmerBox(width: 180, height: 14, borderRadius: 7),
                const SizedBox(height: DribaSpacing.md),
                DribaShimmerBox(width: 100, height: 10, borderRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: DribaSpacing.md),
          DribaShimmerBox(width: 90, height: 80, borderRadius: DribaBorderRadius.lg),
        ],
      ),
    );
  }
}

/// Skeleton for product/course grid cards
class GridCardSkeleton extends StatelessWidget {
  const GridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DribaBorderRadius.xl),
              ),
              child: DribaShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(DribaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DribaShimmerBox(width: double.infinity, height: 12, borderRadius: 6),
                  const SizedBox(height: 6),
                  DribaShimmerBox(width: 80, height: 10, borderRadius: 5),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DribaShimmerBox(width: 50, height: 10, borderRadius: 5),
                      DribaShimmerBox(width: 40, height: 14, borderRadius: 7),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for horizontal card lists (hotels, experiences)
class HorizontalCardSkeleton extends StatelessWidget {
  final int count;
  final double height;
  final double width;

  const HorizontalCardSkeleton({
    super.key,
    this.count = 3,
    this.height = 200,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.xl),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: DribaSpacing.md),
        itemBuilder: (_, __) => SizedBox(
          width: width,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DribaBorderRadius.xl),
                    ),
                    child: DribaShimmerBox(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(DribaSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DribaShimmerBox(width: 140, height: 12, borderRadius: 6),
                      const SizedBox(height: 6),
                      DribaShimmerBox(width: 80, height: 10, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── EMPTY & ERROR STATES ──────────────────────

/// Reusable empty state widget
class DribaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accent;

  const DribaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? DribaColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DribaSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color.withOpacity(0.5), size: 32),
            ),
            const SizedBox(height: DribaSpacing.xl),
            Text(
              title,
              style: const TextStyle(
                color: DribaColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DribaSpacing.sm),
            Text(
              subtitle,
              style: TextStyle(
                color: DribaColors.textTertiary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DribaSpacing.xl),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.xxl,
                    vertical: DribaSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable error state with retry
class DribaErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final Color? accent;

  const DribaErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please try again. If the problem persists, contact support.',
    this.onRetry,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DribaSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DribaColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: DribaColors.error, size: 32),
            ),
            const SizedBox(height: DribaSpacing.xl),
            Text(
              title,
              style: const TextStyle(
                color: DribaColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DribaSpacing.sm),
            Text(
              message,
              style: TextStyle(
                color: DribaColors.textTertiary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DribaSpacing.xl),
              GestureDetector(
                onTap: onRetry,
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.xxl,
                    vertical: DribaSpacing.md,
                  ),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: DribaColors.textPrimary, size: 18),
                      SizedBox(width: DribaSpacing.sm),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          color: DribaColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── ANIMATED COUNTER ──────────────────────────

/// Smooth animated number counter (for stats, prices)
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;
  final String? prefix;
  final String? suffix;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Text(
          '${widget.prefix ?? ""}${_animation.value.toInt()}${widget.suffix ?? ""}',
          style: widget.style,
        );
      },
    );
  }
}

/// Animated counter that formats large numbers (1.2K, 3.4M)
class AnimatedFormattedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;

  const AnimatedFormattedCounter({
    super.key,
    required this.value,
    required this.style,
  });

  static String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(_format(v), style: style),
    );
  }
}

// ── TOAST / SNACKBAR HELPER ───────────────────

class DribaToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    final accent = color ?? DribaColors.primary;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: DribaSpacing.sm),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: DribaColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: DribaColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
          side: BorderSide(color: accent.withOpacity(0.2)),
        ),
        duration: duration,
        margin: const EdgeInsets.fromLTRB(
            DribaSpacing.xl, 0, DribaSpacing.xl, DribaSpacing.xl),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, icon: Icons.check_circle, color: DribaColors.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, icon: Icons.error_outline, color: DribaColors.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, icon: Icons.info_outline, color: DribaColors.primary);
  }
}

// ── PULL TO REFRESH WRAPPER ───────────────────

class DribaRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? accent;

  const DribaRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: accent ?? DribaColors.primary,
      backgroundColor: DribaColors.surface,
      strokeWidth: 2.5,
      displacement: 60,
      child: child,
    );
  }
}

// ── KEYBOARD AWARE WRAPPER ────────────────────

class KeyboardAwareWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardAwareWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}

// ── ANIMATED PROGRESS BAR ─────────────────────

class AnimatedProgressBar extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final Color color;
  final double height;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (_, v, __) {
            return LinearProgressIndicator(
              value: v,
              backgroundColor: DribaColors.glassFillActive,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: height,
            );
          },
        ),
      ),
    );
  }
}

// ── PULSING DOT (LIVE INDICATOR) ──────────────

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = DribaColors.success,
    this.size = 8,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.6 + 0.4 * _controller.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _controller.value),
                blurRadius: widget.size * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── BADGE COUNTER ─────────────────────────────

class DribaBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const DribaBadge({
    super.key,
    required this.count,
    this.color = DribaColors.error,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 99 ? '99+' : '$count';

    return AnimatedScale(
      scale: count > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: Container(
        constraints: BoxConstraints(minWidth: size),
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
