import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'food_models.dart';

// ============================================
// RESTAURANT CARD
// Glass card with image, rating, delivery info
// ============================================

class RestaurantCard extends StatelessWidget {
  final FoodRestaurant restaurant;
  final Color accent;
  final VoidCallback? onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(DribaBorderRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: DribaColors.surface,
                        child: Center(
                          child: Icon(Icons.restaurant, color: accent.withOpacity(0.3)),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: DribaColors.surface,
                        child: Icon(Icons.restaurant, color: accent.withOpacity(0.3)),
                      ),
                    ),
                    // Badges overlay
                    Positioned(
                      top: DribaSpacing.sm,
                      left: DribaSpacing.sm,
                      child: Row(
                        children: [
                          if (restaurant.promoText != null)
                            _Badge(text: restaurant.promoText!, color: accent),
                          if (restaurant.deliveryFee == 0 && restaurant.promoText == null)
                            _Badge(text: 'FREE DELIVERY', color: DribaColors.success),
                        ],
                      ),
                    ),
                    // Delivery time pill
                    Positioned(
                      bottom: DribaSpacing.sm,
                      right: DribaSpacing.sm,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(DribaBorderRadius.sm),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DribaSpacing.sm,
                              vertical: DribaSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: DribaColors.background.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(DribaBorderRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    color: DribaColors.textPrimary, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  restaurant.deliveryTimeRange,
                                  style: const TextStyle(
                                    color: DribaColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!restaurant.isOpen)
                      Container(
                        color: DribaColors.background.withOpacity(0.6),
                        child: const Center(
                          child: Text(
                            'CLOSED',
                            style: TextStyle(
                              color: DribaColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DribaSpacing.md, DribaSpacing.md, DribaSpacing.md, DribaSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DribaSpacing.sm,
                          vertical: DribaSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(DribaBorderRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: accent, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${restaurant.rating}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: DribaSpacing.xs),

                  // Meta row
                  Row(
                    children: [
                      // Cuisines
                      Expanded(
                        child: Text(
                          restaurant.cuisineTags
                              .where((t) => t != 'nearby')
                              .map((t) => t[0].toUpperCase() + t.substring(1))
                              .join(' · '),
                          style: TextStyle(
                            color: DribaColors.textTertiary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Distance
                      Text(
                        restaurant.distanceFormatted,
                        style: TextStyle(
                          color: DribaColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Dietary tags
                  if (restaurant.dietaryOptions.isNotEmpty) ...[
                    const SizedBox(height: DribaSpacing.sm),
                    Wrap(
                      spacing: DribaSpacing.xs,
                      children: restaurant.dietaryOptions.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DribaSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DribaColors.glassFill,
                            borderRadius: BorderRadius.circular(DribaBorderRadius.xs),
                            border: Border.all(color: DribaColors.glassBorder),
                          ),
                          child: Text(
                            tag.replaceAll('-', ' '),
                            style: const TextStyle(
                              color: DribaColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DribaSpacing.sm,
        vertical: DribaSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DribaBorderRadius.sm),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================
// MENU ITEM CARD
// Used in restaurant detail sheet
// ============================================

class MenuItemCard extends StatelessWidget {
  final FoodMenuItem item;
  final Color accent;
  final VoidCallback? onAdd;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.accent,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.md),
      borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                if (item.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DribaSpacing.xs),
                    child: Wrap(
                      spacing: DribaSpacing.xs,
                      children: item.tags.map((tag) {
                        final color = tag == 'popular'
                            ? accent
                            : tag == 'new'
                                ? DribaColors.success
                                : DribaColors.warning;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Name
                Text(
                  item.name,
                  style: const TextStyle(
                    color: DribaColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: DribaSpacing.xxs),

                // Description
                Text(
                  item.description,
                  style: TextStyle(
                    color: DribaColors.textTertiary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: DribaSpacing.sm),

                // Price + calories
                Row(
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.hasDiscount) ...[
                      const SizedBox(width: DribaSpacing.xs),
                      Text(
                        '\$${item.originalPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: DribaColors.textDisabled,
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (item.calories > 0)
                      Text(
                        '${item.calories} cal',
                        style: TextStyle(
                          color: DribaColors.textDisabled,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: DribaSpacing.md),

          // Image + add button
          Column(
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(DribaBorderRadius.md),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 80,
                      height: 80,
                      color: DribaColors.surface,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: DribaColors.surface,
                      child: Icon(Icons.fastfood, color: accent.withOpacity(0.3)),
                    ),
                  ),
                ),
              const SizedBox(height: DribaSpacing.sm),
              // Add button
              GestureDetector(
                onTap: item.isAvailable ? onAdd : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DribaSpacing.lg,
                    vertical: DribaSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: item.isAvailable
                        ? accent.withOpacity(0.15)
                        : DribaColors.glassFill,
                    borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                    border: Border.all(
                      color: item.isAvailable ? accent : DribaColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    item.isAvailable ? 'ADD' : 'N/A',
                    style: TextStyle(
                      color: item.isAvailable ? accent : DribaColors.textDisabled,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
