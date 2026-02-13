import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'commerce_models.dart';

// ============================================
// PRODUCT CARD — Grid item (2 per row)
// ============================================

class ProductCard extends StatelessWidget {
  final CommerceProduct product;
  final Color accent;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
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
            // Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: DribaColors.surface,
                        child: Center(
                          child: Icon(Icons.shopping_bag_outlined,
                              color: accent.withOpacity(0.2)),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: DribaColors.surface,
                        child: Icon(Icons.shopping_bag_outlined,
                            color: accent.withOpacity(0.2)),
                      ),
                    ),

                    // Badges
                    if (product.badge != null)
                      Positioned(
                        top: DribaSpacing.sm,
                        left: DribaSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DribaSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: _badgeColor(product.badge!),
                            borderRadius:
                                BorderRadius.circular(DribaBorderRadius.xs),
                          ),
                          child: Text(
                            product.badge!,
                            style: TextStyle(
                              color: _badgeTextColor(product.badge!),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Discount badge
                    if (product.hasDiscount && product.badge == null)
                      Positioned(
                        top: DribaSpacing.sm,
                        left: DribaSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DribaSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: DribaColors.error,
                            borderRadius:
                                BorderRadius.circular(DribaBorderRadius.xs),
                          ),
                          child: Text(
                            '-${product.discountPercent.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                    // Digital / Free shipping indicator
                    Positioned(
                      bottom: DribaSpacing.sm,
                      right: DribaSpacing.sm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (product.isDigital)
                            _SmallTag(
                                icon: Icons.cloud_download_outlined,
                                label: 'Digital',
                                color: accent),
                          if (product.isFreeShipping && !product.isDigital)
                            _SmallTag(
                                icon: Icons.local_shipping_outlined,
                                label: 'Free',
                                color: DribaColors.success),
                        ],
                      ),
                    ),

                    // Low stock
                    if (product.stockCount != null && product.stockCount! <= 5)
                      Positioned(
                        bottom: DribaSpacing.sm,
                        left: DribaSpacing.sm,
                        child: _SmallTag(
                          icon: Icons.warning_amber_rounded,
                          label: '${product.stockCount} left',
                          color: DribaColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    DribaSpacing.md, DribaSpacing.sm, DribaSpacing.md, DribaSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seller
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundImage: NetworkImage(product.seller.avatarUrl),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.seller.name,
                            style: TextStyle(
                              color: DribaColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.seller.isVerified)
                          Icon(Icons.verified, color: accent, size: 13),
                      ],
                    ),

                    const SizedBox(height: DribaSpacing.xxs),

                    // Name
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: DribaColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: accent, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${product.rating}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ' (${product.reviewCount})',
                          style: TextStyle(
                            color: DribaColors.textDisabled,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product.salesCount} sold',
                          style: TextStyle(
                            color: DribaColors.textDisabled,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: DribaSpacing.xs),

                    // Price
                    Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '\$${product.originalPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: DribaColors.textDisabled,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _badgeColor(String badge) {
    switch (badge) {
      case 'BESTSELLER':
        return accent;
      case 'NEW':
        return DribaColors.success;
      case 'TOP RATED':
        return DribaColors.tertiary;
      case 'LIMITED':
        return DribaColors.error;
      default:
        return accent;
    }
  }

  Color _badgeTextColor(String badge) {
    switch (badge) {
      case 'BESTSELLER':
        return Colors.black87;
      default:
        return Colors.white;
    }
  }
}

// ── Small Tag ─────────────────────────────────
class _SmallTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DribaBorderRadius.xs),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: DribaColors.background.withOpacity(0.6),
            borderRadius: BorderRadius.circular(DribaBorderRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 11),
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// SELLER BADGE — Used in detail sheet
// ============================================

class SellerBadge extends StatelessWidget {
  final CommerceSeller seller;
  final Color accent;
  final VoidCallback? onTap;

  const SellerBadge({
    super.key,
    required this.seller,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(DribaSpacing.md),
      borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(seller.avatarUrl),
          ),
          const SizedBox(width: DribaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.name,
                        style: const TextStyle(
                          color: DribaColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (seller.isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified, color: accent, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: accent, size: 14),
                    const SizedBox(width: 2),
                    Text('${seller.rating}',
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    const SizedBox(width: DribaSpacing.sm),
                    Icon(Icons.shopping_bag_outlined,
                        color: DribaColors.textTertiary, size: 13),
                    const SizedBox(width: 2),
                    Text('${seller.salesCount} sales',
                        style: TextStyle(
                            color: DribaColors.textTertiary, fontSize: 12)),
                    const SizedBox(width: DribaSpacing.sm),
                    Icon(Icons.location_on_outlined,
                        color: DribaColors.textTertiary, size: 13),
                    const SizedBox(width: 2),
                    Text(seller.location,
                        style: TextStyle(
                            color: DribaColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: DribaColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}

// ============================================
// RATING STARS
// ============================================

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? const Color(0xFFFFD700);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, size: size, color: starColor);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded, size: size, color: starColor);
        }
        return Icon(Icons.star_outline_rounded,
            size: size, color: DribaColors.textDisabled);
      }),
    );
  }
}
