import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/driba_colors.dart';

// ============================================
// GLASS BOTTOM SHEET
//
// Unified glassmorphic bottom sheet container.
// Every bottom sheet in Driba wraps its content
// with this for consistent blur + frosted glass.
//
// Usage:
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.transparent,
//     isScrollControlled: true,
//     builder: (_) => GlassBottomSheet(
//       child: YourContent(),
//     ),
//   );
//
// Or for a specific height fraction:
//   GlassBottomSheet(
//     heightFraction: 0.75,
//     child: YourContent(),
//   )
// ============================================

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? heightFraction; // null = wrap content
  final double blurSigma;
  final double borderRadius;
  final bool showHandle;
  final EdgeInsetsGeometry? padding;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.heightFraction,
    this.blurSigma = 40,
    this.borderRadius = 28,
    this.showHandle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    Widget content = Column(
      mainAxisSize: heightFraction != null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (showHandle) ...[
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (heightFraction != null)
          Expanded(
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          )
        else
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          height: heightFraction != null ? screenHeight * heightFraction! : null,
          decoration: BoxDecoration(
            color: const Color(0xFF060E1A).withOpacity(0.78),
            borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
              left: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
              right: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  /// Convenience: show a glass bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    double? heightFraction,
    bool isScrollControlled = true,
    bool showHandle = true,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (ctx) => GlassBottomSheet(
        heightFraction: heightFraction,
        showHandle: showHandle,
        padding: padding,
        child: builder(ctx),
      ),
    );
  }
}
