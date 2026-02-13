import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/driba_colors.dart';

/// The floating Glass Dock navigation bar
/// Fades to subtle opacity when inactive to not obscure content
/// Premium glass morphism design
class GlassDock extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onCreateTap;
  final Duration inactivityDuration;
  final double activeOpacity;
  final double inactiveOpacity;

  const GlassDock({
    super.key,
    required this.currentIndex,
    required this.onItemTap,
    required this.onCreateTap,
    this.inactivityDuration = const Duration(seconds: 3),
    this.activeOpacity = 1.0,
    this.inactiveOpacity = 0.3,
  });

  @override
  State<GlassDock> createState() => _GlassDockState();
}

class _GlassDockState extends State<GlassDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _opacityAnimation;
  bool _isActive = true;
  DateTime _lastInteraction = DateTime.now();

  // Dock items configuration
  static const List<DockItem> _items = [
    DockItem(icon: Icons.chat_bubble_outline, label: 'Chat', index: -1),
    DockItem(icon: Icons.grid_view_rounded, label: 'Screens', index: 1),
    DockItem(icon: Icons.add, label: 'Create', index: 999, isCreate: true),
    DockItem(icon: Icons.home_outlined, label: 'Feed', index: 0),
    DockItem(icon: Icons.bolt_outlined, label: 'Utility', index: 2),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: DribaDurations.slow,
      vsync: this,
    );
    
    _opacityAnimation = Tween<double>(
      begin: widget.activeOpacity,
      end: widget.inactiveOpacity,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: DribaCurves.defaultCurve,
    ));

    _startInactivityTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startInactivityTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      
      final timeSinceLastInteraction = 
          DateTime.now().difference(_lastInteraction);
      
      if (timeSinceLastInteraction > widget.inactivityDuration && _isActive) {
        setState(() => _isActive = false);
        _fadeController.forward();
      }
      
      return true;
    });
  }

  void _onInteraction() {
    _lastInteraction = DateTime.now();
    if (!_isActive) {
      setState(() => _isActive = true);
      _fadeController.reverse();
    }
  }

  void _handleItemTap(DockItem item) {
    HapticFeedback.lightImpact();
    _onInteraction();
    
    if (item.isCreate) {
      widget.onCreateTap();
    } else {
      widget.onItemTap(item.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onInteraction(),
      onPointerMove: (_) => _onInteraction(),
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          );
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + DribaSpacing.lg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: DribaBlur.heavy,
                  sigmaY: DribaBlur.heavy,
                ),
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: DribaColors.glassFill,
                    borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    border: Border.all(
                      color: DribaColors.glassBorder,
                      width: 1,
                    ),
                    boxShadow: DribaShadows.elevated,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _items.map((item) {
                      return _DockItemWidget(
                        item: item,
                        isSelected: item.index == widget.currentIndex,
                        onTap: () => _handleItemTap(item),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual dock item widget with animations
class _DockItemWidget extends StatefulWidget {
  final DockItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DockItemWidget> createState() => _DockItemWidgetState();
}

class _DockItemWidgetState extends State<_DockItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DribaDurations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: DribaCurves.defaultCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.item.isCreate;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: DribaDurations.fast,
          curve: DribaCurves.defaultCurve,
          margin: const EdgeInsets.symmetric(horizontal: DribaSpacing.sm),
          padding: const EdgeInsets.all(DribaSpacing.md),
          decoration: BoxDecoration(
            color: widget.isSelected && !isCreate
                ? DribaColors.primary.withOpacity(0.15)
                : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: widget.isSelected && !isCreate
                ? [
                    BoxShadow(
                      color: DribaColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          child: isCreate
              ? _CreateButton(isPressed: _isPressed)
              : Icon(
                  widget.item.icon,
                  color: widget.isSelected
                      ? DribaColors.primary
                      : DribaColors.textTertiary,
                  size: 26,
                ),
        ),
      ),
    );
  }
}

/// Special create button with gradient
class _CreateButton extends StatelessWidget {
  final bool isPressed;

  const _CreateButton({required this.isPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DribaDurations.fast,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: DribaColors.premiumGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: DribaColors.secondary.withOpacity(isPressed ? 0.6 : 0.4),
            blurRadius: isPressed ? 20 : 15,
            spreadRadius: isPressed ? 2 : 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: DribaColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: DribaColors.secondary,
          size: 24,
        ),
      ),
    );
  }
}

/// Dock item data model
class DockItem {
  final IconData icon;
  final String label;
  final int index;
  final bool isCreate;

  const DockItem({
    required this.icon,
    required this.label,
    required this.index,
    this.isCreate = false,
  });
}
