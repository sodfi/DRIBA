import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/driba_colors.dart';

/// Premium Glass Container
/// The foundational glass morphism component for Driba OS
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurIntensity;
  final bool isCircle;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool enableHaptics;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurIntensity = DribaBlur.medium,
    this.isCircle = false,
    this.boxShadow,
    this.gradient,
    this.onTap,
    this.enableHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = isCircle
        ? BorderRadius.circular(DribaBorderRadius.circle)
        : (borderRadius ?? BorderRadius.circular(DribaBorderRadius.lg));

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: boxShadow ?? DribaShadows.glass,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurIntensity,
            sigmaY: blurIntensity,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ?? DribaColors.glassGradient,
              color: gradient == null
                  ? (fillColor ?? DribaColors.glassFill)
                  : null,
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: borderColor ?? DribaColors.glassBorder,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      container = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }

    return container;
  }
}

/// Animated Glass Container with hover and press states
class AnimatedGlassContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final Color? activeFillColor;
  final Color? borderColor;
  final Color? activeBorderColor;
  final double blurIntensity;
  final bool isCircle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Color? selectedGlowColor;
  final Duration animationDuration;

  const AnimatedGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.fillColor,
    this.activeFillColor,
    this.borderColor,
    this.activeBorderColor,
    this.blurIntensity = DribaBlur.medium,
    this.isCircle = false,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.selectedGlowColor,
    this.animationDuration = DribaDurations.fast,
  });

  @override
  State<AnimatedGlassContainer> createState() => _AnimatedGlassContainerState();
}

class _AnimatedGlassContainerState extends State<AnimatedGlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: DribaCurves.defaultCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = widget.isCircle
        ? BorderRadius.circular(DribaBorderRadius.circle)
        : (widget.borderRadius ?? BorderRadius.circular(DribaBorderRadius.lg));

    final isActive = _isPressed || widget.isSelected;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: widget.animationDuration,
              curve: DribaCurves.defaultCurve,
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                boxShadow: [
                  ...DribaShadows.glass,
                  if (widget.isSelected)
                    BoxShadow(
                      color: (widget.selectedGlowColor ?? DribaColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: effectiveBorderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blurIntensity,
                    sigmaY: widget.blurIntensity,
                  ),
                  child: AnimatedContainer(
                    duration: widget.animationDuration,
                    curve: DribaCurves.defaultCurve,
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (widget.activeFillColor ?? DribaColors.glassFillActive)
                          : (widget.fillColor ?? DribaColors.glassFill),
                      borderRadius: effectiveBorderRadius,
                      border: Border.all(
                        color: isActive
                            ? (widget.activeBorderColor ?? DribaColors.glassBorderHighlight)
                            : (widget.borderColor ?? DribaColors.glassBorder),
                        width: 1.0,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Glass Card specifically for content cards
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool showAccentBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.accentColor,
    this.showAccentBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedGlassContainer(
      padding: padding ?? const EdgeInsets.all(DribaSpacing.lg),
      margin: margin,
      borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
      borderColor: showAccentBorder
          ? accentColor ?? DribaColors.primary
          : null,
      selectedGlowColor: accentColor,
      onTap: onTap,
      child: child,
    );
  }
}

/// Circular glass button (for dock icons, actions)
class GlassCircleButton extends StatelessWidget {
  final Widget child;
  final double size;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;

  const GlassCircleButton({
    super.key,
    required this.child,
    this.size = 48,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedGlassContainer(
      width: size,
      height: size,
      isCircle: true,
      isSelected: isSelected,
      selectedGlowColor: selectedColor ?? DribaColors.primary,
      activeFillColor: isSelected
          ? (selectedColor ?? DribaColors.primary).withOpacity(0.2)
          : null,
      onTap: onTap,
      child: Center(child: child),
    );
  }
}

/// Glass pill for filters and tags
class GlassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final EdgeInsetsGeometry? padding;

  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor = selectedColor ?? DribaColors.primary;
    
    return AnimatedGlassContainer(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: DribaSpacing.lg,
        vertical: DribaSpacing.sm,
      ),
      borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
      isSelected: isSelected,
      selectedGlowColor: effectiveSelectedColor,
      fillColor: isSelected
          ? effectiveSelectedColor.withOpacity(0.2)
          : DribaColors.glassFill,
      borderColor: isSelected
          ? effectiveSelectedColor
          : DribaColors.glassBorder,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? effectiveSelectedColor
                  : DribaColors.textSecondary,
            ),
            const SizedBox(width: DribaSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? effectiveSelectedColor
                  : DribaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
