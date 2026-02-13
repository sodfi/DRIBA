import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/providers/app_state.dart';
import '../../core/widgets/glass_bottom_sheet.dart';

/// Screens View - Pinterest-style masonry grid
/// Shows live previews of each enabled screen
/// Users can tap to enter a screen or long-press to customize
class ScreensViewScreen extends ConsumerStatefulWidget {
  const ScreensViewScreen({super.key});

  @override
  ConsumerState<ScreensViewScreen> createState() => _ScreensViewScreenState();
}

class _ScreensViewScreenState extends ConsumerState<ScreensViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: DribaDurations.slow,
      vsync: this,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabledScreens = ref.watch(enabledScreensProvider);
    
    // Get full config for enabled screens
    final screenConfigs = allScreens
        .where((s) => enabledScreens.contains(s.id) || s.id == 'feed')
        .toList();

    return Scaffold(
      backgroundColor: DribaColors.background,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // Header space
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 80,
                ),
              ),
              
              // Masonry grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: DribaSpacing.md,
                    crossAxisSpacing: DribaSpacing.md,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Add button at the end
                      if (index == screenConfigs.length) {
                        return _AddScreenCard(
                          onTap: () => _showAddScreenSheet(),
                        );
                      }
                      
                      return _ScreenPreviewCard(
                        config: screenConfigs[index],
                        index: index,
                        isEditMode: _isEditMode,
                        entranceController: _entranceController,
                        onTap: () => _navigateToScreen(screenConfigs[index]),
                        onLongPress: () => _showScreenOptions(screenConfigs[index]),
                      );
                    },
                    childCount: screenConfigs.length + 1,
                  ),
                ),
              ),
              
              // Bottom padding for dock
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
          
          // Glass Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassHeader(
              title: 'My Screens',
              screenId: 'screens',
              onSearchTap: () {
                // Search screens
              },
              actionIcon: _isEditMode ? Icons.check : Icons.edit_outlined,
              onActionTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isEditMode = !_isEditMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(ScreenConfig config) {
    HapticFeedback.lightImpact();
    
    // Update selected screen and navigate
    ref.read(selectedScreenProvider.notifier).state = config.id;
    ref.read(currentDockIndexProvider.notifier).state = 0; // Go to feed
    ref.read(currentPageIndexProvider.notifier).state = 0;
  }

  void _showScreenOptions(ScreenConfig config) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScreenOptionsSheet(
        config: config,
        onRemove: () {
          // Remove screen from user's enabled screens
          Navigator.pop(context);
        },
        onCustomize: () {
          // Open customization
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddScreenSheet() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _AddScreenSheet(),
    );
  }
}

