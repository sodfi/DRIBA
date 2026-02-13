import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/driba_colors.dart';
import '../widgets/glass_container.dart';

/// Unified Glass Header for all screens
/// Shows dynamic icons based on current screen
/// Consistent styling across the entire app
class GlassHeader extends StatelessWidget {
  final String? title;
  final String screenId;
  final VoidCallback? onLogoTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final Widget? trailing;
  final bool showSearch;
  final bool showLogo;
  final double height;
  final Color? accentColor;

  const GlassHeader({
    super.key,
    this.title,
    this.screenId = 'feed',
    this.onLogoTap,
    this.onSearchTap,
    this.onActionTap,
    this.actionIcon,
    this.trailing,
    this.showSearch = true,
    this.showLogo = true,
    this.height = 60,
    this.accentColor,
  });

  /// Get the icon for each screen type
  IconData _getScreenIcon(String id) {
    switch (id.toLowerCase()) {
      case 'feed':
        return Icons.auto_awesome;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'food':
        return Icons.restaurant_outlined;
      case 'commerce':
        return Icons.shopping_bag_outlined;
      case 'travel':
        return Icons.flight_outlined;
      case 'health':
        return Icons.favorite_outline;
      case 'news':
        return Icons.newspaper_outlined;
      case 'learn':
        return Icons.school_outlined;
      case 'movies':
        return Icons.movie_outlined;
      case 'local':
        return Icons.place_outlined;
      case 'utility':
        return Icons.grid_view_outlined;
      case 'profile':
        return Icons.person_outline;
      case 'creator':
        return Icons.add_circle_outline;
      case 'screens':
        return Icons.dashboard_outlined;
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? DribaColors.getScreenAccent(screenId);
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DribaBlur.medium, sigmaY: DribaBlur.medium),
        child: Container(
          height: height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: DribaSpacing.lg,
            right: DribaSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DribaColors.background.withOpacity(0.8),
                DribaColors.background.withOpacity(0.0),
              ],
            ),
          ),
          child: Row(
            children: [
              // Logo / Screen Icon
              if (showLogo)
                GlassCircleButton(
                  size: 44,
                  onTap: onLogoTap,
                  child: Icon(
                    _getScreenIcon(screenId),
                    color: effectiveAccent,
                    size: 22,
                  ),
                ),

              // Title
              if (title != null) ...[
                const SizedBox(width: DribaSpacing.md),
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: DribaColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),

              // Trailing widgets
              if (trailing != null)
                trailing!
              else ...[
                // Action button (if provided)
                if (onActionTap != null && actionIcon != null) ...[
                  GlassCircleButton(
                    size: 44,
                    onTap: onActionTap,
                    child: Icon(
                      actionIcon,
                      color: DribaColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: DribaSpacing.sm),
                ],
                
                // Search button
                if (showSearch)
                  GlassCircleButton(
                    size: 44,
                    onTap: onSearchTap,
                    child: const Icon(
                      Icons.search,
                      color: DribaColors.textPrimary,
                      size: 22,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated header that hides on scroll
class CollapsibleGlassHeader extends StatefulWidget {
  final String? title;
  final String screenId;
  final ScrollController scrollController;
  final VoidCallback? onSearchTap;
  final double expandedHeight;
  final Widget? flexibleContent;

  const CollapsibleGlassHeader({
    super.key,
    this.title,
    this.screenId = 'feed',
    required this.scrollController,
    this.onSearchTap,
    this.expandedHeight = 120,
    this.flexibleContent,
  });

  @override
  State<CollapsibleGlassHeader> createState() => _CollapsibleGlassHeaderState();
}

class _CollapsibleGlassHeaderState extends State<CollapsibleGlassHeader> {
  double _opacity = 1.0;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.offset;
    setState(() {
      _scrollOffset = offset;
      _opacity = (1 - (offset / 100)).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: widget.expandedHeight,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DribaBlur.medium,
              sigmaY: DribaBlur.medium,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DribaColors.background.withOpacity(0.9),
                    DribaColors.background.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Opacity(
                  opacity: _opacity,
                  child: widget.flexibleContent ?? const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      ),
      title: AnimatedOpacity(
        duration: DribaDurations.fast,
        opacity: _scrollOffset > 50 ? 1.0 : 0.0,
        child: Text(
          widget.title?.toUpperCase() ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      actions: [
        if (widget.onSearchTap != null)
          Padding(
            padding: const EdgeInsets.only(right: DribaSpacing.lg),
            child: GlassCircleButton(
              size: 40,
              onTap: widget.onSearchTap,
              child: const Icon(
                Icons.search,
                color: DribaColors.textPrimary,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}

/// Header with filter pills
class GlassHeaderWithFilters extends StatelessWidget {
  final String? title;
  final String screenId;
  final List<String> filters;
  final int selectedFilterIndex;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback? onSearchTap;
  final Color? accentColor;

  const GlassHeaderWithFilters({
    super.key,
    this.title,
    this.screenId = 'feed',
    required this.filters,
    required this.selectedFilterIndex,
    required this.onFilterSelected,
    this.onSearchTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? DribaColors.getScreenAccent(screenId);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassHeader(
          title: title,
          screenId: screenId,
          onSearchTap: onSearchTap,
          accentColor: effectiveAccent,
        ),
        
        // Filter pills
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedFilterIndex;
              
              return Padding(
                padding: const EdgeInsets.only(right: DribaSpacing.sm),
                child: GlassPill(
                  label: filters[index],
                  isSelected: isSelected,
                  selectedColor: effectiveAccent,
                  onTap: () => onFilterSelected(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
