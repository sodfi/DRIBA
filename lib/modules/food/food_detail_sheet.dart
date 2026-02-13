import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'food_models.dart';
import 'food_widgets.dart';
import '../../core/widgets/glass_bottom_sheet.dart';

/// Restaurant detail bottom sheet
/// Full menu, ratings, delivery info, add-to-cart
class FoodDetailSheet extends StatefulWidget {
  final FoodRestaurant restaurant;
  final Color accent;
  final List<CartItem> cartItems;
  final void Function(CartItem) onAddToCart;

  const FoodDetailSheet({
    super.key,
    required this.restaurant,
    required this.accent,
    required this.cartItems,
    required this.onAddToCart,
  });

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  late ScrollController _scrollController;
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (offset / 200).clamp(0.0, 1.0);
    });
  }

  void _handleAddToCart(FoodMenuItem item) {
    HapticFeedback.mediumImpact();
    widget.onAddToCart(CartItem(
      menuItem: item,
      restaurant: widget.restaurant,
    ));

    // Show brief confirmation
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.name} added to cart',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: widget.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DribaBorderRadius.md),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final r = widget.restaurant;

    return GlassBottomSheet(
      heightFraction: 0.92,
      showHandle: false,
      child: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero image
              SliverToBoxAdapter(child: _buildHeroImage(r)),

              // Restaurant info card
              SliverToBoxAdapter(child: _buildInfoSection(r)),

              // Quick stats row
              SliverToBoxAdapter(child: _buildStatsRow(r)),

              // Menu sections
              ...r.menu.map((section) => _buildMenuSection(section)),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),

          // Collapsing header bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildCollapsingHeader(r),
          ),
        ],
      ),
    );
  }

  // ── Hero Image ──────────────────────────────
  Widget _buildHeroImage(FoodRestaurant r) {
    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: r.coverUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: DribaColors.surface),
            errorWidget: (_, __, ___) => Container(
              color: DribaColors.surface,
              child: Icon(Icons.restaurant,
                  color: widget.accent.withOpacity(0.3), size: 48),
            ),
          ),
          // Bottom gradient
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, DribaColors.background],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SizedBox(height: 80),
            ),
          ),
          // Top rounded corners mask
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: DribaBorderRadius.xxl,
              decoration: const BoxDecoration(
                color: DribaColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DribaBorderRadius.xxl),
                ),
              ),
            ),
          ),
          // Close handle
          Positioned(
            top: DribaSpacing.md,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Section ────────────────────────────
  Widget _buildInfoSection(FoodRestaurant r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            r.name,
            style: const TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: DribaSpacing.sm),

          // Cuisines
          Text(
            r.cuisineTags
                .where((t) => t != 'nearby')
                .map((t) => t[0].toUpperCase() + t.substring(1))
                .join(' · '),
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: DribaSpacing.md),

          // Rating + reviews
          Row(
            children: [
              Icon(Icons.star_rounded, color: widget.accent, size: 20),
              const SizedBox(width: 4),
              Text(
                '${r.rating}',
                style: TextStyle(
                  color: widget.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${r.reviewCount} reviews)',
                style: TextStyle(
                  color: DribaColors.textTertiary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (r.dietaryOptions.isNotEmpty)
                ...r.dietaryOptions.map((tag) => Padding(
                      padding: const EdgeInsets.only(left: DribaSpacing.xs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DribaSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: DribaColors.success.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(DribaBorderRadius.sm),
                        ),
                        child: Text(
                          tag.replaceAll('-', ' '),
                          style: const TextStyle(
                            color: DribaColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ───────────────────────────────
  Widget _buildStatsRow(FoodRestaurant r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.xl,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: DribaSpacing.lg,
          vertical: DribaSpacing.md,
        ),
        borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.access_time_rounded,
              value: '${r.deliveryTimeMin}-${r.deliveryTimeMax}',
              label: 'min',
              accent: widget.accent,
            ),
            _divider(),
            _StatItem(
              icon: Icons.delivery_dining,
              value: r.deliveryFee == 0
                  ? 'Free'
                  : '\$${r.deliveryFee.toStringAsFixed(2)}',
              label: 'delivery',
              accent: widget.accent,
            ),
            _divider(),
            _StatItem(
              icon: Icons.location_on_outlined,
              value: r.distanceFormatted,
              label: 'away',
              accent: widget.accent,
            ),
            if (r.minimumOrder > 0) ...[
              _divider(),
              _StatItem(
                icon: Icons.shopping_bag_outlined,
                value: '\$${r.minimumOrder.toStringAsFixed(0)}',
                label: 'minimum',
                accent: widget.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: DribaColors.glassBorder,
    );
  }

  // ── Menu Section ────────────────────────────
  Widget _buildMenuSection(FoodMenuSection section) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(
                top: DribaSpacing.lg,
                bottom: DribaSpacing.md,
              ),
              child: Text(
                section.name,
                style: const TextStyle(
                  color: DribaColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Items
            ...section.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: DribaSpacing.md),
                  child: MenuItemCard(
                    item: item,
                    accent: widget.accent,
                    onAdd: () => _handleAddToCart(item),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Collapsing Header ───────────────────────
  Widget _buildCollapsingHeader(FoodRestaurant r) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _headerOpacity * 20,
          sigmaY: _headerOpacity * 20,
        ),
        child: AnimatedContainer(
          duration: DribaDurations.fast,
          padding: EdgeInsets.fromLTRB(
            DribaSpacing.lg,
            MediaQuery.of(context).padding.top + DribaSpacing.sm,
            DribaSpacing.lg,
            DribaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: DribaColors.background
                .withOpacity(_headerOpacity * 0.9),
            border: Border(
              bottom: BorderSide(
                color: DribaColors.glassBorder
                    .withOpacity(_headerOpacity),
              ),
            ),
          ),
          child: Row(
            children: [
              GlassCircleButton(
                size: 38,
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close_rounded,
                  color: DribaColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: DribaSpacing.md),
              Expanded(
                child: Opacity(
                  opacity: _headerOpacity,
                  child: Text(
                    r.name,
                    style: const TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Share button
              GlassCircleButton(
                size: 38,
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: const Icon(
                  Icons.share_outlined,
                  color: DribaColors.textPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: DribaSpacing.sm),
              // Favorite button
              GlassCircleButton(
                size: 38,
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: Icon(
                  Icons.favorite_outline,
                  color: widget.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Item Widget ──────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: DribaColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: DribaColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
