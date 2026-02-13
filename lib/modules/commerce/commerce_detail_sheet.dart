import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'commerce_models.dart';
import 'commerce_widgets.dart';

/// Product detail bottom sheet
/// Image gallery, variant picker, reviews, seller info, add to cart
class CommerceDetailSheet extends StatefulWidget {
  final CommerceProduct product;
  final Color accent;
  final void Function(CommerceCartItem) onAddToCart;

  const CommerceDetailSheet({
    super.key,
    required this.product,
    required this.accent,
    required this.onAddToCart,
  });

  @override
  State<CommerceDetailSheet> createState() => _CommerceDetailSheetState();
}

class _CommerceDetailSheetState extends State<CommerceDetailSheet> {
  late ScrollController _scrollController;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  double _headerOpacity = 0.0;
  final Map<String, String> _selectedVariants = {};
  bool _isFavorited = false;

  CommerceProduct get p => widget.product;
  Color get accent => widget.accent;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Pre-select first variant option for each group
    for (final group in p.variants) {
      final first = group.options.firstWhere((o) => o.available,
          orElse: () => group.options.first);
      _selectedVariants[group.name] = first.label;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _headerOpacity = (_scrollController.offset / 200).clamp(0.0, 1.0);
    });
  }

  double get _effectivePrice {
    double price = p.price;
    for (final group in p.variants) {
      final selected = _selectedVariants[group.name];
      if (selected != null) {
        final option = group.options.firstWhere((o) => o.label == selected,
            orElse: () => group.options.first);
        price += option.priceAdd ?? 0;
      }
    }
    return price;
  }

  void _handleAddToCart() {
    HapticFeedback.heavyImpact();
    widget.onAddToCart(CommerceCartItem(
      product: p,
      quantity: _quantity,
      selectedVariants: Map.from(_selectedVariants),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: DribaColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(DribaBorderRadius.xxl)),
      ),
      child: Column(
        children: [
          // Scrollable content
          Expanded(
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Image gallery
                    SliverToBoxAdapter(child: _buildImageGallery()),
                    // Product info
                    SliverToBoxAdapter(child: _buildProductInfo()),
                    // Variants
                    if (p.variants.isNotEmpty)
                      SliverToBoxAdapter(child: _buildVariants()),
                    // Highlights
                    if (p.highlights.isNotEmpty)
                      SliverToBoxAdapter(child: _buildHighlights()),
                    // Seller
                    SliverToBoxAdapter(child: _buildSeller()),
                    // Reviews
                    if (p.reviews.isNotEmpty)
                      SliverToBoxAdapter(child: _buildReviews()),
                    // Spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),

                // Collapsing header
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: _buildCollapsingHeader(),
                ),
              ],
            ),
          ),

          // Bottom add-to-cart bar
          _buildBottomBar(bottomPad),
        ],
      ),
    );
  }

  // ── Image Gallery ───────────────────────────
  Widget _buildImageGallery() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: p.imageUrls.length,
            onPageChanged: (i) => setState(() => _selectedImageIndex = i),
            itemBuilder: (_, index) {
              return CachedNetworkImage(
                imageUrl: p.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: DribaColors.surface),
                errorWidget: (_, __, ___) => Container(
                  color: DribaColors.surface,
                  child: Icon(Icons.shopping_bag_outlined,
                      color: accent.withOpacity(0.3), size: 48),
                ),
              );
            },
          ),

          // Bottom gradient
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, DribaColors.background],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Page dots
          if (p.imageUrls.length > 1)
            Positioned(
              bottom: DribaSpacing.lg,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(p.imageUrls.length, (i) {
                  final isActive = i == _selectedImageIndex;
                  return AnimatedContainer(
                    duration: DribaDurations.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? accent : DribaColors.textDisabled,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          // Top handle
          Positioned(
            top: DribaSpacing.md, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 36, height: 4,
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

  // ── Product Info ────────────────────────────
  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          if (p.badge != null)
            Padding(
              padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.sm),
                ),
                child: Text(p.badge!,
                    style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ),
            ),

          // Name
          Text(
            p.name,
            style: const TextStyle(
              color: DribaColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: DribaSpacing.md),

          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_effectivePrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (p.hasDiscount) ...[
                const SizedBox(width: DribaSpacing.sm),
                Text(
                  '\$${p.originalPrice!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: DribaColors.textDisabled,
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: DribaSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DribaColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DribaBorderRadius.xs),
                  ),
                  child: Text(
                    '-${p.discountPercent.toInt()}%',
                    style: const TextStyle(
                      color: DribaColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DribaSpacing.md),

          // Rating + sales
          Row(
            children: [
              RatingStars(rating: p.rating, size: 18, color: accent),
              const SizedBox(width: DribaSpacing.sm),
              Text('${p.rating}',
                  style: TextStyle(
                      color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
              Text(' (${p.reviewCount} reviews)',
                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 14)),
              const Spacer(),
              Icon(Icons.shopping_bag_outlined,
                  color: DribaColors.textTertiary, size: 16),
              const SizedBox(width: 4),
              Text('${p.salesCount} sold',
                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: DribaSpacing.lg),

          // Shipping / Digital tags
          Wrap(
            spacing: DribaSpacing.sm,
            runSpacing: DribaSpacing.sm,
            children: [
              if (p.isDigital)
                _InfoTag(icon: Icons.cloud_download_outlined, text: 'Instant download', color: accent),
              if (p.isFreeShipping && !p.isDigital)
                _InfoTag(icon: Icons.local_shipping_outlined, text: 'Free shipping', color: DribaColors.success),
              if (p.stockCount != null && p.stockCount! <= 10)
                _InfoTag(
                  icon: Icons.inventory_2_outlined,
                  text: 'Only ${p.stockCount} left',
                  color: DribaColors.warning,
                ),
              _InfoTag(icon: Icons.shield_outlined, text: 'Buyer protection', color: DribaColors.info),
            ],
          ),
          const SizedBox(height: DribaSpacing.lg),

          // Description
          Text(
            p.description,
            style: TextStyle(
              color: DribaColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Variants ────────────────────────────────
  Widget _buildVariants() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: p.variants.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.name,
                  style: const TextStyle(
                      color: DribaColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const SizedBox(height: DribaSpacing.sm),
              Wrap(
                spacing: DribaSpacing.sm,
                runSpacing: DribaSpacing.sm,
                children: group.options.map((option) {
                  final isSelected =
                      _selectedVariants[group.name] == option.label;
                  final isColor = option.colorHex != null;

                  return GestureDetector(
                    onTap: option.available
                        ? () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedVariants[group.name] = option.label;
                            });
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: DribaDurations.fast,
                      padding: EdgeInsets.symmetric(
                        horizontal: isColor ? DribaSpacing.md : DribaSpacing.lg,
                        vertical: DribaSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: !option.available
                            ? DribaColors.glassFill
                            : isSelected
                                ? accent.withOpacity(0.15)
                                : DribaColors.glassFill,
                        borderRadius:
                            BorderRadius.circular(DribaBorderRadius.pill),
                        border: Border.all(
                          color: !option.available
                              ? DribaColors.glassBorder
                              : isSelected
                                  ? accent
                                  : DribaColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isColor) ...[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _hexToColor(option.colorHex!),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? accent
                                      : DribaColors.glassBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: DribaSpacing.sm),
                          ],
                          Text(
                            option.label,
                            style: TextStyle(
                              color: !option.available
                                  ? DribaColors.textDisabled
                                  : isSelected
                                      ? accent
                                      : DribaColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                              decoration: !option.available
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (option.priceAdd != null && option.priceAdd! > 0)
                            Text(
                              ' +\$${option.priceAdd!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: DribaColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: DribaSpacing.lg),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Highlights ──────────────────────────────
  Widget _buildHighlights() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.lg),
      child: GlassContainer(
        padding: const EdgeInsets.all(DribaSpacing.lg),
        borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Highlights',
                style: TextStyle(
                    color: DribaColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: DribaSpacing.md),
            ...p.highlights.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: DribaSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: accent, size: 18),
                      const SizedBox(width: DribaSpacing.sm),
                      Expanded(
                        child: Text(h,
                            style: TextStyle(
                                color: DribaColors.textSecondary,
                                fontSize: 14,
                                height: 1.3)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Seller ──────────────────────────────────
  Widget _buildSeller() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sold by',
              style: TextStyle(
                  color: DribaColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: DribaSpacing.md),
          SellerBadge(seller: p.seller, accent: accent),
        ],
      ),
    );
  }

  // ── Reviews ─────────────────────────────────
  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DribaSpacing.lg, 0, DribaSpacing.lg, DribaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Reviews',
                  style: TextStyle(
                      color: DribaColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(width: DribaSpacing.sm),
              Text('(${p.reviewCount})',
                  style: TextStyle(color: DribaColors.textTertiary, fontSize: 14)),
              const Spacer(),
              Text('See all',
                  style: TextStyle(
                      color: accent, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: DribaSpacing.md),
          ...p.reviews.map((review) => Padding(
                padding: const EdgeInsets.only(bottom: DribaSpacing.md),
                child: GlassContainer(
                  padding: const EdgeInsets.all(DribaSpacing.md),
                  borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (review.avatarUrl != null)
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(review.avatarUrl!),
                            ),
                          const SizedBox(width: DribaSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.userName,
                                    style: const TextStyle(
                                        color: DribaColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                RatingStars(
                                    rating: review.rating,
                                    size: 14,
                                    color: accent),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(review.date),
                            style: TextStyle(
                                color: DribaColors.textDisabled, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: DribaSpacing.sm),
                      Text(review.text,
                          style: TextStyle(
                              color: DribaColors.textSecondary,
                              fontSize: 14,
                              height: 1.4)),
                      if (review.helpfulCount > 0) ...[
                        const SizedBox(height: DribaSpacing.sm),
                        Text('${review.helpfulCount} people found this helpful',
                            style: TextStyle(
                                color: DribaColors.textDisabled, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ── Collapsing Header ───────────────────────
  Widget _buildCollapsingHeader() {
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
            color: DribaColors.background.withOpacity(_headerOpacity * 0.9),
            border: Border(
              bottom: BorderSide(
                  color: DribaColors.glassBorder.withOpacity(_headerOpacity)),
            ),
          ),
          child: Row(
            children: [
              GlassCircleButton(
                size: 38,
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: DribaColors.textPrimary, size: 20),
              ),
              const SizedBox(width: DribaSpacing.md),
              Expanded(
                child: Opacity(
                  opacity: _headerOpacity,
                  child: Text(p.name,
                      style: const TextStyle(
                          color: DribaColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              GlassCircleButton(
                size: 38,
                onTap: () => HapticFeedback.lightImpact(),
                child: const Icon(Icons.share_outlined,
                    color: DribaColors.textPrimary, size: 18),
              ),
              const SizedBox(width: DribaSpacing.sm),
              GlassCircleButton(
                size: 38,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isFavorited = !_isFavorited);
                },
                child: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_outline,
                  color: _isFavorited ? DribaColors.error : accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────
  Widget _buildBottomBar(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          DribaSpacing.lg, DribaSpacing.md, DribaSpacing.lg, bottomPad + DribaSpacing.md),
      decoration: BoxDecoration(
        color: DribaColors.surface,
        border: Border(top: BorderSide(color: DribaColors.glassBorder)),
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: DribaColors.glassFill,
              borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
              border: Border.all(color: DribaColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyBtn(
                  icon: Icons.remove,
                  onTap: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text('$_quantity',
                        style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
                _QtyBtn(
                  icon: Icons.add,
                  color: accent,
                  onTap: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: DribaSpacing.md),

          // Add to cart button
          Expanded(
            child: GestureDetector(
              onTap: p.inStock ? _handleAddToCart : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: p.inStock ? accent : DribaColors.glassFillActive,
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  boxShadow: p.inStock
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    p.inStock
                        ? 'Add to Cart · \$${(_effectivePrice * _quantity).toStringAsFixed(2)}'
                        : 'Out of Stock',
                    style: TextStyle(
                      color:
                          p.inStock ? Colors.black87 : DribaColors.textDisabled,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays < 1) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── Quantity Button ───────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _QtyBtn({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon,
            color: onTap != null
                ? (color ?? DribaColors.textSecondary)
                : DribaColors.textDisabled,
            size: 20),
      ),
    );
  }
}

// ── Info Tag ──────────────────────────────────
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoTag({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DribaBorderRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
