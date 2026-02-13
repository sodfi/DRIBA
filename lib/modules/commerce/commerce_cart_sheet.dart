import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'commerce_models.dart';

/// Shopping cart bottom sheet
/// Item list, quantity controls, pricing breakdown, checkout
class CommerceCartSheet extends StatelessWidget {
  final List<CommerceCartItem> cartItems;
  final Color accent;
  final void Function(int index, int quantity) onUpdateQuantity;
  final VoidCallback onCheckout;

  const CommerceCartSheet({
    super.key,
    required this.cartItems,
    required this.accent,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  double get _subtotal => cartItems.fold(0, (s, i) => s + i.total);
  double get _shipping {
    if (cartItems.isEmpty) return 0;
    final hasPhysical = cartItems.any((i) => !i.product.isDigital);
    if (!hasPhysical) return 0;
    final allFreeShipping = cartItems
        .where((i) => !i.product.isDigital)
        .every((i) => i.product.isFreeShipping);
    return allFreeShipping ? 0 : 4.99;
  }
  double get _platformFee => 0; // 0% forever
  double get _total => _subtotal + _shipping + _platformFee;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: DribaColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(DribaBorderRadius.xxl)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: DribaSpacing.md),
            child: Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(DribaSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: accent, size: 24),
                const SizedBox(width: DribaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shopping Cart',
                          style: TextStyle(
                              color: DribaColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      Text(
                        '${cartItems.fold<int>(0, (s, i) => s + i.quantity)} items',
                        style: TextStyle(
                            color: DribaColors.textTertiary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GlassCircleButton(
                  size: 36,
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: DribaColors.textPrimary, size: 18),
                ),
              ],
            ),
          ),

          // Items
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DribaSpacing.lg),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: DribaSpacing.sm),
                    itemBuilder: (_, index) {
                      return _CartItemRow(
                        item: cartItems[index],
                        accent: accent,
                        onIncrement: () =>
                            onUpdateQuantity(index, cartItems[index].quantity + 1),
                        onDecrement: () =>
                            onUpdateQuantity(index, cartItems[index].quantity - 1),
                      );
                    },
                  ),
          ),

          // Checkout section
          _buildCheckout(context, bottomPad),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
              color: DribaColors.textDisabled, size: 48),
          const SizedBox(height: DribaSpacing.md),
          const Text('Cart is empty',
              style: TextStyle(
                  color: DribaColors.textTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCheckout(BuildContext context, double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          DribaSpacing.lg, DribaSpacing.lg, DribaSpacing.lg, bottomPad + DribaSpacing.lg),
      decoration: BoxDecoration(
        color: DribaColors.surface,
        border: Border(top: BorderSide(color: DribaColors.glassBorder)),
      ),
      child: Column(
        children: [
          _PriceLine(label: 'Subtotal', value: _subtotal),
          const SizedBox(height: DribaSpacing.xs),
          _PriceLine(
            label: 'Shipping',
            value: _shipping,
            isFree: _shipping == 0,
            freeLabel: cartItems.any((i) => !i.product.isDigital)
                ? 'FREE'
                : 'Digital',
            accent: accent,
          ),
          const SizedBox(height: DribaSpacing.xs),
          _PriceLine(
            label: 'Platform fee',
            value: 0,
            isFree: true,
            freeLabel: 'FREE',
            accent: accent,
            badge: '0% FOREVER',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
            child: Container(height: 1, color: DribaColors.glassBorder),
          ),

          // Total
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('\$${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: accent, fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: DribaSpacing.lg),

          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: GestureDetector(
              onTap: cartItems.isEmpty
                  ? null
                  : () {
                      HapticFeedback.heavyImpact();
                      onCheckout();
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: cartItems.isEmpty
                      ? DribaColors.glassFillActive
                      : accent,
                  borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
                  boxShadow: cartItems.isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    cartItems.isEmpty
                        ? 'Add items to continue'
                        : 'Checkout · \$${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: cartItems.isEmpty
                          ? DribaColors.textDisabled
                          : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}

// ── Cart Item Row ─────────────────────────────
class _CartItemRow extends StatelessWidget {
  final CommerceCartItem item;
  final Color accent;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemRow({
    required this.item,
    required this.accent,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(DribaSpacing.md),
      borderRadius: BorderRadius.circular(DribaBorderRadius.lg),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(DribaBorderRadius.md),
            child: CachedNetworkImage(
              imageUrl: item.product.imageUrls.first,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 64, height: 64, color: DribaColors.surface),
              errorWidget: (_, __, ___) =>
                  Container(width: 64, height: 64, color: DribaColors.surface),
            ),
          ),
          const SizedBox(width: DribaSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        color: DribaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.selectedVariants.isNotEmpty)
                  Text(
                    item.selectedVariants.values.join(' · '),
                    style: TextStyle(
                        color: DribaColors.textTertiary, fontSize: 12),
                  ),
                const SizedBox(height: DribaSpacing.xs),
                Row(
                  children: [
                    Text('\$${item.product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    if (item.product.isDigital) ...[
                      const SizedBox(width: DribaSpacing.sm),
                      Icon(Icons.cloud_download_outlined,
                          color: DribaColors.textDisabled, size: 14),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Quantity
          Container(
            decoration: BoxDecoration(
              color: DribaColors.glassFill,
              borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
              border: Border.all(color: DribaColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDecrement();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      item.quantity <= 1
                          ? Icons.delete_outline
                          : Icons.remove,
                      color: item.quantity <= 1
                          ? DribaColors.error
                          : DribaColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Text('${item.quantity}',
                        style: const TextStyle(
                            color: DribaColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onIncrement();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, color: accent, size: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: DribaSpacing.sm),

          // Total
          SizedBox(
            width: 55,
            child: Text(
              '\$${item.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: DribaColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price Line ────────────────────────────────
class _PriceLine extends StatelessWidget {
  final String label;
  final double value;
  final bool isFree;
  final String? freeLabel;
  final Color? accent;
  final String? badge;

  const _PriceLine({
    required this.label,
    required this.value,
    this.isFree = false,
    this.freeLabel,
    this.accent,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(color: DribaColors.textSecondary, fontSize: 14)),
        if (badge != null) ...[
          const SizedBox(width: DribaSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: (accent ?? DribaColors.success).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge!,
                style: TextStyle(
                    color: accent ?? DribaColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ],
        const Spacer(),
        Text(
          isFree ? (freeLabel ?? 'FREE') : '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: isFree
                ? (accent ?? DribaColors.success)
                : DribaColors.textPrimary,
            fontSize: 14,
            fontWeight: isFree ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
