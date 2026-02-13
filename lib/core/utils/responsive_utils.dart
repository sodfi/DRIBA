import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/driba_colors.dart';
import '../widgets/glass_container.dart';

// ============================================
// RESPONSIVE UTILITIES & EDGE CASE HELPERS
// Adaptive layout, safe area, connectivity,
// scroll behavior, overflow protection
// ============================================

// ── RESPONSIVE BREAKPOINTS ────────────────────

class DribaBreakpoints {
  static const double mobile = 375;
  static const double mobileLarge = 428;
  static const double tablet = 768;
  static const double desktop = 1024;
}

class DribaResponsive {
  final BuildContext context;
  DribaResponsive(this.context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;
  EdgeInsets get padding => MediaQuery.of(context).padding;
  double get topPad => padding.top;
  double get bottomPad => padding.bottom;
  double get keyboardHeight => MediaQuery.of(context).viewInsets.bottom;
  bool get isKeyboardOpen => keyboardHeight > 50;
  double get textScale => MediaQuery.of(context).textScaler.scale(1.0);

  bool get isMobile => width < DribaBreakpoints.tablet;
  bool get isTablet => width >= DribaBreakpoints.tablet && width < DribaBreakpoints.desktop;
  bool get isDesktop => width >= DribaBreakpoints.desktop;

  bool get isSmallPhone => width < DribaBreakpoints.mobile;
  bool get isLargePhone => width >= DribaBreakpoints.mobileLarge;

  /// Horizontal padding that adapts to screen width
  double get horizontalPadding {
    if (isSmallPhone) return DribaSpacing.lg;
    if (isMobile) return DribaSpacing.xl;
    if (isTablet) return DribaSpacing.xxl;
    return DribaSpacing.xxxl;
  }

  /// Grid columns based on screen width
  int get gridColumns {
    if (isSmallPhone) return 2;
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }

  /// Card aspect ratio for product/course grids
  double get gridAspectRatio {
    if (isSmallPhone) return 0.72;
    if (isMobile) return 0.78;
    return 0.82;
  }
}

extension ResponsiveContext on BuildContext {
  DribaResponsive get responsive => DribaResponsive(this);
}

// ── SAFE AREA SCAFFOLD ────────────────────────

/// Scaffold with proper safe area handling for glass OS
class DribaSafeScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBehindAppBar;

  const DribaSafeScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.extendBody = true,
    this.extendBehindAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? DribaColors.background,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBehindAppBar,
      body: body,
    );
  }
}

// ── CONNECTION BANNER ─────────────────────────

/// Offline/reconnecting indicator banner
class ConnectionBanner extends StatelessWidget {
  final bool isOnline;
  final bool isReconnecting;

  const ConnectionBanner({
    super.key,
    this.isOnline = true,
    this.isReconnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && !isReconnecting) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOnline ? 0 : 36,
      color: isReconnecting
          ? const Color(0xFFFF6B35).withOpacity(0.15)
          : DribaColors.error.withOpacity(0.15),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReconnecting) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(const Color(0xFFFF6B35)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Reconnecting...',
                style: TextStyle(
                  color: const Color(0xFFFF6B35),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Icon(Icons.wifi_off, color: DribaColors.error, size: 14),
              const SizedBox(width: 8),
              Text(
                'No connection',
                style: TextStyle(
                  color: DribaColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── OVERFLOW SAFE TEXT ─────────────────────────

/// Text widget that prevents overflow with ellipsis
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  const SafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}

// ── BOTTOM SHEET HANDLE ───────────────────────

/// Standard drag handle for bottom sheets
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: DribaSpacing.md, bottom: DribaSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: DribaColors.glassBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ── CONDITIONAL WRAPPER ───────────────────────

/// Wraps child with a widget only if condition is true
class ConditionalWrapper extends StatelessWidget {
  final bool condition;
  final Widget Function(Widget child) wrapper;
  final Widget child;

  const ConditionalWrapper({
    super.key,
    required this.condition,
    required this.wrapper,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? wrapper(child) : child;
  }
}

// ── IMAGE WITH FALLBACK ───────────────────────

/// Network image with loading shimmer and error fallback
class DribaNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double borderRadius;

  const DribaNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: DribaColors.glassFill,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation(DribaColors.primary),
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            width: width,
            height: height,
            color: DribaColors.glassFill,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: DribaColors.textDisabled,
              size: 24,
            ),
          );
        },
      ),
    );
  }
}

// ── GLASS DIVIDER ─────────────────────────────

class GlassDivider extends StatelessWidget {
  final double indent;

  const GlassDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Divider(height: 1, color: DribaColors.glassBorder),
    );
  }
}
