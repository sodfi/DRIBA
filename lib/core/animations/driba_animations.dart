import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/driba_colors.dart';

/// Driba Animation Utilities
/// Playful, rewarding animations that delight users

// ============================================
// ANIMATION CONTROLLERS & MIXINS
// ============================================

/// Mixin for widgets that need playful entrance animations
mixin PlayfulEntranceMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController entranceController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;

  void initEntranceAnimation({
    Duration duration = DribaDurations.normal,
    Offset slideFrom = const Offset(0, 0.1),
    double scaleFrom = 0.95,
  }) {
    entranceController = AnimationController(duration: duration, vsync: this);
    
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: entranceController, curve: DribaCurves.defaultCurve),
    );
    
    slideAnimation = Tween<Offset>(begin: slideFrom, end: Offset.zero).animate(
      CurvedAnimation(parent: entranceController, curve: DribaCurves.enter),
    );
    
    scaleAnimation = Tween<double>(begin: scaleFrom, end: 1.0).animate(
      CurvedAnimation(parent: entranceController, curve: DribaCurves.enter),
    );
  }

  void playEntrance() => entranceController.forward();
  
  void disposeEntrance() => entranceController.dispose();

  Widget buildEntranceAnimation({required Widget child}) {
    return AnimatedBuilder(
      animation: entranceController,
      builder: (context, _) => Opacity(
        opacity: fadeAnimation.value,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================
// LIKE / REACTION ANIMATION
// ============================================

/// Animated like button with particle burst effect
class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final Color likedColor;
  final Color unlikedColor;
  final double size;
  final IconData likedIcon;
  final IconData unlikedIcon;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.likedColor = DribaColors.secondary,
    this.unlikedColor = DribaColors.textSecondary,
    this.size = 28,
    this.likedIcon = Icons.favorite,
    this.unlikedIcon = Icons.favorite_border,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DribaDurations.normal,
      vsync: this,
    );
    _particleController = AnimationController(
      duration: DribaDurations.slow,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: DribaCurves.bounce),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0);
    if (!widget.isLiked) {
      _particleController.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size * 2,
        height: widget.size * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Particle burst
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                if (_particleController.value == 0) return const SizedBox();
                return CustomPaint(
                  size: Size(widget.size * 2, widget.size * 2),
                  painter: ParticleBurstPainter(
                    progress: _particleController.value,
                    color: widget.likedColor,
                  ),
                );
              },
            ),
            // Heart icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    widget.isLiked ? widget.likedIcon : widget.unlikedIcon,
                    size: widget.size,
                    color: widget.isLiked ? widget.likedColor : widget.unlikedColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Particle burst painter for like animation
class ParticleBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int particleCount;

  ParticleBurstPainter({
    required this.progress,
    required this.color,
    this.particleCount = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = maxRadius * progress;
      final particleSize = 4 * (1 - progress);
      final opacity = (1 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final particleCenter = Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      );

      canvas.drawCircle(particleCenter, particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticleBurstPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ============================================
// SLIDE TO ACTION BUTTON
// ============================================

/// Premium slide-to-action button for purchases, orders, confirmations
class SlideToActionButton extends StatefulWidget {
  final String label;
  final String completedLabel;
  final IconData icon;
  final IconData completedIcon;
  final Color backgroundColor;
  final Color sliderColor;
  final Color textColor;
  final VoidCallback onComplete;
  final double height;
  final double width;

  const SlideToActionButton({
    super.key,
    required this.label,
    this.completedLabel = 'Done!',
    this.icon = Icons.arrow_forward_ios,
    this.completedIcon = Icons.check,
    this.backgroundColor = DribaColors.glassFillActive,
    this.sliderColor = DribaColors.primary,
    this.textColor = DribaColors.textPrimary,
    required this.onComplete,
    this.height = 60,
    this.width = double.infinity,
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isCompleted = false;
  late AnimationController _completionController;
  late Animation<double> _completionAnimation;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      duration: DribaDurations.normal,
      vsync: this,
    );
    _completionAnimation = CurvedAnimation(
      parent: _completionController,
      curve: DribaCurves.bounce,
    );
  }

  @override
  void dispose() {
    _completionController.dispose();
    super.dispose();
  }

  double get _maxDrag => (context.size?.width ?? 300) - widget.height - 8;
  double get _progress => (_dragPosition / _maxDrag).clamp(0.0, 1.0);

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, _maxDrag);
    });
    
    if (_progress > 0.2) {
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isCompleted) return;

    if (_progress > 0.85) {
      _complete();
    } else {
      _reset();
    }
  }

  void _complete() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isCompleted = true;
      _dragPosition = _maxDrag;
    });
    _completionController.forward();
    widget.onComplete();
  }

  void _reset() {
    setState(() {
      _dragPosition = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: _isCompleted
            ? DribaColors.success.withOpacity(0.2)
            : widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: _isCompleted
              ? DribaColors.success
              : DribaColors.glassBorder,
        ),
      ),
      child: Stack(
        children: [
          // Progress fill
          AnimatedContainer(
            duration: DribaDurations.fast,
            width: _dragPosition + widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.sliderColor.withOpacity(0.3),
                  widget.sliderColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
          ),
          
          // Center label
          Center(
            child: AnimatedSwitcher(
              duration: DribaDurations.fast,
              child: Text(
                _isCompleted ? widget.completedLabel : widget.label,
                key: ValueKey(_isCompleted),
                style: TextStyle(
                  color: _isCompleted
                      ? DribaColors.success
                      : widget.textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          // Slider thumb
          Positioned(
            left: 4 + _dragPosition,
            top: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedBuilder(
                animation: _completionAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isCompleted ? 1.0 + (_completionAnimation.value * 0.1) : 1.0,
                    child: Container(
                      width: widget.height - 8,
                      height: widget.height - 8,
                      decoration: BoxDecoration(
                        color: _isCompleted
                            ? DribaColors.success
                            : widget.sliderColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isCompleted
                                    ? DribaColors.success
                                    : widget.sliderColor)
                                .withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: DribaDurations.fast,
                          child: Icon(
                            _isCompleted ? widget.completedIcon : widget.icon,
                            key: ValueKey(_isCompleted),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// SUCCESS / CONFIRMATION ANIMATION
// ============================================

/// Animated checkmark for confirmations
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 80,
    this.color = DribaColors.success,
    this.duration = DribaDurations.slow,
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: CheckmarkPainter(
              progress: _controller.value,
              color: widget.color,
              strokeWidth: widget.size * 0.08,
            ),
          );
        },
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Circle
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      paint,
    );

    // Checkmark
    if (progress > 0.5) {
      final checkProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      
      final start = Offset(size.width * 0.25, size.height * 0.5);
      final mid = Offset(size.width * 0.45, size.height * 0.7);
      final end = Offset(size.width * 0.75, size.height * 0.35);

      final path = Path();
      
      if (checkProgress <= 0.5) {
        final firstProgress = checkProgress * 2;
        final currentMid = Offset.lerp(start, mid, firstProgress)!;
        path.moveTo(start.dx, start.dy);
        path.lineTo(currentMid.dx, currentMid.dy);
      } else {
        path.moveTo(start.dx, start.dy);
        path.lineTo(mid.dx, mid.dy);
        final secondProgress = (checkProgress - 0.5) * 2;
        final currentEnd = Offset.lerp(mid, end, secondProgress)!;
        path.lineTo(currentEnd.dx, currentEnd.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ============================================
// SHIMMER LOADING EFFECT
// ============================================

/// Premium shimmer effect for loading states
class DribaShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const DribaShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = DribaColors.glassFill,
    this.highlightColor = DribaColors.glassFillActive,
  });

  @override
  State<DribaShimmer> createState() => _DribaShimmerState();
}

class _DribaShimmerState extends State<DribaShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
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
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

// ============================================
// STAGGERED LIST ANIMATION
// ============================================

/// Wrapper for staggered entrance animations in lists
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration staggerDelay;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DribaDurations.normal,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DribaCurves.defaultCurve),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: DribaCurves.enter),
    );

    Future.delayed(
      widget.baseDelay + (widget.staggerDelay * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
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
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ============================================
// PULSE ANIMATION
// ============================================

/// Subtle pulse animation for attention
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Color? pulseColor;
  final Duration duration;
  final bool enabled;

  const PulseAnimation({
    super.key,
    required this.child,
    this.pulseColor,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: (widget.pulseColor ?? DribaColors.primary)
                    .withOpacity(0.3 * _controller.value),
                blurRadius: 20 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