/// Individual screen preview card with live preview effect
class _ScreenPreviewCard extends StatefulWidget {
  final ScreenConfig config;
  final int index;
  final bool isEditMode;
  final AnimationController entranceController;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ScreenPreviewCard({
    required this.config,
    required this.index,
    required this.isEditMode,
    required this.entranceController,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_ScreenPreviewCard> createState() => _ScreenPreviewCardState();
}

class _ScreenPreviewCardState extends State<_ScreenPreviewCard> {
  bool _isPressed = false;

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home': return Icons.home_outlined;
      case 'restaurant': return Icons.restaurant_outlined;
      case 'shopping_bag': return Icons.shopping_bag_outlined;
      case 'flight': return Icons.flight_outlined;
      case 'favorite': return Icons.favorite_outline;
      case 'newspaper': return Icons.newspaper_outlined;
      case 'school': return Icons.school_outlined;
      case 'movie': return Icons.movie_outlined;
      case 'place': return Icons.place_outlined;
      case 'music_note': return Icons.music_note_outlined;
      case 'sports_esports': return Icons.sports_esports_outlined;
      case 'sports_soccer': return Icons.sports_soccer_outlined;
      case 'account_balance': return Icons.account_balance_outlined;
      case 'directions_car': return Icons.directions_car_outlined;
      case 'pets': return Icons.pets_outlined;
      case 'home_work': return Icons.home_work_outlined;
      case 'checkroom': return Icons.checkroom_outlined;
      case 'face': return Icons.face_outlined;
      case 'weekend': return Icons.weekend_outlined;
      case 'event': return Icons.event_outlined;
      case 'child_care': return Icons.child_care_outlined;
      default: return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(widget.config.color);
    final delay = widget.index * 0.1;
    
    return AnimatedBuilder(
      animation: widget.entranceController,
      builder: (context, child) {
        final progress = ((widget.entranceController.value - delay) / (1 - delay))
            .clamp(0.0, 1.0);
        
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - progress)),
            child: Transform.scale(
              scale: 0.9 + (0.1 * progress),
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: DribaDurations.fast,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: DribaBlur.medium, sigmaY: DribaBlur.medium),
              child: Container(
                decoration: BoxDecoration(
                  color: DribaColors.glassFill,
                  borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                  border: Border.all(
                    color: _isPressed ? accentColor : DribaColors.glassBorder,
                    width: 1,
                  ),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ]
                      : DribaShadows.glass,
                ),
                child: Stack(
                  children: [
                    // Fake content preview
                    _buildContentPreview(accentColor),
                    
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              DribaColors.background.withOpacity(0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // Screen info
                    Positioned(
                      left: DribaSpacing.md,
                      right: DribaSpacing.md,
                      bottom: DribaSpacing.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconData(widget.config.icon),
                                  color: accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: DribaSpacing.sm),
                              Expanded(
                                child: Text(
                                  widget.config.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: DribaColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Edit mode indicator
                    if (widget.isEditMode)
                      Positioned(
                        top: DribaSpacing.sm,
                        right: DribaSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: DribaColors.error.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(Color accentColor) {
    // Simulated content preview
    return Padding(
      padding: const EdgeInsets.all(DribaSpacing.md),
      child: Column(
        children: [
          // Fake post cards
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: DribaSpacing.sm),
                  height: 60,
                  decoration: BoxDecoration(
                    color: DribaColors.glassFill,
                    borderRadius: BorderRadius.circular(DribaBorderRadius.md),
                    border: Border.all(color: DribaColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(DribaBorderRadius.md),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: DribaColors.glassFillActive,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 6,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: DribaColors.glassBorder,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Add screen card
class _AddScreenCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddScreenCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DribaColors.glassFill,
          borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
          border: Border.all(
            color: DribaColors.glassBorder,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DribaColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DribaColors.primary.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: DribaColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: DribaSpacing.md),
              const Text(
                'Add Screen',
                style: TextStyle(
                  color: DribaColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen options bottom sheet
class _ScreenOptionsSheet extends StatelessWidget {
  final ScreenConfig config;
  final VoidCallback onRemove;
  final VoidCallback onCustomize;

  const _ScreenOptionsSheet({
    required this.config,
    required this.onRemove,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(config.color);
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(DribaBorderRadius.xxl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(DribaSpacing.xl),
          decoration: BoxDecoration(
            color: const Color(0xFF060E1A).withOpacity(0.78),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DribaColors.glassBorderHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: DribaSpacing.xl),
              
              // Screen name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.grid_view,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: DribaSpacing.md),
                  Text(
                    config.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DribaSpacing.xl),
              
              // Options
              _OptionTile(
                icon: Icons.tune,
                label: 'Customize',
                onTap: onCustomize,
              ),
              _OptionTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              _OptionTile(
                icon: Icons.remove_circle_outline,
                label: 'Remove Screen',
                color: DribaColors.error,
                onTap: onRemove,
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? DribaColors.textPrimary),
      title: Text(
        label,
        style: TextStyle(color: color ?? DribaColors.textPrimary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: DribaColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}

/// Add screen sheet
class _AddScreenSheet extends ConsumerWidget {
  const _AddScreenSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledScreens = ref.watch(enabledScreensProvider);
    final availableScreens = allScreens
        .where((s) => !enabledScreens.contains(s.id) && s.id != 'feed')
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DribaBorderRadius.xxl),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: DribaBlur.heavy, sigmaY: DribaBlur.heavy),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF060E1A).withOpacity(0.78),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DribaBorderRadius.xxl),
                ),
                border: Border.all(color: DribaColors.glassBorder),
              ),
              child: Column(
                children: [
                  // Handle and title
                  Padding(
                    padding: const EdgeInsets.all(DribaSpacing.lg),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: DribaColors.glassBorderHighlight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: DribaSpacing.lg),
                        const Text(
                          'Add Screens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: DribaSpacing.xs),
                        const Text(
                          'Choose which worlds you want to explore',
                          style: TextStyle(
                            color: DribaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Screen list
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(DribaSpacing.lg),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: DribaSpacing.md,
                        crossAxisSpacing: DribaSpacing.md,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: availableScreens.length,
                      itemBuilder: (context, index) {
                        final screen = availableScreens[index];
                        final color = Color(screen.color);
                        
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            // Add screen to user's enabled screens
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: DribaColors.glassFill,
                              borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                              border: Border.all(color: DribaColors.glassBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: DribaSpacing.sm),
                                Text(
                                  screen.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
