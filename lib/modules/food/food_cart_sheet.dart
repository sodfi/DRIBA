import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/driba_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/animations/driba_animations.dart';
import 'food_models.dart';

/// Cart bottom sheet with item list, quantities, and checkout
class FoodCartSheet extends StatelessWidget {
  final List<CartItem> cartItems;
  final Color accent;
  final void Function(int index, int quantity) onUpdateQuantity;
  final VoidCallback onCheckout;

  const FoodCartSheet({
    super.key,
    required this.cartItems,
    required this.accent,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  double get _subtotal =>
      cartItems.fold(0, (sum, item) => sum + item.total);
  double get _deliveryFee =>
      cartItems.isNotEmpty ? cartItems.first.restaurant.deliveryFee : 0;
  double get _serviceFee => 0; // Driba: 0% platform fee
  double get _total => _subtotal + _deliveryFee + _serviceFee;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: DribaColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DribaBorderRadius.xxl),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: DribaSpacing.md),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
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
                const Expanded(
                  child: Text(
                    'Your Order',
                    style: TextStyle(
                      color: DribaColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GlassCircleButton(
                  size: 36,
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: DribaColors.textPrimary, size: 18),
                ),
              ],
            ),
          ),

          // Restaurant name
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DribaSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.store_outlined,
                      color: DribaColors.textTertiary, size: 16),
                  const SizedBox(width: DribaSpacing.sm),
                  Text(
                    cartItems.first.restaurant.name,
                    style: TextStyle(
                      color: DribaColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: DribaSpacing.md),

          // Cart items list
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DribaSpacing.lg,
                    ),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: DribaSpacing.sm),
                    itemBuilder: (context, index) {
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

          // Price breakdown + checkout
          _buildCheckoutSection(context, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
              color: DribaColors.textDisabled, size: 48),
          const SizedBox(height: DribaSpacing.md),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: DribaColors.textTertiary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DribaSpacing.lg,
        DribaSpacing.lg,
        DribaSpacing.lg,
        bottomPadding + DribaSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: DribaColors.surface,
        border: Border(
          top: BorderSide(color: DribaColors.glassBorder),
        ),
      ),
      child: Column(
        children: [
          // Price breakdown
          _PriceRow(label: 'Subtotal', value: _subtotal),
          const SizedBox(height: DribaSpacing.xs),
          _PriceRow(
            label: 'Delivery',
            value: _deliveryFee,
            isFree: _deliveryFee == 0,
            accent: accent,
          ),
          const SizedBox(height: DribaSpacing.xs),
          _PriceRow(
            label: 'Service fee',
            value: _serviceFee,
            isFree: true,
            accent: accent,
            badge: '0% FOREVER',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: DribaSpacing.md),
            child: Container(
              height: 1,
              color: DribaColors.glassBorder,
            ),
          ),

          // Total
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: DribaColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                  borderRadius:
                      BorderRadius.circular(DribaBorderRadius.pill),
                  boxShadow: cartItems.isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    cartItems.isEmpty
                        ? 'Add items to continue'
                        : 'Place Order · \$${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: cartItems.isEmpty
                          ? DribaColors.textDisabled
                          : Colors.white,
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
  final CartItem item;
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
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: const TextStyle(
                    color: DribaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.menuItem.price.toStringAsFixed(2)} each',
                  style: TextStyle(
                    color: DribaColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: DribaColors.glassFill,
              borderRadius: BorderRadius.circular(DribaBorderRadius.pill),
              border: Border.all(color: DribaColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityButton(
                  icon: item.quantity <= 1
                      ? Icons.delete_outline
                      : Icons.remove,
                  iconColor: item.quantity <= 1
                      ? DribaColors.error
                      : DribaColors.textSecondary,
                  onTap: onDecrement,
                ),
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        color: DribaColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  iconColor: accent,
                  onTap: onIncrement,
                ),
              ],
            ),
          ),

          const SizedBox(width: DribaSpacing.md),

          // Line total
          SizedBox(
            width: 60,
            child: Text(
              '\$${item.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: DribaColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quantity Button ────────────────────────────

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

// ── Price Row ─────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isFree;
  final Color? accent;
  final String? badge;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isFree = false,
    this.accent,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: DribaColors.textSecondary,
            fontSize: 14,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: DribaSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: (accent ?? DribaColors.success).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: accent ?? DribaColors.success,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          isFree ? 'FREE' : '\$${value.toStringAsFixed(2)}',
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
